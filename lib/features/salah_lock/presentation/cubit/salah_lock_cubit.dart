import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:adhan/adhan.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/device_management_service.dart';
import '../../data/services/salah_notification_service.dart';
import '../../domain/entities/salah_lock_settings.dart';
import '../../domain/repositories/salah_lock_repository.dart';
import '../../../salah/presentation/cubit/salah_cubit.dart';
import '../../../../core/location/cubit/location_cubit.dart';
import '../../../../core/location/cubit/location_state.dart';
import '../../../auth/domain/repositories/premium_repository.dart';

part 'salah_lock_state.dart';

class SalahLockCubit extends Cubit<SalahLockState> {
  final SalahLockRepository repository;
  final SalahNotificationService notificationService;
  final DeviceManagementService deviceManager;
  final SalahCubit salahCubit;
  final LocationCubit locationCubit;
  final PremiumRepository premiumRepository;

  Timer? _monitoringTimer;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _salahSubscription;
  SalahLockSettings _settings = SalahLockSettings();
  bool _isGuideDismissed = false;
  List<Map<String, String>> _ayahs = [];
  DateTime? _snoozedUntil;
  String? _lastScheduledDate; // tracks which day notifications were last scheduled

  SalahLockCubit({
    required this.repository,
    required this.notificationService,
    required this.deviceManager,
    required this.salahCubit,
    required this.locationCubit,
    required this.premiumRepository,
  }) : super(SalahLockIdle(SalahLockSettings()));

