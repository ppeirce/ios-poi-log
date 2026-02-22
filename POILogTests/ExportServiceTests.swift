import Testing
import Foundation
import SwiftData
@testable import POILog

@Suite("ExportService")
struct ExportServiceTests {
    private func makeCheckIn(
        name: String = "Test Place",
        address: String = "123 Main St",
        latitude: Double = 37.801200,
        longitude: Double = -122.272700,
        category: String? = "Restaurant",
        createdAt: Date = Date()
    ) -> CheckIn {
        CheckIn(
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
            category: category,
            createdAt: createdAt
        )
    }

    @Test("CSV header row")
    func csvHeader() {
        let csv = ExportService.exportCSV([])
        #expect(csv == "date,time,name,address,latitude,longitude,category")
    }

    @Test("CSV escapes commas in fields")
    func csvEscapesCommas() {
        let checkIn = makeCheckIn(address: "300 Webster St, Oakland, CA 94607")
        let csv = ExportService.exportCSV([checkIn])
        let lines = csv.split(separator: "\n")
        #expect(lines.count == 2)
        // Address with comma should be quoted
        #expect(lines[1].contains("\"300 Webster St, Oakland, CA 94607\""))
    }

    @Test("CSV escapes quotes in fields")
    func csvEscapesQuotes() {
        let checkIn = makeCheckIn(name: "Joe's \"Best\" Pizza")
        let csv = ExportService.exportCSV([checkIn])
        // Quotes should be doubled and field should be quoted
        #expect(csv.contains("\"Joe's \"\"Best\"\" Pizza\""))
    }

    @Test("JSON output is valid and contains fields")
    func jsonOutput() {
        let checkIn = makeCheckIn()
        let json = ExportService.exportJSON([checkIn])
        #expect(json.contains("\"name\" : \"Test Place\""))
        #expect(json.contains("\"address\" : \"123 Main St\""))
        #expect(json.contains("\"category\" : \"Restaurant\""))
        #expect(json.contains("\"latitude\""))
        #expect(json.contains("\"longitude\""))
    }

    @Test("JSON empty array")
    func jsonEmpty() {
        let json = ExportService.exportJSON([])
        #expect(json == "[\n\n]")
    }
}
