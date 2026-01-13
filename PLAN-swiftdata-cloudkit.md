# SwiftData + CloudKit Implementation Plan

## Overview

Migrate from JSON-file persistence to SwiftData with CloudKit sync, providing:
- Cross-device sync via iCloud
- Data survives app deletion (restores on reinstall)
- Graceful fallback to local-only when iCloud unavailable
- Automatic sync when iCloud becomes available later

**Target**: iOS 26

---

## Phase 1: Project Setup

### Xcode Capabilities (via UI)

| Capability | Setting |
|------------|---------|
| iCloud | Enable CloudKit, container `iCloud.com.yourteam.POILog` |
| Push Notifications | Enable (sets `aps-environment` for Debug/Release) |
| Background Modes | Remote notifications |

### Checklist

```
[ ] Add iCloud capability → CloudKit container (Xcode UI)
[ ] Add Push Notifications capability (Xcode UI)
[ ] Add Background Modes → Remote notifications (Xcode UI)
[ ] Verify entitlements file has correct container ID
```

---

## Phase 2: Data Model

### POILog/Models/CheckIn.swift

```swift
import Foundation
import SwiftData
import CoreLocation

@Model
final class CheckIn {
    @Attribute(.unique) var id: UUID
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var category: String?
    var createdAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        category: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = Self.rounded(latitude)
        self.longitude = Self.rounded(longitude)
        self.category = category
        self.createdAt = createdAt
    }

    private static func rounded(_ value: Double) -> Double {
        (value * 1_000_000).rounded() / 1_000_000
    }
}
```

---

## Phase 3: ModelContainer with Shared Store URL

### Key Design Decision

Use the same explicit store URL for both CloudKit and local-only configs. This ensures:
- If CloudKit fails initially but works later, the same store syncs
- No data stranded in a separate local-only file

### POILog/App.swift

```swift
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
        // Guard against double-initialization
        guard !isInitializing else { return }
        isInitializing = true

        let schema = Schema([CheckIn.self])

        // Use Application Support (not Documents) to avoid Files app visibility
        let appSupport = URL.applicationSupportDirectory
        let storeURL = appSupport.appending(path: "CheckIns.store")

        // Ensure directory exists
        try? FileManager.default.createDirectory(
            at: appSupport,
            withIntermediateDirectories: true
        )

        let container: ModelContainer
        do {
            let cloudConfig = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .private("iCloud.com.yourteam.POILog")
            )
            container = try ModelContainer(for: schema, configurations: cloudConfig)
        } catch {
            // CloudKit unavailable—use same store URL, local-only
            print("CloudKit unavailable, using local storage: \(error)")
            do {
                let localConfig = ModelConfiguration(
                    schema: schema,
                    url: storeURL,
                    cloudKitDatabase: .none
                )
                container = try ModelContainer(for: schema, configurations: localConfig)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }

        // Run migration on main actor
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
```

---

## Phase 4: Migration Service

### POILog/Services/MigrationService.swift

```swift
import Foundation
import SwiftData

struct MigrationService {
    private static let migrationKey = "didMigrateFromJSON_v1"

    static func migrateIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let legacyURL = URL.documentsDirectory.appending(path: "checkins.json")

        guard FileManager.default.fileExists(atPath: legacyURL.path) else {
            // No legacy file—mark complete, nothing to migrate
            UserDefaults.standard.set(true, forKey: migrationKey)
            return
        }

        do {
            let data = try Data(contentsOf: legacyURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let legacyRecords = try decoder.decode([LegacyCheckInRecord].self, from: data)

            // Fetch existing IDs in SwiftData to avoid duplicates
            let existingIDs: Set<UUID>
            do {
                let descriptor = FetchDescriptor<CheckIn>()
                let existing = try context.fetch(descriptor)
                existingIDs = Set(existing.map(\.id))
            } catch {
                existingIDs = []
            }

            // Track IDs seen in this migration to handle duplicates in JSON file
            var seenIDs = existingIDs

            for record in legacyRecords {
                guard !seenIDs.contains(record.id) else { continue }
                seenIDs.insert(record.id)

                let checkIn = CheckIn(
                    id: record.id,
                    name: record.name,
                    address: record.address,
                    latitude: record.latitude,
                    longitude: record.longitude,
                    category: record.category,
                    createdAt: record.createdAt
                )
                context.insert(checkIn)
            }

            try context.save()

            // Archive legacy file
            let backupURL = legacyURL.deletingLastPathComponent()
                .appending(path: "checkins.json.migrated")
            try? FileManager.default.moveItem(at: legacyURL, to: backupURL)

            UserDefaults.standard.set(true, forKey: migrationKey)

        } catch {
            // Log but don't crash—will retry next launch
            print("Migration failed: \(error)")
        }
    }
}

// Keep for migration only—remove after migration window
struct LegacyCheckInRecord: Codable {
    let id: UUID
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let category: String?
    let createdAt: Date
}
```

---

## Phase 5: Export Service

### POILog/Services/ExportService.swift

Matches existing CSV/JSON formatting exactly (date format, coordinate precision).

