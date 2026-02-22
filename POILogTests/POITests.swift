import Testing
import CoreLocation
@testable import POILog

@Suite("POI Model")
struct POITests {
    @Test("formattedDistance shows feet when under 0.01 miles")
    func formattedDistanceFeet() {
        let poi = POI(
            name: "Test",
            address: "123 Main St",
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            distance: 3.0, // ~10 feet
            category: nil
        )
        #expect(poi.formattedDistance == "10 ft")
    }

    @Test("formattedDistance shows miles when 0.01+ miles")
    func formattedDistanceMiles() {
        let poi = POI(
            name: "Test",
            address: "123 Main St",
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            distance: 1609.34, // 1 mile
            category: nil
        )
        #expect(poi.formattedDistance == "1.00 mi")
    }

    @Test("formattedDistance at boundary")
    func formattedDistanceBoundary() {
        // 0.01 miles = 16.0934 meters
        let poi = POI(
            name: "Test",
            address: "123 Main St",
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            distance: 16.0934,
            category: nil
        )
        #expect(poi.formattedDistance == "0.01 mi")
    }
}

@Suite("CaptureData YAML")
struct CaptureDataTests {
    @Test("yamlString formats correctly")
    func yamlStringFormat() {
        let data = CaptureData(
            date: "2025-12-27",
            time: "09:12",
            name: "Blue Bottle Coffee",
            address: "300 Webster St, Oakland, CA 94607",
            latitude: 37.8012,
            longitude: -122.2727
        )

        #expect(data.yamlString.contains("date: 2025-12-27"))
        #expect(data.yamlString.contains("time: 09:12"))
        #expect(data.yamlString.contains("name: Blue Bottle Coffee"))
        #expect(data.yamlString.contains("coordinates: 37.801200, -122.272700"))
    }

    @Test("yamlString rounds coordinates to 6 decimal places")
    func yamlCoordinatePrecision() {
        let data = CaptureData(
            date: "2025-01-01",
            time: "12:00",
            name: "Test",
            address: "Test",
            latitude: 37.12345678,
            longitude: -122.98765432
        )

        #expect(data.yamlString.contains("coordinates: 37.123457, -122.987654"))
    }
}