  Future<void> init() async {
    emit(SalahLockLoading(_settings, isGuideDismissed: _isGuideDismissed));
    _settings = await repository.getSettings();
    debugPrint('⚙️ SalahLock: Settings loaded - isEnabled: ${_settings.isEnabled}');

    SalahNotificationService.onPrayedAction = _onNotificationPrayed;
    SalahNotificationService.onSkipAction = _onNotificationSkip;
    _isGuideDismissed = await repository.isGuideDismissed();
    _lastScheduledDate = await repository.getLastNotificationDate();

    final jsonString = await rootBundle.loadString('assets/salah_ayahs.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    _ayahs = jsonList.map((e) => Map<String, String>.from(e)).toList();

    // ── Guard: don't start monitoring if no user is logged in ──
    if (FirebaseAuth.instance.currentUser == null) {
      debugPrint('⏭️ SalahLock: No user logged in, skipping monitoring');
      emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
      return;
    }

    _locationSubscription = locationCubit.stream.listen((locationState) {
      if (locationState is LocationLoaded) {
        // Re-check auth before starting monitoring
        if (FirebaseAuth.instance.currentUser == null) return;
        startMonitoring(userId: '', locationState: locationState);
      }
    });

    _salahSubscription = salahCubit.stream.listen((salahState) async {
      if (salahState is SalahLoaded) {
        // Always reconcile — even before the location/prayer-times are ready —
        // so notifications are cancelled for prayers marked complete via the
        // Salah screen or another device.
        await _syncCompletedPrayersFromSalahState();
        if (locationCubit.state is LocationLoaded) {
          final prayerTimes = _getPrayerTimes(locationCubit.state as LocationLoaded);
          await checkPrayerLock(prayerTimes, '');
        }
      }
    });

    if (_settings.isEnabled) {
      // Ensure alarm + battery permissions are granted silently on startup
      checkAndRequestBasicPermissions();
    }

    if (locationCubit.state is LocationLoaded) {
      startMonitoring(userId: '', locationState: locationCubit.state as LocationLoaded);
    }

    emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
  }

  void startMonitoring({required String userId, required LocationLoaded locationState}) {
    if (FirebaseAuth.instance.currentUser == null) return;
    _monitoringTimer?.cancel();

    final prayerTimes = _getPrayerTimes(locationState);
    // Always reschedule on app start so missed/stale notifications are refreshed
    _forceScheduleNotifications(prayerTimes);
    checkPrayerLock(prayerTimes, userId);

    _monitoringTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (FirebaseAuth.instance.currentUser == null) {
        _monitoringTimer?.cancel();
        return;
      }
      final times = _getPrayerTimes(locationState);
      // Reschedule notifications when the calendar day rolls over
      _scheduleNotificationsIfNewDay(times);
      checkPrayerLock(times, userId);
    });
  }

  PrayerTimes _getPrayerTimes(LocationLoaded state) {
    final coordinates = Coordinates(state.latitude, state.longitude);
    final params = CalculationMethod.karachi.getParameters()..madhab = Madhab.hanafi;
    return PrayerTimes(coordinates, DateComponents.from(DateTime.now()), params);
  }

  /// Called on every app start — always reschedules today's notifications.
  Future<void> _forceScheduleNotifications(PrayerTimes prayerTimes) async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    _lastScheduledDate = dateKey;
    repository.saveLastNotificationDate(dateKey).catchError((_) {});
    final tomorrowPrayers = _getTomorrowPrayerTimes();
    final completed = await _getCompletedPrayers();
    notificationService.scheduleAllPrayerNotifications(prayerTimes, tomorrowPrayerTimes: tomorrowPrayers, completedPrayers: completed).catchError((e) {
      debugPrint('⚠️ SalahLock: Failed to schedule prayer notifications: $e');
    });
  }

  Future<void> _scheduleNotificationsIfNewDay(PrayerTimes prayerTimes) async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    if (_lastScheduledDate == dateKey) return;
    _lastScheduledDate = dateKey;
    repository.saveLastNotificationDate(dateKey).catchError((_) {});
    final tomorrowPrayers = _getTomorrowPrayerTimes();
    final completed = await _getCompletedPrayers();
    notificationService.scheduleAllPrayerNotifications(prayerTimes, tomorrowPrayerTimes: tomorrowPrayers, completedPrayers: completed).catchError((e) {
      debugPrint('⚠️ SalahLock: Failed to schedule prayer notifications: $e');
    });
  }

  Future<Set<String>> _getCompletedPrayers() async {
    const prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final completed = <String>{};
    for (final name in prayers) {
      if (await repository.isSalahCompletedLocally(name)) {
        completed.add(name);
      }
    }
    return completed;
  }

  PrayerTimes? _getTomorrowPrayerTimes() {
    if (locationCubit.state is! LocationLoaded) return null;
    final locState = locationCubit.state as LocationLoaded;
    final coordinates = Coordinates(locState.latitude, locState.longitude);
    final params = CalculationMethod.karachi.getParameters()..madhab = Madhab.hanafi;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return PrayerTimes(coordinates, DateComponents.from(tomorrow), params);
  }

  Future<void> checkPrayerLock(PrayerTimes prayerTimes, String userId) async {
    if (!_settings.isEnabled) return;
    if (FirebaseAuth.instance.currentUser == null) return;
    if (state is SalahLockUnlocked) return;
    if (_snoozedUntil != null && DateTime.now().isBefore(_snoozedUntil!)) return;

    // ✅ Always sync any remotely-completed prayers to the local flag
    // and cancel their notifications. Prevents notifications from firing
    // for prayers the user marked via the Salah screen or another device,
    // regardless of which prayer window we are currently in.
    await _syncCompletedPrayersFromSalahState();

    final currentPrayer = prayerTimes.currentPrayer();

    if (currentPrayer == Prayer.none || currentPrayer == Prayer.sunrise) {
      if (state is SalahLockActive) {
        emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
      }
      return;
    }

    final prayerName = _getPrayerName(currentPrayer);
    final bool isDone = await repository.isSalahCompletedLocally(prayerName);

    // ✅ Avoid flashing the overlay before SalahCubit has finished its first
    // load. Without this, the lock briefly shows SalahLockActive on cold start
    // and then disappears once SalahLoaded arrives and reveals the prayer is
    // already done. Still proceed if SalahCubit errored — we don't want the
    // user to miss their prayer just because Firestore is unreachable.
    if (!isDone &&
        (salahCubit.state is SalahInitial ||
            salahCubit.state is SalahLoading)) {
      return;
    }

    if (!isDone) {
      if (state is! SalahLockActive) {
        final randomVerse = _ayahs[Random().nextInt(_ayahs.length)];
        emit(SalahLockActive(
          salahName: prayerName,
          verse: randomVerse,
          settings: _settings,
          isGuideDismissed: _isGuideDismissed,
        ));
      }
    } else {
      // ✅ Also cancel notifications here in case local state was marked done elsewhere
      await notificationService.cancelPrayerByName(prayerName);

      if (state is SalahLockActive) {
        emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
      }
    }
  }

  /// Reconcile the SalahCubit's loaded state with the local "done" flag and
  /// notification queue. Called from [checkPrayerLock] and from the salah
  /// stream listener. Ensures that whenever a prayer is marked complete —
  /// from the Salah screen, a notification action, the overlay, or any other
  /// entry point — its notifications are cancelled and local state is in sync.
  Future<void> _syncCompletedPrayersFromSalahState() async {
    final salahState = salahCubit.state;
    if (salahState is! SalahLoaded) return;

    for (final salah in salahState.salahs) {
      if (!salah.isCompleted) continue;
      final name = salah.salahName;
      final alreadyLocal = await repository.isSalahCompletedLocally(name);
      if (alreadyLocal) continue;
      await repository.markSalahCompletedLocally(name);
      await notificationService.cancelPrayerByName(name);
      debugPrint('🔕 Synced completed prayer $name → cancelled notifications');
    }
  }

  /// Public entry point used by the Salah screen (and any other UI surface)
  /// to mark a prayer as prayed. Cancels notifications and updates local
  /// state immediately so the user doesn't keep getting reminders.
  Future<void> markPrayerCompletedExternally(String salahName) async {
    await repository.markSalahCompletedLocally(salahName);
    await notificationService.cancelPrayerByName(salahName);
    if (state is SalahLockActive &&
        (state as SalahLockActive).salahName == salahName) {
      emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
    }
  }

  void _onNotificationPrayed(String salahName) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    confirmPrayed(uid, salahName);
  }

  void _onNotificationSkip(String salahName) {
    notificationService.cancelPrayerByName(salahName);
    repository.markSalahCompletedLocally(salahName);
    if (state is SalahLockActive) {
      emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
    }
  }

  Future<void> confirmPrayed(String userId, String salahName) async {
    // Resolve a real userId if the caller didn't pass one (e.g. notification
    // action handler). Without this, the Firestore write stores an empty
    // userId and the Salah screen never sees the prayer as complete.
    final effectiveUserId = userId.isNotEmpty
        ? userId
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    // Mark locally + cancel notifications FIRST so any in-flight
    // checkPrayerLock call (triggered by SalahCubit reloads) immediately
    // sees this prayer as done and doesn't re-emit SalahLockActive.
    await repository.markSalahCompletedLocally(salahName);
    await notificationService.cancelPrayerByName(salahName);
    emit(SalahLockUnlocked(_settings, isGuideDismissed: _isGuideDismissed));

    if (effectiveUserId.isNotEmpty) {
      try {
        await salahCubit.markSalahComplete(
          userId: effectiveUserId,
          salahName: salahName,
        );
      } catch (e) {
        debugPrint('⚠️ SalahLock: markSalahComplete failed: $e');
      }
    } else {
      debugPrint('⚠️ SalahLock: confirmPrayed called with no userId — '
          'skipping Firestore write');
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (state is SalahLockUnlocked) {
        emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
      }
    });
  }

  Future<void> remindLater(String salahName) async {
    _snoozedUntil = DateTime.now().add(const Duration(minutes: 10));
    emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
    notificationService.scheduleReminder(salahName, const Duration(minutes: 10)).catchError((e) {
      debugPrint('⚠️ SalahLock: Reminder notification failed (non-critical): $e');
    });
  }

  Future<void> updateSettings(SalahLockSettings settings) async {
    await repository.saveSettings(settings);
    _settings = settings;

    if (state is SalahLockActive) {
      final s = state as SalahLockActive;
      emit(SalahLockActive(
        salahName: s.salahName,
        verse: s.verse,
        settings: _settings,
        isGuideDismissed: _isGuideDismissed,
      ));
    } else if (state is SalahLockUnlocked) {
      emit(SalahLockUnlocked(_settings, isGuideDismissed: _isGuideDismissed));
    } else {
      emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
    }

    if (_settings.isEnabled && locationCubit.state is LocationLoaded) {
      final prayerTimes = _getPrayerTimes(locationCubit.state as LocationLoaded);
      await checkPrayerLock(prayerTimes, '');
    }
  }

  Future<void> dismissGuide() async {
    await repository.setGuideDismissed(true);
    _isGuideDismissed = true;
    updateSettings(_settings);
  }

  /// Requests exact alarm + battery optimization permissions so notifications
  /// fire on time even when the app is in the background.
  Future<bool> checkAndRequestBasicPermissions() async {
    if (!Platform.isAndroid) return true;

    // 1. Exact alarm permission (Android 12+)
    final exactGranted = await deviceManager.checkExactAlarmPermission();
    if (!exactGranted) {
      await deviceManager.requestExactAlarmPermission();
    }

    // 2. Battery optimization exemption — critical for background alarms
    final batteryIgnored = await deviceManager.isBatteryOptimizationIgnored();
    if (!batteryIgnored) {
      await deviceManager.requestIgnoreBatteryOptimization();
    }

    return exactGranted && batteryIgnored;
  }

  SalahLockSettings get settings => _settings;

  String _getPrayerName(Prayer prayer) {
    return switch (prayer) {
      Prayer.fajr => 'Fajr',
      Prayer.dhuhr => 'Dhuhr',
      Prayer.asr => 'Asr',
      Prayer.maghrib => 'Maghrib',
      Prayer.isha => 'Isha',
      _ => 'Salah',
    };
  }

  @override
  Future<void> close() {
    clear();
    return super.close();
  }

  void clear() {
    _monitoringTimer?.cancel();
    _locationSubscription?.cancel();
    _salahSubscription?.cancel();
    emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
  }
}
