import Foundation
import MapKit
import Combine

@MainActor
class POISearchManager: ObservableObject {
    @Published var nearbyPOIs: [POI] = []
    @Published var isSearching = false
    @Published var error: Error?
    @Published var onlyRestaurants: Bool {
        didSet {
            userDefaults.set(onlyRestaurants, forKey: Self.onlyRestaurantsKey)
        }
    }
    @Published var debugMode: Bool {
        didSet {
            userDefaults.set(debugMode, forKey: Self.debugModeKey)
        }
    }

    static let defaultSearchRadius: CLLocationDistance = 8040.67 // 0.5 miles in meters
    let searchRadius: CLLocationDistance = defaultSearchRadius
    private static let onlyRestaurantsKey = "onlyRestaurants"
    private static let debugModeKey = "debugMode"

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.onlyRestaurants = userDefaults.object(forKey: Self.onlyRestaurantsKey) as? Bool ?? false
        self.debugMode = userDefaults.object(forKey: Self.debugModeKey) as? Bool ?? false
    }

    func searchNearbyPOIs(from coordinate: CLLocationCoordinate2D) async {
        guard !isSearching else { return }
        isSearching = true
        error = nil
        defer { isSearching = false }

        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )

        let request = MKLocalPointsOfInterestRequest(coordinateRegion: region)
        request.pointOfInterestFilter = pointOfInterestFilter

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            var pois = response.mapItems.compactMap { item -> POI? in
                guard let name = item.name,
                      let placemark = item.placemark.location else {
                    return nil
                }

                let distance = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    .distance(from: CLLocation(latitude: placemark.coordinate.latitude, longitude: placemark.coordinate.longitude))

                guard distance <= searchRadius else { return nil }

                // Format category for display
                let category = item.pointOfInterestCategory?.rawValue
                    .replacingOccurrences(of: "MKPOICategory", with: "")
                    .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)

                return POI(
                    name: name,
                    address: item.placemark.title ?? "Unknown",
                    coordinate: placemark.coordinate,
                    distance: distance,
                    category: category
                )
            }

            pois.sort { $0.distance < $1.distance }
            self.nearbyPOIs = pois
        } catch {
            self.error = error
            self.nearbyPOIs = []
        }
    }

    private var pointOfInterestFilter: MKPointOfInterestFilter {
        if onlyRestaurants {
            return MKPointOfInterestFilter(including: [.restaurant])
        }
        return .includingAll
    }
}
