import Foundation
import MapKit
import Combine

@MainActor
class POISearchManager: ObservableObject {
    @Published var nearbyPOIs: [POI] = []
    @Published var isSearching = false
    @Published var error: Error?

    private let searchRadius: CLLocationDistance = 8040.67 // 0.5 miles in meters

    func searchNearbyPOIs(from coordinate: CLLocationCoordinate2D) async {
        isSearching = true
        defer { isSearching = false }

        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )

        let request = MKLocalPointsOfInterestRequest(coordinateRegion: region)
        request.pointOfInterestFilter = .includingAll

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

                return POI(
                    name: name,
                    address: item.placemark.title ?? "Unknown",
                    coordinate: placemark.coordinate,
                    distance: distance
                )
            }

            pois.sort { $0.distance < $1.distance }
            self.nearbyPOIs = Array(pois.prefix(10))
        } catch {
            self.error = error
            self.nearbyPOIs = []
        }
    }
}
