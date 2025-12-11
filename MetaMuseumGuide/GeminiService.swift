//
//  GeminiService.swift
//  MuseumMuse
//
//  Created by Peter Sun on 12/7/25.
//
import Foundation
import UIKit

class GeminiService {
    private let apiKey: String
    private let session = URLSession.shared
    
    // Gemini 1.5 Flash is fast and multimodal
    private let model = "gemini-flash-latest"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Vision (Identify Art)
    func identifyArt(image: UIImage, completion: @escaping (Result<ArtPiece, Error>) -> Void) {
        guard let base64Image = image.jpegData(compressionQuality: 0.5)?.base64EncodedString() else {
            completion(.failure(NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])))
            return
        }
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "GeminiService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        Analyze this image. If it is an artwork, identify the Title, Artist, Year, and provide a Description and Context.
        If it is a general object, identify it and provide context.
        Return the result as a valid JSON object with the following keys:
        "title", "artist", "year", "description", "context".
        Do not include markdown formatting like ```json. Just the raw JSON.
        """
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "response_mime_type": "application/json"
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("GeminiService: Sending request to Gemini API...")
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("GeminiService: Network Error - \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("GeminiService: HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("GeminiService: No data received")
                completion(.failure(NSError(domain: "GeminiService", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Debug: Print raw JSON
            if let rawString = String(data: data, encoding: .utf8) {
                print("GeminiService: Raw Response: \(rawString)")
            }
            
            do {
                // Parse Gemini Response
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    // Check for error
                    if let errorObj = json["error"] as? [String: Any],
                       let errorMessage = errorObj["message"] as? String {
                        print("GeminiService: API Error - \(errorMessage)")
                        completion(.failure(NSError(domain: "GeminiService", code: -5, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                        return
                    }
                    
                    if let candidates = json["candidates"] as? [[String: Any]],
                       let firstCandidate = candidates.first,
                       let content = firstCandidate["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let firstPart = parts.first,
                       let text = firstPart["text"] as? String {
                        
                        print("GeminiService: Content received: \(text)")
                        
                        // Clean the content string
                        let cleanContent = text.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if let contentData = cleanContent.data(using: .utf8),
                           let artInfo = try JSONSerialization.jsonObject(with: contentData) as? [String: String] {
                            
                            let artPiece = ArtPiece(
                                title: artInfo["title"] ?? "Unknown",
                                artist: artInfo["artist"] ?? "Unknown",
                                year: artInfo["year"] ?? "Unknown",
                                description: artInfo["description"] ?? "No description available.",
                                context: artInfo["context"] ?? "No context available."
                            )
                            completion(.success(artPiece))
                        } else {
                            print("GeminiService: JSON Parsing Error - Could not parse content string")
                            completion(.failure(NSError(domain: "GeminiService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse content JSON"])))
                        }
                    } else {
                        print("GeminiService: Invalid API Response Structure")
                        completion(.failure(NSError(domain: "GeminiService", code: -6, userInfo: [NSLocalizedDescriptionKey: "Invalid API response"])))
                    }
                }
            } catch {
                print("GeminiService: JSON Serialization Error - \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
