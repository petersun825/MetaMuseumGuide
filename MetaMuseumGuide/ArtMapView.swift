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
    
    struct MapItem: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let art: ArtPiece?
        let museum: Museum?
    }
    
    var mapItems: [MapItem] {
        var items: [MapItem] = []
        // Add History
        items.append(contentsOf: historyManager.history.compactMap { art in
            guard let lat = art.latitude, let lon = art.longitude else { return nil }
            return MapItem(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), art: art, museum: nil)
        })
        // Add Museums
        items.append(contentsOf: MuseumData.museums.values.map { museum in
            MapItem(coordinate: CLLocationCoordinate2D(latitude: museum.latitude, longitude: museum.longitude), art: nil, museum: museum)
        })
        return items
    }
    
    @State private var selectedMuseum: Museum?
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: mapItems) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    if let art = item.art {
                        NavigationLink(destination: HistoryDetailView(art: art, language: "English")) {
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
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(4)
                            }
                        }
                    } else if let museum = item.museum {
                        Button(action: {
                            selectedMuseum = museum
                        }) {
                            VStack {
                                Image(systemName: "building.columns.circle.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.red)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                                
                                Text(museum.name)
                                    .font(.caption)
                                    .padding(4)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            .sheet(item: $selectedMuseum) { museum in
                MuseumDetailView(museum: museum)
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
