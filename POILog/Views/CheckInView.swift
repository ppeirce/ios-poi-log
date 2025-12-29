import SwiftUI
import CoreLocation
import Combine
import MapKit
import UIKit

struct CheckInView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var searchManager: POISearchManager

    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var mapCenterCoordinate: CLLocationCoordinate2D?
    @State private var lastSearchLocation: CLLocation?

    private let minSearchDistance: CLLocationDistance = 45.7 // ~150 ft

    var body: some View {
        VStack(spacing: 0) {
            CurrentLocationMapView(
                currentLocation: locationManager.currentLocation,
                mapPosition: $mapPosition,
                mapCenterCoordinate: $mapCenterCoordinate,
                shouldRecenterOnLocationChange: !searchManager.debugMode
            )
                .frame(height: 280)

            if shouldShowDiagnostics {
                coordinateStatus
            }

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
        .onChange(of: mapCenterKey) { _, _ in
            guard let coordinate = mapCenterCoordinate else { return }
            handleMapCenterChange(coordinate)
        }
        .onChange(of: searchManager.selectedCategories) { _, _ in
            handleFilterChange()
        }
        .onChange(of: searchManager.debugMode) { _, _ in
            handleDebugModeChange()
        }
    }

    private var coordinateStatus: some View {
        VStack(alignment: .leading, spacing: 4) {
            if searchManager.debugMode {
                ForEach(Array(diagnosticLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .monospaced()
                }
            }

            if let error = locationManager.error {
                Text("Location Error: \(error.localizedDescription)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .contentShape(Rectangle())
        .onTapGesture {
            if searchManager.debugMode {
                copyDiagnosticsToPasteboard()
            }
        }
    }

    private func handleLocationUpdate(_ coordinate: CLLocationCoordinate2D) {
        guard let searchCoordinate = currentSearchCoordinate(fallback: coordinate) else { return }
        performSearchIfNeeded(from: searchCoordinate)
    }

    private func handleMapCenterChange(_ coordinate: CLLocationCoordinate2D) {
        guard searchManager.debugMode else { return }
        performSearchIfNeeded(from: coordinate)
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

    private func handleFilterChange() {
        guard let coordinate = currentSearchCoordinate(fallback: locationManager.currentLocation) else { return }
        lastSearchLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        Task { @MainActor in
            await searchManager.searchNearbyPOIs(from: coordinate)
        }
    }

    private var diagnosticLines: [String] {
        guard searchManager.debugMode else { return [] }
        var lines: [String] = []
        let poiCount = searchManager.nearbyPOIs.count
        lines.append("POIs found: \(poiCount)")
        lines.append(String(
            format: "Radius: %.2f mi | Categories: %@",
            searchRadiusMiles,
            categoriesLabel
        ))

        if let coordinate = mapCenterCoordinate {
            lines.append(String(
                format: "Search origin: map center (%.5f, %.5f)",
                coordinate.latitude,
                coordinate.longitude
            ))
        } else if let coordinate = locationManager.currentLocation {
            lines.append(String(
                format: "Search origin: location (%.5f, %.5f)",
                coordinate.latitude,
                coordinate.longitude
            ))
        } else {
            lines.append("Search origin: waiting")
            return lines
        }

        guard !searchManager.nearbyPOIs.isEmpty else {
            lines.append("Distribution: none")
            return lines
        }

        if let statsCoordinate = currentSearchCoordinate(fallback: locationManager.currentLocation) {
            let stats = poiStats(for: statsCoordinate, pois: searchManager.nearbyPOIs)
            lines.append("N/S/E/W: \(stats.north)/\(stats.south)/\(stats.east)/\(stats.west)")
            lines.append("NE/NW/SE/SW: \(stats.northEast)/\(stats.northWest)/\(stats.southEast)/\(stats.southWest)")
            lines.append(String(format: "Lat d: %+.4f..%+.4f", stats.minLatDelta, stats.maxLatDelta))
            lines.append(String(format: "Lon d: %+.4f..%+.4f", stats.minLonDelta, stats.maxLonDelta))
            lines.append(String(format: "Max dist: %.2f mi", stats.maxDistanceMiles))
        }

        return lines
    }

    private var searchRadiusMiles: Double {
        searchManager.searchRadius / 1609.34
    }

    private var categoriesLabel: String {
        let selections = searchManager.selectedCategories
        if selections.isEmpty {
            return "none"
        }
        if selections.count == POISearchManager.availableCategories.count {
            return "all"
        }

        let names = selections.map(\.displayName).sorted()
        if names.count <= 3 {
            return names.joined(separator: ", ")
        }
        let prefix = names.prefix(2).joined(separator: ", ")
        return "\(prefix) +\(names.count - 2)"
    }

    private var shouldShowDiagnostics: Bool {
        searchManager.debugMode || locationManager.error != nil
    }

    private var mapCenterKey: String? {
        guard let mapCenterCoordinate else { return nil }
        return String(format: "%.5f,%.5f", mapCenterCoordinate.latitude, mapCenterCoordinate.longitude)
    }

    private struct POIStats {
        let north: Int
        let south: Int
        let east: Int
        let west: Int
        let northEast: Int
        let northWest: Int
        let southEast: Int
        let southWest: Int
        let minLatDelta: Double
        let maxLatDelta: Double
        let minLonDelta: Double
        let maxLonDelta: Double
        let maxDistanceMiles: Double
    }

    private func poiStats(for coordinate: CLLocationCoordinate2D, pois: [POI]) -> POIStats {
        var north = 0
        var south = 0
        var east = 0
        var west = 0
        var northEast = 0
        var northWest = 0
        var southEast = 0
        var southWest = 0

        var minLatDelta = Double.greatestFiniteMagnitude
        var maxLatDelta = -Double.greatestFiniteMagnitude
        var minLonDelta = Double.greatestFiniteMagnitude
        var maxLonDelta = -Double.greatestFiniteMagnitude
        var maxDistanceMeters: Double = 0

        for poi in pois {
            let latDelta = poi.coordinate.latitude - coordinate.latitude
            let lonDelta = poi.coordinate.longitude - coordinate.longitude

            minLatDelta = min(minLatDelta, latDelta)
            maxLatDelta = max(maxLatDelta, latDelta)
            minLonDelta = min(minLonDelta, lonDelta)
            maxLonDelta = max(maxLonDelta, lonDelta)

            if latDelta >= 0 {
                north += 1
            } else {
                south += 1
            }

            if lonDelta >= 0 {
                east += 1
            } else {
                west += 1
            }

            switch (latDelta >= 0, lonDelta >= 0) {
            case (true, true):
                northEast += 1
            case (true, false):
                northWest += 1
            case (false, true):
                southEast += 1
            case (false, false):
                southWest += 1
            }

            maxDistanceMeters = max(maxDistanceMeters, poi.distance)
        }

        return POIStats(
            north: north,
            south: south,
            east: east,
            west: west,
            northEast: northEast,
            northWest: northWest,
            southEast: southEast,
            southWest: southWest,
            minLatDelta: minLatDelta,
            maxLatDelta: maxLatDelta,
            minLonDelta: minLonDelta,
            maxLonDelta: maxLonDelta,
            maxDistanceMiles: maxDistanceMeters / 1609.34
        )
    }

    private func copyDiagnosticsToPasteboard() {
        UIPasteboard.general.string = diagnosticLines.joined(separator: "\n")
    }

    private func currentSearchCoordinate(fallback: CLLocationCoordinate2D?) -> CLLocationCoordinate2D? {
        if searchManager.debugMode, let mapCenterCoordinate {
            return mapCenterCoordinate
        }
        return fallback ?? locationManager.currentLocation
    }

    private func handleDebugModeChange() {
        guard let coordinate = currentSearchCoordinate(fallback: locationManager.currentLocation) else { return }
        performSearchIfNeeded(from: coordinate)
    }

    private func performSearchIfNeeded(from coordinate: CLLocationCoordinate2D) {
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
}

#Preview {
    CheckInView(locationManager: LocationManager(), searchManager: POISearchManager())
}
