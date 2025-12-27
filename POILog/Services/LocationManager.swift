import Foundation
import CoreLocation
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: Error?

    private let locationManager = CLLocationManager()
    private var hasRequestedLocation = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }

    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            DispatchQueue.main.async { [weak self] in
                self?.currentLocation = location.coordinate
                self?.error = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Ignore transient location unknown errors (code 0) - these happen during startup
        if let clError = error as? CLError, clError.code == .locationUnknown {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.error = error
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async { [weak self] in
            self?.authorizationStatus = status
            if (status == .authorizedWhenInUse || status == .authorizedAlways) && !(self?.hasRequestedLocation ?? false) {
                self?.hasRequestedLocation = true
                self?.locationManager.requestLocation()
            }
        }
    }
}
