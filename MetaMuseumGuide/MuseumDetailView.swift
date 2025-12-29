//
//  MuseumDetailView.swift
//  MuseumMuse
//
//  Created by Peter Sun on 12/27/25.
//
import SwiftUI

struct MuseumDetailView: View {
    let museum: Museum
    @Environment(\.presentationMode) var presentationMode
    
    var websiteURL: URL? {
        // Simple mapping for demo. In a real app, this should be in Museum struct.
        switch museum.name {
        case "Harvard Art Museums": return URL(string: "https://harvardartmuseums.org")
        case "The Metropolitan Museum of Art": return URL(string: "https://www.metmuseum.org")
        case "Museum of Modern Art": return URL(string: "https://www.moma.org")
        case "Louvre Museum": return URL(string: "https://www.louvre.fr/en")
        default: return URL(string: "https://www.google.com/search?q=\(museum.name)")
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title Card
                        VStack(alignment: .leading) {
                            Text(museum.name)
                                .font(.largeTitle)
                                .bold()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Exhibits
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Exhibits")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ForEach(museum.exhibits) { exhibit in
                                VStack(alignment: .leading) {
                                    Text(exhibit.name)
                                        .font(.headline)
                                    Text(exhibit.locationInMuseum)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(exhibit.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                        
                        // Website Link
                        if let url = websiteURL {
                            Link(destination: url) {
                                HStack {
                                    Image(systemName: "safari")
                                    Text("Visit Website")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Museum Info")
            .toolbar {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
