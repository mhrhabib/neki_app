import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class DeviceManagementService {
  static const MethodChannel _channel = MethodChannel('neki/device_management');

  // --- Android Specific ---

  Future<bool> isDeviceAdminActive() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod('isDeviceAdminActive') ?? false;
      debugPrint('🔒 DeviceManager: isDeviceAdminActive = $result');
      return result;
    } catch (e) {
      debugPrint('❌ DeviceManager: Error checking admin status - $e');
      return false;
    }
  }

  Future<void> requestDeviceAdmin() async {
    if (!Platform.isAndroid) return;
    try {
      debugPrint('🔒 DeviceManager: Requesting device admin...');
      await _channel.invokeMethod('requestDeviceAdmin');
    } catch (e) {
      debugPrint('❌ DeviceManager: Error requesting admin - $e');
    }
  }

  Future<bool> checkUsageStatsPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod('checkUsageStatsPermission') ?? false;
    } catch (e) {
      debugPrint('❌ DeviceManager: Error checking usage stats - $e');
      return false;
    }
  }

  Future<void> requestUsageStatsPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestUsageStatsPermission');
    } catch (e) {
      debugPrint('❌ DeviceManager: Error requesting usage stats - $e');
    }
  }

  Future<bool> checkOverlayPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod('checkOverlayPermission') ?? false;
    } catch (e) {
      debugPrint('❌ DeviceManager: Error checking overlay permission - $e');
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      debugPrint('❌ DeviceManager: Error requesting overlay permission - $e');
    }
  }

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

  Future<void> scheduleBackgroundAlarms(Map<String, DateTime> prayerTimes) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final List<dynamic> times = [];
      final List<String> names = [];

      prayerTimes.forEach((name, time) {
        times.add(time.millisecondsSinceEpoch);
        names.add(name);
      });

      debugPrint('⏰ DeviceManager: Scheduling ${names.length} background alarms/activities');
      await _channel.invokeMethod('schedulePrayerAlarms', {
        'prayerTimes': times,
        'prayerNames': names,
      });
    } catch (e) {
      debugPrint('❌ DeviceManager: Error scheduling background alarms - $e');
    }
  }

  Future<void> cancelBackgroundAlarms() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      debugPrint('⏰ DeviceManager: Cancelling background alarms/activities');
      await _channel.invokeMethod('cancelPrayerAlarms');
    } catch (e) {
      debugPrint('❌ DeviceManager: Error cancelling background alarms - $e');
    }
  }

  // --- Unified / Universal ---

  Future<void> startAppBlocker(List<String> blockedApps) async {
    try {
      debugPrint('🚫 DeviceManager: Starting app blocker (${Platform.isAndroid ? 'Android' : 'iOS'})');
      await _channel.invokeMethod('startAppBlocker', {'blockedApps': blockedApps});
    } catch (e) {
      debugPrint('❌ DeviceManager: Error starting app blocker - $e');
    }
  }

  Future<void> stopAppBlocker() async {
    try {
      debugPrint('🚫 DeviceManager: Stopping app blocker (${Platform.isAndroid ? 'Android' : 'iOS'})');
      await _channel.invokeMethod('stopAppBlocker');
    } catch (e) {
      debugPrint('❌ DeviceManager: Error stopping app blocker - $e');
    }
  }

  // --- iOS Specific (FamilyControls / Screen Time) ---

  Future<bool> checkIOSAuthorization() async {
    if (!Platform.isIOS) return true;
    try {
      return await _channel.invokeMethod('checkIOSAuthorization') ?? false;
    } catch (e) {
      debugPrint('❌ DeviceManager: Error checking iOS authorization - $e');
      return false;
    }
  }

  Future<void> requestIOSAuthorization() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('requestIOSAuthorization');
    } catch (e) {
      debugPrint('❌ DeviceManager: Error requesting iOS authorization - $e');
    }
  }

  /// Opens the native iOS Apple Picker for the user to select which apps to block.
  Future<void> selectBlockedApps() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('selectBlockedApps');
    } catch (e) {
      debugPrint('❌ DeviceManager: Error selecting apps - $e');
    }
  }

  // --- General ---

  Future<void> lockDeviceScreen() async {
    try {
      debugPrint('🔒 DeviceManager: Calling native lockDevice()...');
      await _channel.invokeMethod('lockDevice');
      debugPrint('✅ DeviceManager: lockDevice() returned successfully');
    } catch (e) {
      debugPrint('❌ DeviceManager: Error locking device - $e');
      rethrow;
    }
  }
}
