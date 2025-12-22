//
//  ArtMapView.swift
//  MuseumMuse
//
//  Created by Peter Sun on 12/21/25.
//
import SwiftUI
import MapKit

struct ArtMapView: View {
    @ObservedObject var historyManager: HistoryManager
    @ObservedObject var locationManager: LocationManager
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), // Default to NYC
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: historyManager.history.filter { $0.latitude != nil && $0.longitude != nil }) { art in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: art.latitude!, longitude: art.longitude!)) {
                    NavigationLink(destination: HistoryDetailView(art: art)) {
                        VStack {
                            if let data = art.imageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .shadow(radius: 3)
                            } else {
                                Image(systemName: "photo.circle.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.purple)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            
                            Text(art.title)
                                .font(.caption)
                                .padding(4)
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // Locate Me Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        if let location = locationManager.lastKnownLocation {
                            withAnimation {
                                region.center = location.coordinate
                                region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            }
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            // Center map on the most recent item if available, otherwise user location
            if let lastArt = historyManager.history.last, let lat = lastArt.latitude, let lon = lastArt.longitude {
                region.center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            } else if let userLoc = locationManager.lastKnownLocation {
                region.center = userLoc.coordinate
            }
        }
        .navigationTitle("Art Map")
    }
}
