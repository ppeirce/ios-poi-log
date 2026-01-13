import Foundation
import SwiftData

struct MigrationService {
    private static let migrationKey = "didMigrateFromJSON_v1"

    static func migrateIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let legacyURL = URL.documentsDirectory.appending(path: "checkins.json")

        guard FileManager.default.fileExists(atPath: legacyURL.path) else {
            UserDefaults.standard.set(true, forKey: migrationKey)
            return
        }

        do {
            let data = try Data(contentsOf: legacyURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let legacyRecords = try decoder.decode([LegacyCheckInRecord].self, from: data)

            let existingIDs: Set<UUID>
            do {
                let descriptor = FetchDescriptor<CheckIn>()
                let existing = try context.fetch(descriptor)
                existingIDs = Set(existing.map(\.id))
            } catch {
                existingIDs = []
            }

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

            let backupURL = legacyURL.deletingLastPathComponent()
                .appending(path: "checkins.json.migrated")
            try? FileManager.default.moveItem(at: legacyURL, to: backupURL)

            UserDefaults.standard.set(true, forKey: migrationKey)
        } catch {
            print("Migration failed: \(error)")
        }
    }
}

struct LegacyCheckInRecord: Codable {
    let id: UUID
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let category: String?
    let createdAt: Date
}
