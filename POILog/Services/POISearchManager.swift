import Foundation
import MapKit
import Combine

@MainActor
class POISearchManager: ObservableObject {
    @Published var nearbyPOIs: [POI] = []
    @Published var isSearching = false
    @Published var error: Error?
    @Published var selectedCategories: Set<MKPointOfInterestCategory> {
        didSet {
            userDefaults.set(selectedCategories.map(\.rawValue), forKey: Self.selectedCategoriesKey)
        }
    }
    @Published var debugMode: Bool {
        didSet {
            userDefaults.set(debugMode, forKey: Self.debugModeKey)
        }
    }

    static let defaultSearchRadius: CLLocationDistance = 8040.67 // 0.5 miles in meters
    let searchRadius: CLLocationDistance = defaultSearchRadius
    private static let selectedCategoriesKey = "selectedCategories"
    private static let debugModeKey = "debugMode"

    private let userDefaults: UserDefaults
    static let defaultCategories: Set<MKPointOfInterestCategory> = [.restaurant, .nightlife]
    static var availableCategories: [MKPointOfInterestCategory] {
        var categories: [MKPointOfInterestCategory] = [
            .airport,
            .amusementPark,
            .aquarium,
            .bakery,
            .bank,
            .beach,
            .brewery,
            .cafe,
            .campground,
            .carRental,
            .fireStation,
            .fitnessCenter,
            .foodMarket,
            .gasStation,
            .hospital,
            .hotel,
            .laundry,
            .library,
            .marina,
            .movieTheater,
            .museum,
            .nationalPark,
            .nightlife,
            .park,
            .pharmacy,
            .police,
            .postOffice,
            .publicTransport,
            .restaurant,
            .restroom,
            .school,
            .stadium,
            .store,
            .theater,
            .university,
            .winery,
            .zoo
        ]

        if #available(iOS 18.0, *) {
            categories.append(contentsOf: [
                .automotiveRepair,
                .baseball,
                .basketball,
                .beauty,
                .bowling,
                .castle,
                .conventionCenter,
                .distillery,
                .fairground,
                .fishing,
                .fortress,
                .golf,
                .goKart,
                .hiking,
                .landmark,
                .miniGolf,
                .musicVenue,
                .nationalMonument,
                .planetarium,
                .rockClimbing,
                .rvPark,
                .skatePark,
                .skating,
                .skiing,
                .soccer,
                .surfing,
                .swimming,
                .tennis,
                .volleyball
            ])
        }

        return categories
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let stored = userDefaults.array(forKey: Self.selectedCategoriesKey) as? [String] {
            let mapped = stored.map { MKPointOfInterestCategory(rawValue: $0) }
            let availableSet = Set(Self.availableCategories)
            self.selectedCategories = Set(mapped).intersection(availableSet)
        } else {
            self.selectedCategories = Self.defaultCategories
        }
        self.debugMode = userDefaults.object(forKey: Self.debugModeKey) as? Bool ?? false
    }

    func searchNearbyPOIs(from coordinate: CLLocationCoordinate2D) async {
        guard !isSearching else { return }
        if selectedCategories.isEmpty {
            nearbyPOIs = []
            return
        }
        isSearching = true
        error = nil
        defer { isSearching = false }

        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )

        let request = MKLocalPointsOfInterestRequest(coordinateRegion: region)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: Array(selectedCategories))

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
                let category = item.pointOfInterestCategory?.displayName

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

}

extension MKPointOfInterestCategory {
    var displayName: String {
        if self == .nightlife {
            return "Nightlife (Bars)"
        }

        return rawValue
            .replacingOccurrences(of: "MKPOICategory", with: "")
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
    }
}
