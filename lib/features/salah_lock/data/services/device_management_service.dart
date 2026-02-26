import 'dart:io';
import 'package:flutter/services.dart';

class DeviceManagementService {
  static const MethodChannel _channel = MethodChannel('neki/device_management');

  // --- Android Specific ---

  Future<bool> isDeviceAdminActive() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod('isDeviceAdminActive') ?? false;
  }

  Future<void> requestDeviceAdmin() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('requestDeviceAdmin');
  }

  Future<bool> checkUsageStatsPermission() async {
    if (!Platform.isAndroid) return true;
    return await _channel.invokeMethod('checkUsageStatsPermission') ?? false;
  }

  Future<void> requestUsageStatsPermission() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('requestUsageStatsPermission');
  }

  Future<bool> checkOverlayPermission() async {
    if (!Platform.isAndroid) return true;
    return await _channel.invokeMethod('checkOverlayPermission') ?? false;
  }

  Future<void> requestOverlayPermission() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('requestOverlayPermission');
  }

  Future<void> startAppBlocker(List<String> blockedApps) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('startAppBlocker', {'blockedApps': blockedApps});
  }

  Future<void> stopAppBlocker() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('stopAppBlocker');
  }

  // --- iOS Specific (FamilyControls / Screen Time) ---

  Future<bool> checkIOSAuthorization() async {
    if (!Platform.isIOS) return true;
    return await _channel.invokeMethod('checkIOSAuthorization') ?? false;
  }

  Future<void> requestIOSAuthorization() async {
    if (!Platform.isIOS) return;
    await _channel.invokeMethod('requestIOSAuthorization');
  }

  Future<void> applyIOSBlockList(List<String> appTokens) async {
    if (!Platform.isIOS) return;
    await _channel.invokeMethod('applyIOSBlockList', {'appTokens': appTokens});
  }

  // --- General ---

  Future<void> lockDeviceScreen() async {
    // Uses the existing neki/device_lock channel or we can move it here
    const lockChannel = MethodChannel('neki/device_lock');
    await lockChannel.invokeMethod('lockDevice');
  }
}
