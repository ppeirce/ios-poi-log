import Foundation
import MapKit

struct POI: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let distance: Double

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
        """
        date: \(date)
        time: \(time)
        name: \(name)
        address: \(address)
        coordinates: \(latitude), \(longitude)
        """
    }
}
