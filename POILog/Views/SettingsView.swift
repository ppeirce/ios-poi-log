import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var searchManager: POISearchManager
    @Environment(\.modelContext) private var modelContext

    @State private var showingImporter = false
    @State private var importResult: ImportResult?
    @State private var importError: Error?
    @State private var showingResult = false

    var body: some View {
        Form {
            Section("Data") {
                Button("Import from JSON") {
                    showingImporter = true
                }

                Text("Restore check-ins from a previously exported file.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

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
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json]
        ) { result in
            handleImport(result)
        }
        .alert("Import Complete", isPresented: $showingResult) {
            Button("OK") { }
        } message: {
            if let result = importResult {
                Text("Imported \(result.imported) records.\(result.skipped > 0 ? " \(result.skipped) duplicates skipped." : "")")
            } else if let error = importError {
                Text("Import failed: \(error.localizedDescription)")
            }
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                importResult = try ImportService.importJSON(from: url, context: modelContext)
                importError = nil
            } catch {
                importResult = nil
                importError = error
            }
            showingResult = true
        case .failure(let error):
            importResult = nil
            importError = error
            showingResult = true
        }
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
        .modelContainer(for: CheckIn.self, inMemory: true)
}
