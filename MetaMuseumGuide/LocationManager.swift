//
//  LocationManager.swift
//  MetaMuseumGuide
//
//  Created by Peter Sun on 12/5/25.
//
import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var currentMuseum: String? = nil
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // Hardcoded list of museums for demo
    private let museums: [String: (lat: Double, long: Double)] = [
        "The Met": (40.7794, -73.9632),
        "MoMA": (40.7614, -73.9776),
        "Louvre": (48.8606, 2.3376),
        "British Museum": (51.5194, -0.1270),
        "Museum of Fine Art Boston": (42.3588, -71.0561)
    ]
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        checkMuseum(at: location)
    }
    
    private func checkMuseum(at location: CLLocation) {
        // Simple distance check (e.g., within 500 meters)
        for (name, coords) in museums {
            let museumLocation = CLLocation(latitude: coords.lat, longitude: coords.long)
            if location.distance(from: museumLocation) < 500 {
                DispatchQueue.main.async {
                    self.currentMuseum = name
                }
                return
            }
        }
        // If no match found
        DispatchQueue.main.async {
            self.currentMuseum = nil
        }
    }
}

