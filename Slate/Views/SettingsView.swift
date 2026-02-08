import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Data", value: "Stored on device")
                }
                Section("Coming Soon") {
                    Label("API Key Configuration", systemImage: "key")
                        .foregroundStyle(.secondary)
                    Label("Cloud Sync", systemImage: "icloud")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
