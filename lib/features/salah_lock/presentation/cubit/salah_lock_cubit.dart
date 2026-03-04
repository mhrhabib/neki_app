import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:adhan/adhan.dart';
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
    _isGuideDismissed = await repository.isGuideDismissed();

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
        final prayerTimes = _calculatePrayerTimes(
          locationCubit.state as LocationLoaded,
        );
        checkPrayerLock(prayerTimes, '');
      }
    });

    // Initial check
    if (locationCubit.state is LocationLoaded) {
      final prayerTimes = _calculatePrayerTimes(
        locationCubit.state as LocationLoaded,
      );
      checkPrayerLock(prayerTimes, '');
    }
    // Ensure any listeners (UI) update after settings are loaded
    emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
  }

  void startMonitoring({
    required String userId,
    required LocationLoaded locationState,
  }) {
    _monitoringTimer?.cancel();

    final prayerTimes = _calculatePrayerTimes(locationState);

    _monitoringTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      checkPrayerLock(prayerTimes, userId);
    });

    // Run first check immediately
    checkPrayerLock(prayerTimes, userId);
  }

  PrayerTimes _calculatePrayerTimes(LocationLoaded state) {
    final coordinates = Coordinates(state.latitude, state.longitude);
    final params = CalculationMethod.karachi.getParameters()
      ..madhab = Madhab.hanafi;
    return PrayerTimes(
      coordinates,
      DateComponents.from(DateTime.now()),
      params,
    );
  }

  Future<void> checkPrayerLock(PrayerTimes prayerTimes, String userId) async {
    if (!_settings.isEnabled) return;
    if (state is SalahLockUnlocked) return;

    final currentPrayer = prayerTimes.currentPrayer();
    if (currentPrayer == Prayer.none || currentPrayer == Prayer.sunrise) {
      if (state is SalahLockActive) {
        emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
      }
      return;
    }

    final prayerName = _getPrayerName(currentPrayer);

    // Premium Check: Allow only 2 prayers (Fajr and Isha) for free users
    final isPremium = await premiumRepository.isPremium();
    if (!isPremium) {
      if (prayerName != 'Fajr' && prayerName != 'Isha') {
        if (state is SalahLockActive) {
          emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
        }
        return;
      }
    }

    bool isDone = await repository.isSalahCompletedLocally(prayerName);

    // Also check SalahCubit state for sync
    if (!isDone && salahCubit.state is SalahLoaded) {
      final loadedState = salahCubit.state as SalahLoaded;
      isDone = loadedState.salahs.any(
        (s) => s.salahName == prayerName && s.isCompleted,
      );
      if (isDone) {
        await repository.markSalahCompletedLocally(prayerName);
      }
    }

    if (!isDone) {
      if (state is! SalahLockActive) {
        // Trigger lock
        if (_settings.lockDeviceAndroid) {
          await deviceManager.lockDeviceScreen();
        }

        // Start App Blocker if there are blocked apps
        if (_settings.blockedApps.isNotEmpty) {
          await deviceManager.startAppBlocker(_settings.blockedApps);
        }

        final randomVerse = _ayahs[Random().nextInt(_ayahs.length)];
        emit(
          SalahLockActive(
            salahName: prayerName,
            verse: randomVerse,
            settings: _settings,
            isGuideDismissed: _isGuideDismissed,
          ),
        );
      }
    } else {
      if (state is SalahLockActive) {
        await deviceManager.stopAppBlocker();
        emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
      }
    }
  }

  Future<void> confirmPrayed(String userId, String salahName) async {
    await salahCubit.markSalahComplete(userId: userId, salahName: salahName);
    await repository.markSalahCompletedLocally(salahName);
    await notificationService.cancelAll();
    await deviceManager.stopAppBlocker();
    emit(SalahLockUnlocked(_settings, isGuideDismissed: _isGuideDismissed));

    // After 2 seconds, move back to idle so we can lock for next prayer
    Future.delayed(const Duration(seconds: 2), () {
      emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
    });
  }

  Future<void> remindLater(String salahName) async {
    try {
      await notificationService.scheduleReminder(
        salahName,
        const Duration(minutes: 10),
      );
    } catch (e) {
      // Ignore notification failures to ensure the app still unlocks
    }
    await deviceManager.stopAppBlocker();
    emit(
      SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed),
    ); // Temporarily dismiss overlay
  }

  Future<void> updateSettings(SalahLockSettings settings) async {
    await repository.saveSettings(settings);
    _settings = settings;
    // Re-emit current state with new settings so UI will rebuild.
    if (state is SalahLockActive) {
      final s = state as SalahLockActive;
      emit(
        SalahLockActive(
          salahName: s.salahName,
          verse: s.verse,
          settings: _settings,
          isGuideDismissed: _isGuideDismissed,
        ),
      );
    } else if (state is SalahLockUnlocked) {
      emit(SalahLockUnlocked(_settings, isGuideDismissed: _isGuideDismissed));
    } else {
      emit(SalahLockIdle(_settings, isGuideDismissed: _isGuideDismissed));
    }
  }

  Future<void> dismissGuide() async {
    await repository.setGuideDismissed(true);
    _isGuideDismissed = true;
    updateSettings(_settings); // Trigger a re-emit
  }

  Future<bool> checkAndRequestAndroidPermissions() async {
    final usage = await deviceManager.checkUsageStatsPermission();
    if (!usage) {
      await deviceManager.requestUsageStatsPermission();
      return false;
    }
    final overlay = await deviceManager.checkOverlayPermission();
    if (!overlay) {
      await deviceManager.requestOverlayPermission();
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
