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
}
