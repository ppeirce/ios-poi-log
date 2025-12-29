import SwiftUI
import MapKit

struct CurrentLocationMapView: View {
    let currentLocation: CLLocationCoordinate2D?

    @Binding var mapPosition: MapCameraPosition
    @Binding var mapCenterCoordinate: CLLocationCoordinate2D?
    var shouldRecenterOnLocationChange: Bool = true

    @State private var hasSetInitialPosition = false

    init(
        currentLocation: CLLocationCoordinate2D?,
        mapPosition: Binding<MapCameraPosition>,
        mapCenterCoordinate: Binding<CLLocationCoordinate2D?>,
        shouldRecenterOnLocationChange: Bool = true
    ) {
        self.currentLocation = currentLocation
        _mapPosition = mapPosition
        _mapCenterCoordinate = mapCenterCoordinate
        self.shouldRecenterOnLocationChange = shouldRecenterOnLocationChange
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
        .onAppear {
            guard let location = currentLocation, !hasSetInitialPosition else { return }
            mapPosition = CurrentLocationMapView.regionPosition(for: location)
            mapCenterCoordinate = location
            hasSetInitialPosition = true
        }
        .onChange(of: locationKey) { _, _ in
            guard let location = currentLocation else { return }
            if shouldRecenterOnLocationChange {
                withAnimation {
                    mapPosition = CurrentLocationMapView.regionPosition(for: location)
                }
                mapCenterCoordinate = location
                hasSetInitialPosition = true
            } else if !hasSetInitialPosition {
                mapPosition = CurrentLocationMapView.regionPosition(for: location)
                mapCenterCoordinate = location
                hasSetInitialPosition = true
            }
        }
        .onMapCameraChange { context in
            mapCenterCoordinate = context.region.center
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
    CurrentLocationMapView(
        currentLocation: CLLocationCoordinate2D(latitude: 37.8012, longitude: -122.2727),
        mapPosition: .constant(.automatic),
        mapCenterCoordinate: .constant(nil)
    )
}
