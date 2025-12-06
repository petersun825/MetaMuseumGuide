//
//  ArtRecognizer.swift
//  MetaMuseumGuide
//
//  Created by Peter Sun on 12/5/25.
//

import Foundation
import UIKit
import Vision

protocol ArtRecognizerService {
    func recognizeArt(image: UIImage, completion: @escaping (Result<ArtPiece, Error>) -> Void)
}

struct ArtPiece: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let description: String
    let year: String
}

class AppleVisionArtRecognizer: ArtRecognizerService {
    func recognizeArt(image: UIImage, completion: @escaping (Result<ArtPiece, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(NSError(domain: "ArtRecognizer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Image"])))
            return
        }
        
        // Create a Vision request to recognize text (OCR)
        // This is great for reading museum placards/labels
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(NSError(domain: "ArtRecognizer", code: -2, userInfo: [NSLocalizedDescriptionKey: "No text found"])))
                return
            }
            
            // Combine recognized text
            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            let fullText = recognizedStrings.joined(separator: " ")
            
            print("Recognized Text: \(fullText)")
            
            // Simple keyword matching to identify art (in a real app, this would query a database)
            let artPiece = self.identifyArtFromText(fullText)
            completion(.success(artPiece))
        }
        
        request.recognitionLevel = .accurate
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func identifyArtFromText(_ text: String) -> ArtPiece {
        // Naive matching logic for demo purposes
        if text.contains("Starry") || text.contains("Gogh") {
            return ArtPiece(title: "The Starry Night", artist: "Vincent van Gogh", description: "A post-impressionist masterpiece depicting a swirling night sky.", year: "1889")
        } else if text.contains("Mona") || text.contains("Lisa") || text.contains("Vinci") {
            return ArtPiece(title: "Mona Lisa", artist: "Leonardo da Vinci", description: "A half-length portrait painting considered an archetypal masterpiece.", year: "1503")
        } else if text.contains("Persistence") || text.contains("Dali") {
            return ArtPiece(title: "The Persistence of Memory", artist: "Salvador Dalí", description: "A surrealist painting featuring melting pocket watches.", year: "1931")
        } else {
            // Fallback if we read text but don't recognize the specific keywords
            return ArtPiece(title: "Unknown Artwork", artist: "Unknown Artist", description: "I read the following text: \"\(text)\", but couldn't match it to my database.", year: "Unknown")
        }
    }
}
