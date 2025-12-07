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
    func recognizeArt(image: UIImage, onPartial: @escaping (ArtPiece) -> Void, onComplete: @escaping (Result<ArtPiece, Error>) -> Void)
}

struct ArtPiece: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let year: String
    let description: String
    let context: String
}

class OpenAIArtRecognizer: ArtRecognizerService {
    private let openAIService: OpenAIService
    
    init(apiKey: String) {
        self.openAIService = OpenAIService(apiKey: "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")
    }
    
    func recognizeArt(image: UIImage, onPartial: @escaping (ArtPiece) -> Void, onComplete: @escaping (Result<ArtPiece, Error>) -> Void) {
        // 1. Instant Local Recognition (OCR)
        performLocalRecognition(image: image, onPartial: onPartial)
        
        // 2. Deep OpenAI Analysis
        openAIService.identifyArt(image: image, completion: onComplete)
    }
    
    private func performLocalRecognition(image: UIImage, onPartial: @escaping (ArtPiece) -> Void) {
        guard let cgImage = image.cgImage else { return }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            let fullText = recognizedStrings.joined(separator: " ")
            
            if !fullText.isEmpty {
                print("Local Vision Found: \(fullText)")
                // Create a temporary "Partial" result
                let partialPiece = ArtPiece(
                    title: "Scanning...",
                    artist: "Found text: \"\(fullText.prefix(30))...\"",
                    year: "",
                    description: "Analyzing details...",
                    context: ""
                )
                DispatchQueue.main.async {
                    onPartial(partialPiece)
                }
            }
        }
        request.recognitionLevel = .fast
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}
