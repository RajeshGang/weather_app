//
//  LocationManager.swift
//  WeatherApp
//
//  Created by Rahul Rajesh on 9/7/25.
//
import CoreLocation
import Combine
import UIKit

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorization: CLAuthorizationStatus = .notDetermined
    @Published var isAuthorized: Bool = false
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var lastUpdated: Date?
    @Published var placename: String = ""

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        // seed current status
        authorization = manager.authorizationStatus
        isAuthorized = (authorization == .authorizedAlways || authorization == .authorizedWhenInUse)
    }

    func request() {
        // If we already have permission, ask for a fresh fix; else prompt.
        if isAuthorized {
            manager.requestLocation()
        } else {
            manager.requestWhenInUseAuthorization()
        }
    }

    func refresh() { manager.requestLocation() }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Delegate

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorization = status
            self.isAuthorized = (status == .authorizedAlways || status == .authorizedWhenInUse)
        }
        if isAuthorized {
            manager.requestLocation()         // kick off a fix right away
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        DispatchQueue.main.async {
            self.coordinate = loc.coordinate
            self.lastUpdated = Date()
        }
        geocode(loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
    }

    private func geocode(_ loc: CLLocation) {
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(loc) { [weak self] placemarks, _ in
            guard let self, let p = placemarks?.first else { return }
            let city = p.locality ?? p.subAdministrativeArea ?? ""
            let admin = p.administrativeArea ?? ""
            let parts = [city, admin].filter { !$0.isEmpty }
            DispatchQueue.main.async { self.placename = parts.joined(separator: ", ") }
        }
    }
}

