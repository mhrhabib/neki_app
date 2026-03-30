import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:adhan/adhan.dart';
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
    _isGuideDismissed = await repository.isGuideDismissed();
    _lastScheduledDate = await repository.getLastNotificationDate();

    final jsonString = await rootBundle.loadString('assets/salah_ayahs.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    _ayahs = jsonList.map((e) => Map<String, String>.from(e)).toList();

    _locationSubscription = locationCubit.stream.listen((locationState) {
      if (locationState is LocationLoaded) {
        startMonitoring(userId: '', locationState: locationState);
      }
    });

    _salahSubscription = salahCubit.stream.listen((salahState) {
      if (salahState is SalahLoaded && locationCubit.state is LocationLoaded) {
        final prayerTimes = _getPrayerTimes(locationCubit.state as LocationLoaded);
        checkPrayerLock(prayerTimes, '');
      }
    });

    if (locationCubit.state is LocationLoaded) {
      startMonitoring(userId: '', locationState: locationCubit.state as LocationLoaded);
    }

    emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
  }

  void startMonitoring({required String userId, required LocationLoaded locationState}) {
    _monitoringTimer?.cancel();

    final prayerTimes = _getPrayerTimes(locationState);
    _scheduleNotificationsIfNewDay(prayerTimes);
    checkPrayerLock(prayerTimes, userId);

    _monitoringTimer = Timer.periodic(const Duration(minutes: 1), (_) {
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

  void _scheduleNotificationsIfNewDay(PrayerTimes prayerTimes) {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    if (_lastScheduledDate == dateKey) return;
    _lastScheduledDate = dateKey;
    repository.saveLastNotificationDate(dateKey).catchError((_) {});
    notificationService.scheduleAllPrayerNotifications(prayerTimes).catchError((e) {
      debugPrint('⚠️ SalahLock: Failed to schedule prayer notifications: $e');
    });
  }

  Future<void> checkPrayerLock(PrayerTimes prayerTimes, String userId) async {
    if (!_settings.isEnabled) return;
    if (state is SalahLockUnlocked) return;
    if (_snoozedUntil != null && DateTime.now().isBefore(_snoozedUntil!)) return;

    final currentPrayer = prayerTimes.currentPrayer();

    if (currentPrayer == Prayer.none || currentPrayer == Prayer.sunrise) {
      if (state is SalahLockActive) {
        emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
      }
      return;
    }

    final prayerName = _getPrayerName(currentPrayer);
    bool isDone = await repository.isSalahCompletedLocally(prayerName);

    if (!isDone && salahCubit.state is SalahLoaded) {
      final loadedState = salahCubit.state as SalahLoaded;
      isDone = loadedState.salahs.any((s) => s.salahName == prayerName && s.isCompleted);
      if (isDone) await repository.markSalahCompletedLocally(prayerName);
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
      if (state is SalahLockActive) {
        emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
      }
    }
  }

  void _onNotificationPrayed(String salahName) {
    confirmPrayed('', salahName);
  }

  Future<void> confirmPrayed(String userId, String salahName) async {
    await salahCubit.markSalahComplete(userId: userId, salahName: salahName);
    await repository.markSalahCompletedLocally(salahName);
    await notificationService.cancelPrayerNotifications();
    emit(SalahLockUnlocked(_settings, isGuideDismissed: _isGuideDismissed));

    Future.delayed(const Duration(seconds: 2), () {
      emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
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

  /// Requests exact alarm permission on Android so notifications fire on time.
  Future<bool> checkAndRequestBasicPermissions() async {
    if (!Platform.isAndroid) return true;
    final granted = await deviceManager.checkExactAlarmPermission();
    if (!granted) {
      await deviceManager.requestExactAlarmPermission();
      return false;
    }
    return true;
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
    _monitoringTimer?.cancel();
    _locationSubscription?.cancel();
    _salahSubscription?.cancel();
    return super.close();
  }
}
