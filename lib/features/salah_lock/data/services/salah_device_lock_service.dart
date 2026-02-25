import 'dart:io';
import 'package:flutter/services.dart';

class SalahDeviceLockService {
  static const MethodChannel _channel = MethodChannel('neki/device_lock');

  Future<bool> lockDevice() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? result = await _channel.invokeMethod('lockDevice');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> isDeviceAdminActive() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? result = await _channel.invokeMethod('isDeviceAdminActive');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<void> requestDeviceAdmin() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestDeviceAdmin');
    } on PlatformException catch (_) {}
  }
}
