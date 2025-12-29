import SwiftUI
import MapKit

struct SettingsView: View {
    @ObservedObject var searchManager: POISearchManager

    var body: some View {
        Form {
            Section("Categories") {
                ForEach(POISearchManager.availableCategories, id: \.rawValue) { category in
                    Toggle(category.displayName, isOn: binding(for: category))
                }

                Text("Defaults to Restaurants and Nightlife (Bars).")
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

    private func binding(for category: MKPointOfInterestCategory) -> Binding<Bool> {
        Binding(
            get: { searchManager.selectedCategories.contains(category) },
            set: { isOn in
                if isOn {
                    searchManager.selectedCategories.insert(category)
                } else {
                    searchManager.selectedCategories.remove(category)
                }
            }
        )
    }
}

#Preview {
    SettingsView(searchManager: POISearchManager())
}
