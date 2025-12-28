import SwiftUI
import CoreLocation
import Combine

struct CheckInView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var searchManager: POISearchManager

    @State private var lastSearchLocation: CLLocation?

    private let minSearchDistance: CLLocationDistance = 45.7 // ~150 ft

    var body: some View {
        VStack(spacing: 0) {
            CurrentLocationMapView(currentLocation: locationManager.currentLocation)
                .frame(height: 280)

            coordinateStatus

            Divider()

            if locationManager.currentLocation == nil {
                VStack {
                    ProgressView("Getting your location...")
                        .padding(.top, 24)
                    Spacer()
                }
            } else if searchManager.isSearching {
                VStack {
                    ProgressView("Finding nearby places...")
                        .padding(.top, 24)
                    Spacer()
                }
            } else {
                EmbeddedPOIListView(
                    pois: searchManager.nearbyPOIs,
                    currentLocation: locationManager.currentLocation,
                    searchRadius: searchManager.searchRadius,
                    onRefresh: handleRefresh
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(locationManager.$currentLocation.compactMap { $0 }) { coordinate in
            handleLocationUpdate(coordinate)
        }
    }

    private var coordinateStatus: some View {
        VStack(spacing: 6) {
            if let coordinate = locationManager.currentLocation {
                Text(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .monospaced()
            } else {
                Text("Getting your location...")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            if let error = locationManager.error {
                Text("Location Error: \(error.localizedDescription)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    private func handleLocationUpdate(_ coordinate: CLLocationCoordinate2D) {
        if searchManager.isSearching { return }

        let newLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if let lastLocation = lastSearchLocation, newLocation.distance(from: lastLocation) < minSearchDistance {
            return
        }

        lastSearchLocation = newLocation
        Task { @MainActor in
            await searchManager.searchNearbyPOIs(from: coordinate)
        }
    }

    @MainActor
    private func handleRefresh() async {
        locationManager.requestLocation()

        let start = Date()
        while !searchManager.isSearching && Date().timeIntervalSince(start) < 1.5 {
            try? await Task.sleep(for: .milliseconds(100))
        }

        let finishStart = Date()
        while searchManager.isSearching && Date().timeIntervalSince(finishStart) < 10 {
            try? await Task.sleep(for: .milliseconds(100))
        }
    }
}

#Preview {
    CheckInView(locationManager: LocationManager(), searchManager: POISearchManager())
}
