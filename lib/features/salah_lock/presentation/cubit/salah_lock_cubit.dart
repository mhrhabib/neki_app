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
  StreamSubscription? _authSubscription;
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

    // Note: Reconciliation of background-marked prayers (from killed-app
    // notification actions) happens in the salahSubscription listener below,
    // once SalahLoaded arrives — not here, because at init time SalahCubit is
    // still in its Initial state and we'd have nothing to compare against.

    // ── Auth lifecycle ──
    // On cold start, Firebase Auth restoration can finish AFTER init() runs,
    // so currentUser may be null here even though the user is about to be
    // "authenticated" on the very next frame. Instead of early-returning and
    // leaving the cubit dead, we set up all listeners and rely on this auth
    // subscription to (re)schedule notifications once the user is available.
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        debugPrint('🔐 SalahLock: user=${user.uid} — starting monitoring');
        if (locationCubit.state is LocationLoaded) {
          startMonitoring(
            userId: user.uid,
            locationState: locationCubit.state as LocationLoaded,
          );
        }
      } else {
        debugPrint('🔐 SalahLock: user signed out — cancelling monitoring');
        _monitoringTimer?.cancel();
        notificationService.cancelPrayerNotifications();
      }
    });

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
        // Also reconcile local → Firestore: if the background notification
        // handler (or another offline action) marked a prayer done locally
        // but Firestore doesn't know yet, write it now.
        await _reconcileLocalPrayersToFirestore(salahState);
        if (locationCubit.state is LocationLoaded) {
          final prayerTimes = _getPrayerTimes(locationCubit.state as LocationLoaded);
          await checkPrayerLock(prayerTimes, '');
        }
      }
    });

    // Request notification permission + exact-alarm + battery-opt exemption
    // unconditionally. Notifications fire regardless of whether the user
    // has "lock" turned on — they're separate features and we don't want
    // the user to miss reminders just because they haven't toggled lock yet.
    // Fire-and-forget: we don't want init() to block on a system dialog.
    notificationService.requestPermissions().then((granted) async {
      debugPrint('🔔 SalahLock: notification permission granted=$granted');
      // Log currently pending notifications for diagnostic purposes —
      // helps answer "why am I not getting reminders?" bug reports.
      await notificationService.debugLogPending();
    });
    checkAndRequestBasicPermissions();

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
    notificationService.scheduleDhikrReminders().catchError((e) {
      debugPrint('⚠️ SalahLock: Failed to schedule dhikr reminders: $e');
    });
    notificationService.scheduleQuranReminders().catchError((e) {
      debugPrint('⚠️ SalahLock: Failed to schedule quran reminders: $e');
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
    notificationService.scheduleDhikrReminders().catchError((e) {
      debugPrint('⚠️ SalahLock: Failed to schedule dhikr reminders: $e');
    });
    notificationService.scheduleQuranReminders().catchError((e) {
      debugPrint('⚠️ SalahLock: Failed to schedule quran reminders: $e');
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

  /// Reconcile local-only completions back to Firestore.
  ///
  /// The background notification handler can only persist to SharedPreferences
  /// (no Firestore access in a background isolate), so when the user taps
  /// "I've prayed" from a killed-app notification, only the local flag is set.
  /// Next time the app opens and SalahCubit finishes loading, we look for any
  /// prayer that is locally marked done but isn't complete in Firestore, and
  /// write it up so the Salah tracker, points, and leaderboard stay accurate.
  bool _reconciledOnce = false;
  Future<void> _reconcileLocalPrayersToFirestore(SalahLoaded salahState) async {
    // Only reconcile once per SalahCubit reload-cycle — avoid chasing our
    // tail when markSalahComplete itself triggers another SalahLoaded.
    if (_reconciledOnce) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    const prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    bool wrote = false;
    for (final name in prayers) {
      final localDone = await repository.isSalahCompletedLocally(name);
      if (!localDone) continue;
      final remoteDone = salahState.salahs.any(
        (s) => s.salahName == name && s.isCompleted,
      );
      if (remoteDone) continue;
      // Local says done, Firestore disagrees → reconcile.
      debugPrint('♻️ Reconciling $name: local done → Firestore');
      try {
        await salahCubit.markSalahComplete(userId: uid, salahName: name);
        wrote = true;
      } catch (e) {
        debugPrint('⚠️ SalahLock: reconcile $name failed: $e');
      }
    }
    _reconciledOnce = true;
    // If we wrote anything, SalahCubit will emit SalahLoaded again and the
    // listener will see remoteDone=true for those prayers on the next pass.
    if (wrote) {
      debugPrint('♻️ Reconciliation wrote at least one prayer to Firestore');
    }
  }

  /// The single unified entry point for marking a prayer as prayed.
  ///
  /// Call this from ANY source (overlay, notification action, salah screen).
  /// It persists locally, cancels notifications for this prayer, writes to
  /// Firestore via [SalahCubit.markSalahComplete] (which is idempotent), and
  /// drives the overlay state machine.
  ///
  /// [showUnlockAnimation] is true when the caller is the overlay itself so
  /// the user sees the brief "Unlocked" confirmation before it fades away.
  Future<void> markPrayed({
    required String salahName,
    String? userId,
    bool showUnlockAnimation = false,
  }) async {
    final effectiveUserId = (userId != null && userId.isNotEmpty)
        ? userId
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    final wasAlreadyLocal = await repository.isSalahCompletedLocally(salahName);

    // 1. Persist locally + cancel notifications FIRST so any in-flight
    //    checkPrayerLock call (triggered by SalahCubit reloads) immediately
    //    sees this prayer as done and doesn't re-emit SalahLockActive.
    await repository.markSalahCompletedLocally(salahName);
    await notificationService.cancelPrayerByName(salahName);

    // 2. Drive overlay state machine.
    if (showUnlockAnimation) {
      emit(SalahLockUnlocked(_settings, isGuideDismissed: _isGuideDismissed));
    } else if (state is SalahLockActive &&
        (state as SalahLockActive).salahName == salahName) {
      emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
    }

    // 3. Write to Firestore. SalahCubit.markSalahComplete is idempotent —
    //    it checks the current SalahLoaded state and skips if the prayer is
    //    already complete (so points aren't double-credited).
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
      debugPrint('⚠️ SalahLock: markPrayed called with no userId — '
          'skipping Firestore write (will reconcile on next login)');
    }

    // 4. Auto-return to Idle after the unlock animation.
    if (showUnlockAnimation) {
      Future.delayed(const Duration(seconds: 2), () {
        if (state is SalahLockUnlocked) {
          emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
        }
      });
    }

    if (wasAlreadyLocal) {
      debugPrint('ℹ️ $salahName was already locally marked — idempotent path');
    }
  }

  /// Public entry point used by the Salah screen (and any other UI surface)
  /// to mark a prayer as prayed. Thin wrapper around [markPrayed].
  Future<void> markPrayerCompletedExternally(String salahName) {
    return markPrayed(salahName: salahName);
  }

  /// Called from the overlay's "Yes, I prayed" button. Thin wrapper around
  /// [markPrayed] that plays the unlock animation.
  Future<void> confirmPrayed(String userId, String salahName) {
    return markPrayed(
      salahName: salahName,
      userId: userId,
      showUnlockAnimation: true,
    );
  }

  void _onNotificationPrayed(String salahName) {
    // Fire and forget — markPrayed handles the entire flow including
    // Firestore write, notification cancellation, and overlay transition.
    markPrayed(salahName: salahName);
  }

  void _onNotificationSkip(String salahName) {
    // "Not praying" = silence reminders for this prayer today, but don't
    // count it as prayed (no Firestore write, no points).
    notificationService.cancelPrayerByName(salahName);
    repository.markSalahCompletedLocally(salahName);
    if (state is SalahLockActive &&
        (state as SalahLockActive).salahName == salahName) {
      emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
    }
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
    _authSubscription?.cancel();
    emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
  }
}
