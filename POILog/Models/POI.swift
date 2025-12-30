import Foundation
import MapKit

struct POI: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let distance: Double
    let category: String?

    var formattedDistance: String {
        let miles = distance / 1609.34
        if miles < 0.01 {
            return String(format: "%.0f ft", distance * 3.28084)
        }
        return String(format: "%.2f mi", miles)
    }
}

struct CaptureData: Codable {
    let date: String
    let time: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double

    var yamlString: String {
        let formattedLatitude = String(format: "%.6f", latitude)
        let formattedLongitude = String(format: "%.6f", longitude)
        return """
        date: \(date)
        time: \(time)
        name: \(name)
        address: \(address)
        coordinates: \(formattedLatitude), \(formattedLongitude)
        """
    }
}
