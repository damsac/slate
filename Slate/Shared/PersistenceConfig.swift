import Foundation
import SwiftData

enum PersistenceConfig {
    static let appGroupIdentifier: String = {
        // Read from Info.plist which is generated from build settings
        if let identifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String {
            return identifier
        }
        // Fallback to default if not configured
        return "group.com.damsac.slate.shared"
    }()
    static let schemaVersion = 2

    static var modelContainer: ModelContainer {
        deleteStoreIfSchemaChanged()
        let schema = Schema([TodoItem.self])
        let config = ModelConfiguration(
            "Slate",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    static var storeURL: URL {
        let containerURL: URL
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) {
            containerURL = groupURL
        } else {
            // Fallback for simulator/development when App Group entitlement
            // is not available (no development team configured for signing).
            // The widget won't share data in this mode, but the app won't crash.
            // swiftlint:disable:next line_length
            print("⚠️ App Group container unavailable — using default documents directory. Widget data sharing will not work.")
            containerURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
        return containerURL.appendingPathComponent("Slate.store")
    }

    private static func deleteStoreIfSchemaChanged() {
        let defaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard
        let stored = defaults.integer(forKey: "SlateSchemaVersion")
        guard stored < schemaVersion else { return }
        let base = storeURL.path
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(atPath: base + suffix)
        }
        defaults.set(schemaVersion, forKey: "SlateSchemaVersion")
    }
}
