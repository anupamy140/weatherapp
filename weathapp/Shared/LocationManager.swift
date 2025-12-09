import Foundation
import CoreLocation
import Combine

/// Handles asking for location and turning it into a city name.
final class LocationManager: NSObject, ObservableObject {

    /// The resolved city name (e.g. "Kanpur").
    @Published var currentCityName: String?

    /// Error message to show in alerts.
    @Published var lastErrorMessage: String?

    /// True while we are actively requesting location / geocoding.
    @Published var isRequestingLocation: Bool = false

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    /// Called when you tap the "Use my location" button.
    func requestCurrentCity() {
            lastErrorMessage = nil
            
            // 🚀 NEW: Reset the city name so .onChange will fire again even if the city is the same
            currentCityName = nil

            let status = manager.authorizationStatus
            print("📍 Location auth status: \(status.rawValue)")

            switch status {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()

            case .restricted, .denied:
                lastErrorMessage = "Location permission is denied. Please enable it in Settings."

            case .authorizedWhenInUse, .authorizedAlways:
                isRequestingLocation = true
                manager.requestLocation()

            @unknown default:
                lastErrorMessage = "Unknown location authorization status."
            }
        }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("📍 Authorization changed: \(status.rawValue)")

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            // Now we can actually ask for the location
            isRequestingLocation = true
            manager.requestLocation()
        }
    }


    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("📍 didUpdateLocations: \(locations)")

        guard let location = locations.last else {
            isRequestingLocation = false
            lastErrorMessage = "Couldn't get your location."
            return
        }

        // Reverse geocode -> city name
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isRequestingLocation = false

                if let error = error {
                    print("❌ Reverse geocode error:", error)
                    self.lastErrorMessage = "Could not find a city for your location."
                    return
                }

                guard let placemark = placemarks?.first else {
                    self.lastErrorMessage = "Could not find a city for your location."
                    return
                }

                let city = placemark.locality ??
                           placemark.subLocality ??
                           placemark.name

                if let city, !city.isEmpty {
                    print("✅ Resolved current city:", city)
                    self.currentCityName = city
                } else {
                    self.lastErrorMessage = "Could not determine your city name."
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isRequestingLocation = false
            self.lastErrorMessage = "Location error: \(error.localizedDescription)"
            print("❌ Location error:", error)
        }
    }
}
