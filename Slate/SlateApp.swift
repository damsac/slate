import SwiftUI
import SwiftData
import WidgetKit

@main
struct SlateApp: App {
    let modelContainer = PersistenceConfig.modelContainer

    init() {
        NotificationManager.shared.setup()
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            TodoListView()
        }
        .modelContainer(modelContainer)
    }
}
