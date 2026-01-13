import Foundation

struct ExportService {
    static func exportJSONFile(_ checkIns: [CheckIn]) -> URL {
        let content = exportJSON(checkIns)
        return writeToTempFile(content: content, extension: "json")
    }

    static func exportCSVFile(_ checkIns: [CheckIn]) -> URL {
        let content = exportCSV(checkIns)
        return writeToTempFile(content: content, extension: "csv")
    }

    private static func writeToTempFile(content: String, extension ext: String) -> URL {
        let filename = "poi-log-\(filenameFormatter.string(from: Date())).\(ext)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static let filenameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter
    }()

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

    private static func csvEscaped(_ value: String) -> String {
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
