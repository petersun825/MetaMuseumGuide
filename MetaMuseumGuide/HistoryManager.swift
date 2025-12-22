//
//  HistoryManager.swift
//  MuseumMuse
//
//  Created by Peter Sun on 12/17/25.
//
import Foundation
import SwiftUI

class HistoryManager: ObservableObject {
    @Published var history: [ArtPiece] = []
    private let historyKey = "art_history_log"
    
    init() {
        loadHistory()
    }
    
    func saveArt(_ art: ArtPiece) {
        // Avoid duplicates (optional logic)
        if !history.contains(where: { $0.title == art.title && $0.artist == art.artist }) {
            history.insert(art, at: 0) // Add to top
            persistHistory()
        }
    }
    
    func clearHistory() {
        history.removeAll()
        persistHistory()
    }
    
    private func persistHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([ArtPiece].self, from: data) {
            self.history = decoded
        }
    }
}

