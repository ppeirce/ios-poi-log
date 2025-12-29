import SwiftUI

struct SettingsView: View {
    @ObservedObject var searchManager: POISearchManager

    var body: some View {
        Form {
            Section("Categories") {
                NavigationLink {
                    CategorySelectionView(searchManager: searchManager)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("POI Categories")
                        Text(selectedSummary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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

    private var selectedSummary: String {
        let selections = searchManager.selectedCategories
        if selections.isEmpty {
            return "None selected"
        }
        if selections.count == POISearchManager.availableCategories.count {
            return "All categories"
        }

        let names = selections.map(\.displayName).sorted()
        if names.count <= 3 {
            return names.joined(separator: ", ")
        }
        return "\(names.count) selected"
    }
}

#Preview {
    SettingsView(searchManager: POISearchManager())
}
