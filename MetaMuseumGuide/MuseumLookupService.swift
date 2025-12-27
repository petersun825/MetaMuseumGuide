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
    
    // Coding keys to match API response if needed, or stick to simple names if they match
    // The API returns 'id' as 'id', 'title' as 'title', etc.
    // Ensure optionality as API might omit fields.
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
