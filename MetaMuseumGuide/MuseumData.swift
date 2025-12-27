//
//  MuseumData.swift
//  MuseumMuse
//
//  Created by Peter Sun on 12/6/25.
//

import Foundation

struct Exhibit: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let locationInMuseum: String
    let tags: Set<String>
}

struct Museum: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let exhibits: [Exhibit]
    
    static func == (lhs: Museum, rhs: Museum) -> Bool {
        return lhs.name == rhs.name
    }
}

struct MuseumData {
    static let museums: [String: Museum] = [
        "The Met": Museum(
            name: "The Metropolitan Museum of Art",
            latitude: 40.7794,
            longitude: -73.9632,
            exhibits: [
                Exhibit(name: "Temple of Dendur", description: "An ancient Egyptian temple built by Petronius.", locationInMuseum: "Sackler Wing", tags: ["History", "Sculpture", "Classical"]),
                Exhibit(name: "The Starry Night (Loan)", description: "Van Gogh's masterpiece (visiting exhibit).", locationInMuseum: "Gallery 821", tags: ["Modern Art", "Impressionism"]),
                Exhibit(name: "Greek and Roman Art", description: "Extensive collection of classical antiquity.", locationInMuseum: "First Floor", tags: ["Classical", "History", "Sculpture"])
            ]
        ),
        "MoMA": Museum(
            name: "Museum of Modern Art",
            latitude: 40.7614,
            longitude: -73.9776,
            exhibits: [
                Exhibit(name: "The Starry Night", description: "Van Gogh's most famous painting.", locationInMuseum: "Floor 5", tags: ["Modern Art", "Impressionism"]),
                Exhibit(name: "Persistence of Memory", description: "Dali's melting clocks.", locationInMuseum: "Floor 5", tags: ["Modern Art", "Surrealism"]),
                Exhibit(name: "Design Collection", description: "Modern industrial and graphic design.", locationInMuseum: "Floor 3", tags: ["Modern Art", "Technology"])
            ]
        ),
        "Louvre": Museum(
            name: "Louvre Museum",
            latitude: 48.8606,
            longitude: 2.3376,
            exhibits: [
                Exhibit(name: "Mona Lisa", description: "Da Vinci's masterpiece.", locationInMuseum: "Denon Wing", tags: ["Classical", "History"]),
                Exhibit(name: "Venus de Milo", description: "Ancient Greek statue.", locationInMuseum: "Sully Wing", tags: ["Classical", "Sculpture"])
            ]
        ),
        "Harvard Art Museums": Museum(
                   name: "Harvard Art Museums",
                   latitude: 42.3744,
                   longitude: -71.1182,
                   exhibits: [
                        Exhibit(name: "Pigment Collection", description: "Rare pigments from around the world.", locationInMuseum: "Level 4", tags: ["History", "Technology"]),
                        Exhibit(name: "Light and Color", description: "Impressionist studies.", locationInMuseum: "Level 2", tags: ["Impressionism", "Modern Art"])
                   ]
               )
    ]
}
