import SwiftUI
import MapKit

struct CurrentLocationMapView: View {
    let currentLocation: CLLocationCoordinate2D?

    @State private var mapPosition: MapCameraPosition

    init(currentLocation: CLLocationCoordinate2D?) {
        self.currentLocation = currentLocation
        if let location = currentLocation {
            _mapPosition = State(initialValue: CurrentLocationMapView.regionPosition(for: location))
        } else {
            _mapPosition = State(initialValue: .automatic)
        }
    }

    var body: some View {
        Map(position: $mapPosition) {
            if currentLocation != nil {
                UserAnnotation()
            }
        }
        .mapControls {
            MapUserLocationButton()
        }
        .onChange(of: locationKey) { _, _ in
            guard let location = currentLocation else { return }
            withAnimation {
                mapPosition = CurrentLocationMapView.regionPosition(for: location)
            }
        }
    }

    private var locationKey: String? {
        guard let location = currentLocation else { return nil }
        return "\(location.latitude),\(location.longitude)"
    }

    private static func regionPosition(for location: CLLocationCoordinate2D) -> MapCameraPosition {
        .region(
            MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
    }
}

#Preview {
    CurrentLocationMapView(currentLocation: CLLocationCoordinate2D(latitude: 37.8012, longitude: -122.2727))
}
