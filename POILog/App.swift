import SwiftUI
import SwiftData

@main
struct POILogApp: App {
    @State private var modelContainer: ModelContainer?
    @State private var migrationComplete = false
    @State private var isInitializing = false

    var body: some Scene {
        WindowGroup {
            if let container = modelContainer, migrationComplete {
                ContentView()
                    .modelContainer(container)
            } else {
                MigrationView()
                    .task {
                        await initializeStore()
                    }
            }
        }
    }

    private func initializeStore() async {
        guard !isInitializing else { return }
        isInitializing = true

        let schema = Schema([CheckIn.self])
        let appSupport = URL.applicationSupportDirectory
        let storeURL = appSupport.appending(path: "CheckIns.store")

        try? FileManager.default.createDirectory(
            at: appSupport,
            withIntermediateDirectories: true
        )

        let container: ModelContainer
        do {
            let config = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        await MainActor.run {
            MigrationService.migrateIfNeeded(context: container.mainContext)
        }

        await MainActor.run {
            self.modelContainer = container
            self.migrationComplete = true
        }
    }
}

private struct MigrationView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading...")
                .foregroundStyle(.secondary)
        }
    }
}
