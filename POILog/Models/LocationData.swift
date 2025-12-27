import Foundation
import CoreLocation

struct LocationData {
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date

    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: timestamp)
    }
}
