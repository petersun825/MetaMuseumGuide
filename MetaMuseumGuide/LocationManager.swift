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
    
    @Published var currentMuseum: Museum? = nil
    @Published var recommendations: [Exhibit] = []
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastKnownLocation: CLLocation?
    
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
        self.lastKnownLocation = location
        checkMuseum(at: location)
    }
    
    private func checkMuseum(at location: CLLocation) {
        // Simple distance check (e.g., within 500 meters)
        for (_, museum) in MuseumData.museums {
            let museumLocation = CLLocation(latitude: museum.latitude, longitude: museum.longitude)
            if location.distance(from: museumLocation) < 500 {
                DispatchQueue.main.async {
                    if self.currentMuseum?.name != museum.name {
                        self.currentMuseum = museum
                        // Recommendations will be updated by the view or a separate method observing preferences
                    }
                }
                return
            }
        }
        // If no match found
        DispatchQueue.main.async {
            self.currentMuseum = nil
            self.recommendations = []
        }
    }
    
    func updateRecommendations(for preferences: UserPreferences) {
        guard let museum = currentMuseum else {
            recommendations = []
            return
        }
        
        if preferences.interests.isEmpty {
            // If no preferences, show all or top exhibits
            recommendations = museum.exhibits
        } else {
            // Filter exhibits that match at least one interest tag
            recommendations = museum.exhibits.filter { exhibit in
                !exhibit.tags.isDisjoint(with: preferences.interests)
            }
            // If no matches, fallback to showing all
            if recommendations.isEmpty {
                recommendations = museum.exhibits
            }
        }
    }
    
    // Debug method to simulate location
    func simulateLocation(museumName: String) {
        if let museum = MuseumData.museums[museumName] {
            self.currentMuseum = museum
        }
    }
}
