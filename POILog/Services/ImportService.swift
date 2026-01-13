import Foundation
import SwiftData

struct ImportResult {
    let imported: Int
    let skipped: Int
}

enum ImportError: LocalizedError {
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Could not access the selected file."
        }
    }
}

struct ImportService {
    static func importJSON(from url: URL, context: ModelContext) throws -> ImportResult {
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let records = try decoder.decode([ImportRecord].self, from: data)

        let descriptor = FetchDescriptor<CheckIn>()
        let existing = try context.fetch(descriptor)
        let existingIDs = Set(existing.map(\.id))

        var imported = 0
        var skipped = 0

        for record in records {
            if existingIDs.contains(record.id) {
                skipped += 1
                continue
            }

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
            imported += 1
        }

        try context.save()
        return ImportResult(imported: imported, skipped: skipped)
    }
}

private struct ImportRecord: Codable {
    let id: UUID
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let category: String?
    let createdAt: Date
}
