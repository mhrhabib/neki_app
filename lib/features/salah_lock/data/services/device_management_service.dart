import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class DeviceManagementService {
  static const MethodChannel _channel = MethodChannel('neki/device_management');

  Future<bool> checkExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod('checkExactAlarmPermission') ?? false;
    } catch (e) {
      debugPrint('❌ DeviceManager: Error checking exact alarm permission - $e');
      return false;
    }
  }

  Future<void> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestExactAlarmPermission');
    } catch (e) {
      debugPrint('❌ DeviceManager: Error requesting exact alarm permission - $e');
    }
  }

  Future<bool> isBatteryOptimizationIgnored() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod('isBatteryOptimizationIgnored') ?? false;
    } catch (e) {
      debugPrint('❌ DeviceManager: Error checking battery optimization - $e');
      return false;
    }
  }

  Future<void> requestIgnoreBatteryOptimization() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimization');
    } catch (e) {
      debugPrint('❌ DeviceManager: Error requesting battery optimization exemption - $e');
    }
  }

  // --- iOS Screen Time (FamilyControls / ManagedSettings) ---

  Future<bool> requestIOSAuthorization() async {
    if (!Platform.isIOS) return true;
    try {
      return await _channel.invokeMethod('requestIOSAuthorization') ?? false;
    } catch (e) {
      debugPrint('❌ DeviceManager: Error requesting iOS authorization - $e');
      return false;
    }
  }

  Future<bool> checkIOSAuthorization() async {
    if (!Platform.isIOS) return true;
    try {
      return await _channel.invokeMethod('checkIOSAuthorization') ?? false;
    } catch (e) {
      debugPrint('❌ DeviceManager: Error checking iOS authorization - $e');
      return false;
    }
  }

  Future<bool> selectBlockedApps() async {
    if (!Platform.isIOS) return false;
    try {
      return await _channel.invokeMethod('selectBlockedApps') ?? false;
    } catch (e) {
      debugPrint('❌ DeviceManager: Error showing app picker - $e');
      return false;
    }
  }

  Future<void> schedulePrayerAlarmsIOS({
    required List<double> prayerTimes,
    required List<String> prayerNames,
  }) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('schedulePrayerAlarms', {
        'prayerTimes': prayerTimes,
        'prayerNames': prayerNames,
      });
    } catch (e) {
      debugPrint('❌ DeviceManager: Error scheduling iOS prayer alarms - $e');
    }
  }
}
