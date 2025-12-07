//
//  OpenAIService.swift
//  MuseumMuse
//
//  Created by Peter Sun on 12/6/25.
//
import Foundation
import UIKit

class OpenAIService {
    private let apiKey: String
    private let session = URLSession.shared
    
    // Configurable model name
    private let visionModel = "gpt-5-nano" // User requested gpt-5-nano, defaulting to 4o for now
    private let ttsModel = "tts-1"
    private let ttsVoice = "alloy"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Vision (Identify Art)
    func identifyArt(image: UIImage, completion: @escaping (Result<ArtPiece, Error>) -> Void) {
        guard let base64Image = image.jpegData(compressionQuality: 0.5)?.base64EncodedString() else {
            completion(.failure(NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])))
            return
        }
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        Analyze this image. If it is an artwork, identify the Title, Artist, Year, and provide a Description and Context.
        If it is a general object, identify it and provide context.
        Return the result as a valid JSON object with the following keys:
        "title", "artist", "year", "description", "context".
        Do not include markdown formatting like ```json. Just the raw JSON.
        """
        
        // Multimodal chat format: content is an array of parts (text + image_url)
        let body: [String: Any] = [
            "model": visionModel,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 500,
            "response_format": [
                "type": "json_object"
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("OpenAIService: Sending request to \(url.absoluteString)")
        
        let task = session.dataTask(with: request) { data, response, error in
            // Network error
            if let error = error {
                print("OpenAIService: Network Error - \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Status code
            if let httpResponse = response as? HTTPURLResponse {
                print("OpenAIService: HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            // No data
            guard let data = data else {
                print("OpenAIService: No data received")
                completion(.failure(
                    NSError(
                        domain: "OpenAIService",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "No data received"]
                    )
                ))
                return
            }
            
            // Debug: raw response
            if let rawString = String(data: data, encoding: .utf8) {
                print("OpenAIService: Raw Response: \(rawString)")
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("OpenAIService: Failed to parse response as JSON")
                    completion(.failure(
                        NSError(
                            domain: "OpenAIService",
                            code: -6,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to parse response as JSON"]
                        )
                    ))
                    return
                }
                
                // Check for API error object
                if let errorObj = json["error"] as? [String: Any],
                   let errorMessage = errorObj["message"] as? String {
                    print("OpenAIService: API Error - \(errorMessage)")
                    completion(.failure(
                        NSError(
                            domain: "OpenAIService",
                            code: -5,
                            userInfo: [NSLocalizedDescriptionKey: errorMessage]
                        )
                    ))
                    return
                }
                
                // Parse choices -> message -> content[]
                guard
                    let choices = json["choices"] as? [[String: Any]],
                    let firstChoice = choices.first,
                    let message = firstChoice["message"] as? [String: Any],
                    let contentArray = message["content"] as? [[String: Any]]
                else {
                    print("OpenAIService: Invalid API Response Structure")
                    completion(.failure(
                        NSError(
                            domain: "OpenAIService",
                            code: -4,
                            userInfo: [NSLocalizedDescriptionKey: "Invalid API response"]
                        )
                    ))
                    return
                }
                
                // Find the text part in content array
                guard let textPart = contentArray.first(where: {
                    ($0["type"] as? String) == "text"
                }), let content = textPart["text"] as? String else {
                    print("OpenAIService: No text content part found")
                    completion(.failure(
                        NSError(
                            domain: "OpenAIService",
                            code: -7,
                            userInfo: [NSLocalizedDescriptionKey: "No text content returned from model"]
                        )
                    ))
                    return
                }
                
                print("OpenAIService: Content received: \(content)")
                
                // Clean up in case the model ignored instructions and added ```json fences
                let cleanContent = content
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard
                    let contentData = cleanContent.data(using: .utf8),
                    let artInfo = try JSONSerialization.jsonObject(with: contentData) as? [String: Any]
                else {
                    print("OpenAIService: JSON Parsing Error - Could not parse content string")
                    completion(.failure(
                        NSError(
                            domain: "OpenAIService",
                            code: -3,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to parse content JSON"]
                        )
                    ))
                    return
                }
                
                let artPiece = ArtPiece(
                    title: (artInfo["title"] as? String) ?? "Unknown",
                    artist: (artInfo["artist"] as? String) ?? "Unknown",
                    year: (artInfo["year"] as? String) ?? "Unknown",
                    description: (artInfo["description"] as? String) ?? "No description available.",
                    context: (artInfo["context"] as? String) ?? "No context available."
                )
                
                completion(.success(artPiece))
                
            } catch {
                print("OpenAIService: JSON Serialization Error - \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // MARK: - TTS (Generate Audio)
    func generateAudio(text: String, completion: @escaping (Result<Data, Error>) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/audio/speech")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": ttsModel,
            "input": text,
            "voice": ttsVoice
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("OpenAIService: TTS Network Error - \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("OpenAIService: TTS HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("OpenAIService: No audio data received")
                completion(.failure(
                    NSError(
                        domain: "OpenAIService",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "No audio data received"]
                    )
                ))
                return
            }
            
            completion(.success(data))
        }
        
        task.resume()
    }
}
    
