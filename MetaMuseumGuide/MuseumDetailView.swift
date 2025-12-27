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
            List {
                Section {
                    Text(museum.name)
                        .font(.title)
                        .bold()
                }
                
                Section(header: Text("Exhibits")) {
                    ForEach(museum.exhibits) { exhibit in
                        VStack(alignment: .leading) {
                            Text(exhibit.name)
                                .font(.headline)
                            Text(exhibit.locationInMuseum)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    if let url = websiteURL {
                        Link("Visit Website", destination: url)
                            .foregroundColor(.blue)
                    }
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