```swift
import Foundation

struct ExportService {

    // MARK: - JSON Export

    static func exportJSON(_ checkIns: [CheckIn]) -> String {
        let records = checkIns.map { ExportRecord(from: $0) }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(records),
              let output = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return output
    }

    // MARK: - CSV Export

    static func exportCSV(_ checkIns: [CheckIn]) -> String {
        let header = ["date", "time", "name", "address", "latitude", "longitude", "category"]
        var rows = [header.joined(separator: ",")]

        for checkIn in checkIns {
            let date = Self.dateFormatter.string(from: checkIn.createdAt)
            let time = Self.timeFormatter.string(from: checkIn.createdAt)
            let fields = [
                date,
                time,
                checkIn.name,
                checkIn.address,
                String(format: "%.6f", checkIn.latitude),
                String(format: "%.6f", checkIn.longitude),
                checkIn.category ?? ""
            ]
            rows.append(fields.map(csvEscaped).joined(separator: ","))
        }

        return rows.joined(separator: "\n")
    }

    // MARK: - Helpers

    private static func csvEscaped(_ value: String) -> String {
        let needsQuotes = value.contains(",") || value.contains("\"") || value.contains("\n")
        if needsQuotes {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    // Match existing formatters exactly
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

// Codable struct for JSON export (decoupled from SwiftData)
private struct ExportRecord: Codable {
    let id: UUID
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let category: String?
    let createdAt: Date

    init(from checkIn: CheckIn) {
        self.id = checkIn.id
        self.name = checkIn.name
        self.address = checkIn.address
        self.latitude = checkIn.latitude
        self.longitude = checkIn.longitude
        self.category = checkIn.category
        self.createdAt = checkIn.createdAt
    }
}
```

---

## Phase 6: Update Views

### Pattern: @Query with stable identity

Use `ForEach(checkIns, id: \.id)` so SwiftUI identity is stable across migrations. `@Model` defaults to `persistentModelID`, which changes across installs.

```swift
struct VisitedPlacesView: View {
    @Query(sort: \CheckIn.createdAt, order: .reverse)
    private var checkIns: [CheckIn]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        // ...
        ForEach(checkIns, id: \.id) { checkIn in
            // ...
        }
    }

    private func delete(_ checkIn: CheckIn) {
        modelContext.delete(checkIn)
        do {
            try modelContext.save()
        } catch {
            print("Delete failed: \(error)")
        }
    }
}
```

### Pattern: Preview helpers

```swift
#Preview {
    VisitedPlacesView(locationManager: LocationManager())
        .modelContainer(for: CheckIn.self, inMemory: true)
}
```

---

## Phase 7: Files to Create/Modify

| Action | File | Notes |
|--------|------|-------|
| Create | `POILog/Models/CheckIn.swift` | Add to project.pbxproj |
| Create | `POILog/Services/MigrationService.swift` | Add to project.pbxproj |
| Create | `POILog/Services/ExportService.swift` | Add to project.pbxproj |
| Modify | `POILog/App.swift` | ModelContainer + migration + loading view |
| Modify | `POILog/Views/VisitedPlacesView.swift` | @Query, modelContext, ForEach id, preview |
| Modify | `POILog/Views/VisitedPlaceDetailView.swift` | @Query/modelContext, preview |
| Modify | `POILog/Views/YAMLPreviewView.swift` | modelContext for inserts |
| Modify | `POILog/Views/ContentView.swift` | Remove @EnvironmentObject |
| Delete | `POILog/Services/CheckInHistoryStore.swift` | After migration verified |

---

## Pre-Release Checklist

```
[ ] Update POILog.xcodeproj/project.pbxproj with new Swift files
[ ] Add iCloud capability with CloudKit container (Xcode UI)
[ ] Add Push Notifications capability (Xcode UI)
[ ] Add Background Modes → Remote notifications (Xcode UI)
[ ] Test fresh install—no migration, empty state works
[ ] Test upgrade install—migration runs once, no duplicates
[ ] Test with iCloud disabled—local fallback works, no crash
[ ] Test iCloud disabled → enabled—data syncs after re-enable
[ ] Test cross-device sync (two devices, same iCloud account)
[ ] Test offline edits sync when back online
[ ] Verify export JSON matches old format exactly
[ ] Verify export CSV matches old format exactly
[ ] Deploy CloudKit schema to Production (CloudKit Dashboard) BEFORE TestFlight
```

---

## Post-Release Cleanup

After 2-3 app versions when migration window has passed:

```
[ ] Remove LegacyCheckInRecord struct
[ ] Remove MigrationService (or keep skeleton for future migrations)
[ ] Remove CheckInHistoryStore.swift from project
[ ] Remove checkins.json.migrated backup handling
```

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Migration loses data | Archive old file as `.migrated`, don't delete |
| Duplicate UUIDs in legacy JSON | `seenIDs` set skips duplicates during migration |
| CloudKit quota/rate limits | Unlikely for personal use; monitor in CloudKit Dashboard |
| Sync conflicts | SwiftData uses last-write-wins; acceptable for single-user |
| Offline edits not syncing | SwiftData queues changes; verify with airplane mode testing |
| iCloud disabled permanently | Local-only fallback works; same store syncs if enabled later |
| Store visible in Files app | Using Application Support, not Documents |

---

## Future Considerations

- **Predicate-based queries**: Current in-memory filtering is fine for small datasets. If history grows large, migrate to `#Predicate` in `@Query`.
- **Sharing (friends' check-ins)**: Would require backend service; CloudKit private database doesn't support social features.
- **Schema migrations**: SwiftData handles lightweight migrations. For complex changes, add explicit migration logic.
