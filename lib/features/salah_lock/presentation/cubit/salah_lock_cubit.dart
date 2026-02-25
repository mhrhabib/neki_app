import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:adhan/adhan.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/salah_device_lock_service.dart';
import '../../data/services/salah_notification_service.dart';
import '../../domain/entities/salah_lock_settings.dart';
import '../../domain/repositories/salah_lock_repository.dart';
import '../../../salah/presentation/cubit/salah_cubit.dart';
import '../../../../core/location/cubit/location_cubit.dart';
import '../../../../core/location/cubit/location_state.dart';

part 'salah_lock_state.dart';

class SalahLockCubit extends Cubit<SalahLockState> {
  final SalahLockRepository repository;
  final SalahNotificationService notificationService;
  final SalahDeviceLockService deviceLockService;
  final SalahCubit salahCubit;
  final LocationCubit locationCubit;

  Timer? _monitoringTimer;
  StreamSubscription? _locationSubscription;
  SalahLockSettings _settings = SalahLockSettings();
  List<Map<String, String>> _ayahs = [];

  SalahLockCubit({
    required this.repository,
    required this.notificationService,
    required this.deviceLockService,
    required this.salahCubit,
    required this.locationCubit,
  }) : super(SalahLockIdle());

  Future<void> init() async {
    _settings = await repository.getSettings();
    final jsonString = await rootBundle.loadString('assets/salah_ayahs.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    _ayahs = jsonList.map((e) => Map<String, String>.from(e)).toList();

    _locationSubscription = locationCubit.stream.listen((locationState) {
      if (locationState is LocationLoaded) {
        startMonitoring(userId: '', locationState: locationState);
      }
    });

    // Initial check
    if (locationCubit.state is LocationLoaded) {
      startMonitoring(
        userId: '',
        locationState: locationCubit.state as LocationLoaded,
      );
    }
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
        emit(SalahLockIdle());
      }
      return;
    }

    final prayerName = _getPrayerName(currentPrayer);
    final isDone = await repository.isSalahCompletedLocally(prayerName);

    if (!isDone) {
      if (state is! SalahLockActive) {
        // Trigger lock
        if (_settings.lockDeviceAndroid) {
          await deviceLockService.lockDevice();
        }

        final randomVerse = _ayahs[Random().nextInt(_ayahs.length)];
        emit(SalahLockActive(salahName: prayerName, verse: randomVerse));
      }
    } else {
      if (state is SalahLockActive) {
        emit(SalahLockIdle());
      }
    }
  }

  Future<void> confirmPrayed(String userId, String salahName) async {
    await salahCubit.markSalahComplete(userId: userId, salahName: salahName);
    await repository.markSalahCompletedLocally(salahName);
    await notificationService.cancelAll();
    emit(SalahLockUnlocked());

    // After 2 seconds, move back to idle so we can lock for next prayer
    Future.delayed(const Duration(seconds: 2), () {
      emit(SalahLockIdle());
    });
  }

  Future<void> remindLater(String salahName) async {
    await notificationService.scheduleReminder(
      salahName,
      const Duration(minutes: 10),
    );
    emit(SalahLockIdle()); // Temporarily dismiss overlay
  }

  Future<void> updateSettings(SalahLockSettings settings) async {
    await repository.saveSettings(settings);
    _settings = settings;
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
    return super.close();
  }
}
