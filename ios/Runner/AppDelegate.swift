import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications
import FamilyControls
import ManagedSettings
import SwiftUI
import DeviceActivity

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  // Storage for the selected apps to block
  private var _selection: Any?
  private var _store: Any?
  private let activityKey = "neki_blocked_selection"

  @available(iOS 15.0, *)
  private var selection: FamilyActivitySelection {
    get {
      if _selection == nil { _selection = FamilyActivitySelection() }
      return _selection as! FamilyActivitySelection
    }
    set { _selection = newValue }
  }

  @available(iOS 15.0, *)
  private var store: ManagedSettingsStore {
    if _store == nil { _store = ManagedSettingsStore() }
    return _store as! ManagedSettingsStore
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "neki/device_management",
                                              binaryMessenger: controller.binaryMessenger)
    
    // Load existing selection from UserDefaults if possible
    if #available(iOS 15.0, *) {
      loadSelection()
    }

    channel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard let self = self else { return }
      
      switch call.method {
      case "requestIOSAuthorization":
        if #available(iOS 16.0, *) {
          Task {
            do {
              try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
              DispatchQueue.main.async { result(true) }
            } catch {
              DispatchQueue.main.async { result(FlutterError(code: "AUTH_FAILED", message: error.localizedDescription, details: nil)) }
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

      case "selectBlockedApps":
        // Show the native SwiftUI FamilyActivityPicker
        self.showPicker(result: result)

      case "startAppBlocker":
        // On iOS, starting the app blocker means applying the shield
        self.applyShield(result: result)

      case "stopAppBlocker":
        // On iOS, stopping means clearing the shield
        self.removeShield(result: result)

      case "schedulePrayerAlarms":
        if #available(iOS 15.0, *) {
            let args = call.arguments as? [String: Any]
            let prayerTimes = args?["prayerTimes"] as? [Double] ?? []
            let prayerNames = args?["prayerNames"] as? [String] ?? []
            self.scheduleActivities(times: prayerTimes, names: prayerNames, result: result)
        } else {
            result(FlutterError(code: "UNSUPPORTED", message: "iOS 15.0+ required", details: nil))
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    })

    // Set notification center delegate so flutter_local_notifications can
    // display banners, play sounds, and handle actions on iOS
    UNUserNotificationCenter.current().delegate = self

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Shield Logic

  private func applyShield(result: FlutterResult) {
    if #available(iOS 16.0, *) {
        // Apply the selection to ManagedSettings
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        result(true)
    } else {
        result(FlutterError(code: "UNSUPPORTED", message: "Shielding requires iOS 16.0+", details: nil))
    }
  }

  private func removeShield(result: FlutterResult) {
    if #available(iOS 16.0, *) {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        result(true)
    } else {
        result(true) // No-op on older versions
    }
  }

  // MARK: - Picker Logic

  private func showPicker(result: @escaping FlutterResult) {
    if #available(iOS 15.0, *) {
        let pickerProvider = PickerProvider(selection: self.selection) { newSelection in
            self.selection = newSelection
            self.saveSelection()
            result(true)
        }
        
        let hostingController = UIHostingController(rootView: pickerProvider)
        if let rootVC = window?.rootViewController {
            rootVC.present(hostingController, animated: true)
        }
    } else {
        result(FlutterError(code: "UNSUPPORTED", message: "iOS 15.0+ required for picker", details: nil))
    }
  }

  @available(iOS 15.0, *)
  private func saveSelection() {
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(selection) {
        UserDefaults.standard.set(encoded, forKey: activityKey)
    }
  }

  @available(iOS 15.0, *)
  private func loadSelection() {
    if let data = UserDefaults.standard.data(forKey: activityKey) {
        let decoder = JSONDecoder()
        if let loaded = try? decoder.decode(FamilyActivitySelection.self, from: data) {
            self.selection = loaded
        }
    }
  }

  // MARK: - DeviceActivity Monitoring

  @available(iOS 15.0, *)
  private func scheduleActivities(times: [Double], names: [String], result: FlutterResult) {
      let center = DeviceActivityCenter()
      
      // Clear existing activities first
      center.stopMonitoring()
      
      for (index, timeInterval) in times.enumerated() {
          let date = Date(timeIntervalSince1970: timeInterval / 1000)
          let name = names[index]
          
          let calendar = Calendar.current
          let components = calendar.dateComponents([.hour, .minute], from: date)
          
          guard let hour = components.hour, let minute = components.minute else { continue }
          
          // Create a schedule for a 20-minute window around the prayer time
          // (e.g., 5 mins before, 15 mins after, or just 20 mins total)
          let startComponents = DateComponents(hour: hour, minute: minute)
          let endComponents = calendar.dateComponents([.hour, .minute], from: date.addingTimeInterval(20 * 60))
          
          let schedule = DeviceActivitySchedule(
              intervalStart: startComponents,
              intervalEnd: endComponents,
              repeats: true
          )
          
          let activityName = DeviceActivityName("neki.prayer.\(name)")
          
          do {
              try center.startMonitoring(activityName, during: schedule)
              print("✅ iOS: Scheduled activity for \(name) at \(hour):\(minute)")
          } catch {
              print("❌ iOS: Failed to schedule activity for \(name): \(error.localizedDescription)")
          }
      }
      result(true)
  }
}

// Helper for SwiftUI Picker
@available(iOS 15.0, *)
struct PickerProvider: View {
    @State var selection: FamilyActivitySelection
    var onSave: (FamilyActivitySelection) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Select Restricted Apps")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            onSave(selection)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
        }
    }
}
