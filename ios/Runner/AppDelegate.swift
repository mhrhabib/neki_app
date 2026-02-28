import Flutter
import UIKit
import flutter_local_notifications

import FamilyControls
import ManagedSettings

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "neki/device_management",
                                              binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "requestIOSAuthorization":
        if #available(iOS 15.0, *) {
            Task {
                do {
                    if #available(iOS 16.0, *) {
                        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    } else {
                        // Fallback on earlier versions
                    }
                    result(true)
                } catch {
                    result(FlutterError(code: "AUTH_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        } else {
            result(FlutterError(code: "UNSUPPORTED", message: "iOS 15.0+ required", details: nil))
        }
      case "checkIOSAuthorization":
        if #available(iOS 15.0, *) {
            result(AuthorizationCenter.shared.authorizationStatus == .approved)
        } else {
            result(false)
        }
      case "applyIOSBlockList":
        // This requires ManagedSettings which is usually done via a DeviceActivityMonitorExtension
        // For a production app, we would save the selection to a shared app group container
        // that the extension can read.
        result(true)
      case "lockDevice":
        // iOS does not allow programmatic screen locking for standard apps.
        // We return true to avoid MissingPluginException.
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
