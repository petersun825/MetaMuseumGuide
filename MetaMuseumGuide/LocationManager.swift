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
    
    @Published var sessionArtworks: [ArtPiece] = []
    @Published var isVisiting = false
    
    // Notification Name
    static let museumExitNotification = Notification.Name("MuseumExitDetected")
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true // Ensure background updates if plist allows
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func requestPermission() {
        locationManager.requestAlwaysAuthorization() // Request Always for exit detection
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
    
    func addArtToSession(_ art: ArtPiece) {
        if isVisiting {
            sessionArtworks.append(art)
        }
    }
    
    private func checkMuseum(at location: CLLocation) {
        // Simple distance check (e.g., within 500 meters)
        var foundMuseum: Museum? = nil
        
        for (_, museum) in MuseumData.museums {
            let museumLocation = CLLocation(latitude: museum.latitude, longitude: museum.longitude)
            if location.distance(from: museumLocation) < 500 {
                foundMuseum = museum
                break
            }
        }
        
        DispatchQueue.main.async {
            if let museum = foundMuseum {
                // Enterprise: Did we just enter?
                if self.currentMuseum?.name != museum.name {
                    self.currentMuseum = museum
                    self.isVisiting = true
                    self.sessionArtworks = [] // Reset session on new entry
                    print("LocationManager: Entered \(museum.name)")
                }
            } else {
                // Enterprise: Did we just exit?
                if self.currentMuseum != nil && self.isVisiting {
                    print("LocationManager: Exited Museum. Art collected: \(self.sessionArtworks.count)")
                    self.isVisiting = false
                    
                    if !self.sessionArtworks.isEmpty {
                        NotificationCenter.default.post(name: LocationManager.museumExitNotification, object: nil, userInfo: ["art": self.sessionArtworks])
                    }
                    self.currentMuseum = nil
                    self.recommendations = []
                }
            }
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
            self.isVisiting = true
            self.sessionArtworks = []
        }
    }
    
    func simulateExit() {
        guard isVisiting else {
            print("Cannot simulate exit: Not currently visiting")
            return
        }
        print("Simulating Exit...")
        // Force the check logic to see "no museum"
        DispatchQueue.main.async {
            print("LocationManager: Exited Museum (Simulated). Art collected: \(self.sessionArtworks.count)")
            self.isVisiting = false
            
            if !self.sessionArtworks.isEmpty {
                NotificationCenter.default.post(name: LocationManager.museumExitNotification, object: nil, userInfo: ["art": self.sessionArtworks])
            }
            self.currentMuseum = nil
            self.recommendations = []
        }
    }
}
