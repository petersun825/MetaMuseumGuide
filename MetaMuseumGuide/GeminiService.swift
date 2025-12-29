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
    private let model = "gemini-3-flash-preview"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Podcast Script Generation (Moved to top/init for visibility)
    func createVisitSummary(artworks: [ArtPiece], preferences: UserPreferences, completion: @escaping (Result<String, Error>) -> Void) {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "GeminiService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let artList = artworks.map { "\($0.title) by \($0.artist)" }.joined(separator: ", ")
        let interests = preferences.interests.joined(separator: ", ")
        
        // Using concatenated strings to avoid copy-paste whitespace issues
        var prompt = "You are a charismatic, knowledgeable art podcast host. You are wrapping up a special episode about the user's visit to the museum.\n\n"
        prompt += "The listener just saw these pieces: \(artList).\n"
        prompt += "The listener is interested in: \(interests).\n\n"
        prompt += "Write a short, engaging 1-minute podcast script (approx 130-150 words) summarizing their visit.\n"
        prompt += "- Be enthusiastic and personal.\n"
        prompt += "- Mention 2-3 specific pieces they saw and why they are cool, relating them to their interests if possible.\n"
        prompt += "- End with a thought-provoking sign-off.\n"
        prompt += "- Do NOT include sound effects cues like [Intro Music]. Just the spoken text."
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("GeminiService: Generating podcast script...")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "GeminiService", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let content = candidates.first?["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String {
                    
                    print("GeminiService: Script generated successfully.")
                    completion(.success(text))
                } else {
                    completion(.failure(NSError(domain: "GeminiService", code: -6, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    // MARK: - Chat (Q&A)
    func chatAboutArt(history: [String], question: String, context: String, completion: @escaping (Result<String, Error>) -> Void) {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "GeminiService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let prompt = """
        You are an expert art historian guide in a museum app.
        
        Context about the artwork currently being viewed:
        \(context)
        
        The user asks: "\(question)"
        
        Answer the user's question concisely (2-3 sentences max) and conversationally.
        If the question is unrelated to art, politely steer them back to the artwork.
        """
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "GeminiService", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let content = candidates.first?["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String {
                    completion(.success(text))
                } else {
                    completion(.failure(NSError(domain: "GeminiService", code: -6, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Vision (Identify Art)
    func identifyArt(image: UIImage, language: String, completion: @escaping (Result<ArtPiece, Error>) -> Void) {
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
        Analyze this image. If it is an artwork, identify the Title, Artist, Year, and provide a Description and Context in \(language).
        If it is a general object, identify it and provide context in \(language).
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
