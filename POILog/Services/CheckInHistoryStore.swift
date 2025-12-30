import Foundation
import CoreLocation

struct CheckInRecord: Identifiable, Codable {
    let id: UUID
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let category: String?
    let createdAt: Date

    private static let coordinateScale = 1_000_000.0

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
        self.latitude = Self.roundedCoordinate(latitude)
        self.longitude = Self.roundedCoordinate(longitude)
        self.category = category
        self.createdAt = createdAt
    }

    private static func roundedCoordinate(_ value: Double) -> Double {
        (value * coordinateScale).rounded() / coordinateScale
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

@MainActor
final class CheckInHistoryStore: ObservableObject {
    @Published private(set) var records: [CheckInRecord] = []

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        self.fileURL = (documents ?? URL(fileURLWithPath: NSTemporaryDirectory()))
            .appendingPathComponent("checkins.json")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        load()
    }

    func add(_ record: CheckInRecord) {
        records.insert(record, at: 0)
        save()
    }

    func remove(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        save()
    }

    func exportJSON(records: [CheckInRecord]) -> String {
        let exportEncoder = JSONEncoder()
        exportEncoder.dateEncodingStrategy = .iso8601
        exportEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? exportEncoder.encode(records),
              let output = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return output
    }

    func exportCSV(records: [CheckInRecord]) -> String {
        let header = ["date", "time", "name", "address", "latitude", "longitude", "category"]
        var rows = [header.joined(separator: ",")]

        for record in records {
            let date = Self.dateFormatter.string(from: record.createdAt)
            let time = Self.timeFormatter.string(from: record.createdAt)
            let fields = [
                date,
                time,
                record.name,
                record.address,
                String(format: "%.6f", record.latitude),
                String(format: "%.6f", record.longitude),
                record.category ?? ""
            ]
            rows.append(fields.map(csvEscaped).joined(separator: ","))
        }

        return rows.joined(separator: "\n")
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try decoder.decode([CheckInRecord].self, from: data)
            records = decoded.sorted { $0.createdAt > $1.createdAt }
        } catch {
            records = []
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(records)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            return
        }
    }

    private func csvEscaped(_ value: String) -> String {
        let needsQuotes = value.contains(",") || value.contains("\"") || value.contains("\n")
        if needsQuotes {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

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
