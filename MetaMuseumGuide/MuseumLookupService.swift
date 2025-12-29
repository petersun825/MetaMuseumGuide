//
//  MuseumLookupServices.swift
//  MuseumMuse
//
//  Created by Peter Sun on 12/26/25.
//
import Foundation

struct ArtObject: Codable, Identifiable {
    let id: Int
    let title: String
    let dated: String?
    let medium: String?
    let culture: String?
    let provenance: String?
    let commentary: String?
    let description: String?
    let primaryimageurl: String?
    let url: String?
    let classification: String?
    let technique: String?
    let department: String?
    
    // Rich Data Arrays
    let images: [ImageResource]?
    let people: [Person]?
    let audio: [AudioResource]? // Might verify API name is "audio" or "audios"
    
    struct ImageResource: Codable, Identifiable {
        let imageid: Int
        let baseimageurl: String?
        let idsid: Int?
        let caption: String?
        
        var id: Int { imageid }
    }
    
    struct Person: Codable, Identifiable {
        let personid: Int
        let displayname: String?
        let role: String?
        
        var id: Int { personid }
    }
    
    struct AudioResource: Codable, Identifiable {
        // Based on docs and assumption, verify exact keys if possible
        let audioid: Int? // API often uses integer IDs
        let duration: Double?
        let primaryurl: String?
        let description: String?
        
        var id: Int { audioid ?? Int.random(in: 0...10000) }
    }
}

// Wrapper for API response structure
struct HarvardAPIResponse: Codable {
    let info: Info
    let records: [ArtObject]
    
    struct Info: Codable {
        let totalrecords: Int
    }
}

class MuseumLookupService {
    private let apiKey: String
    private let baseURL = "https://api.harvardartmuseums.org/object"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func fetchArtDetails(query: String) async throws -> ArtObject? {
        // Construct URL
        // We search by title for now as a naive implementation of "lookup"
        // In a real app, we might use image recognition ID or more complex queries
        guard var components = URLComponents(string: baseURL) else { return nil }
        
        components.queryItems = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "title", value: query),
            URLQueryItem(name: "size", value: "1") // We only want the best match
        ]
        
        guard let url = components.url else { return nil }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(HarvardAPIResponse.self, from: data)
        
        return apiResponse.records.first
    }
}

extension ArtObject {
    var voiceReadyDescription: String {
        // combine description, commentary, provenance
        var text = ""
        
        if let desc = description {
            text += desc + " "
        }
        if let comm = commentary {
            text += comm + " "
        }
        if let prov = provenance {
            text += "Provenance: " + prov
        }
        
        if text.isEmpty {
            return "No additional details available."
        }
        
        return text.cleanHTML()
    }
}

extension String {
    func cleanHTML() -> String {
        // Simple regex to remove tags
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "&[^;]+;", with: " ", options: .regularExpression, range: nil) // basic entity removal
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
