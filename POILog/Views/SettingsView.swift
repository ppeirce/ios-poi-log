import SwiftUI

struct SettingsView: View {
    @ObservedObject var searchManager: POISearchManager

    var body: some View {
        Form {
            Section("Filters") {
                Toggle("Return only restaurants", isOn: $searchManager.onlyRestaurants)

                Text("When enabled, the app only searches for restaurants.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Debug") {
                Toggle("Debug mode", isOn: $searchManager.debugMode)

                Text("Shows POI diagnostics and searches from the map center.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView(searchManager: POISearchManager())
}
