import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

// MARK: - DeviceActivity Monitor Extension
// This code should be placed in a separate "Device Activity Monitor" extension target in Xcode.

class SalahActivityMonitor: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    let activityKey = "neki_blocked_selection"

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        // Log the start
        print("🕌 Salah Lock: Activity started for \(activity.rawValue)")
        
        // 1. Load the selection from shared UserDefaults (using App Group)
        // Note: You must set up an App Group to share data between the main app and the extension.
        let suiteName = "group.com.clearwavesystems.nekiapp"
        let sharedDefaults = UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
        
        if let data = sharedDefaults.data(forKey: activityKey) {
            let decoder = JSONDecoder()
            do {
                let selection = try decoder.decode(FamilyActivitySelection.self, from: data)
                // 2. Apply the shield
                store.shield.applications = selection.applicationTokens
                store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : selection.categoryTokens
                print("🔒 Salah Lock: Shield applied successfully for \(selection.applicationTokens.count) apps")
            } catch {
                print("❌ Salah Lock: Failed to decode selection - \(error)")
            }
        } else {
            print("⚠️ Salah Lock: No selection found in shared storage (\(suiteName))")
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        // 1. Remove the shield
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        print("🔓 Salah Lock: Shield removed")
    }
}
