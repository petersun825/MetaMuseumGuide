//
//  MetaMuseumGuideApp.swift
//  MetaMuseumGuide
//
//  Created by Peter Sun on 12/5/25.
//

import SwiftUI
// import MWDATCore // Uncomment when SDK is added

@main
struct MetaMuseumGuideApp: App {
    // Initialize services
    @StateObject private var glassesManager = GlassesManager()
    @StateObject private var locationManager = LocationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(glassesManager)
                .environmentObject(locationManager)
                .onAppear {
                    // Configure Meta Wearables SDK
                    // try? Wearables.configure()
                    print("Meta Wearables SDK Configuration placeholder")
                }
        }
    }
}
