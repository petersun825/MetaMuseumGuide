//
//  UserPreferences.swift
//  MuseumMuse
//
//  Created by Peter Sun on 12/6/25.
//
import Foundation

class UserPreferences: ObservableObject {
    @Published var interests: Set<String> = [] {
        didSet {
            save()
        }
    }
    
    @Published var openAIKey: String = "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"
    //api key 12/7/25 museum
    
    // Available interest tags
    static let availableInterests = [
        "Modern Art",
        "Classical",
        "History",
        "Sculpture",
        "Impressionism",
        "Technology"
    ]
    
    init() {
        // Trim whitespace from the hardcoded key to prevent copy-paste errors
        openAIKey = openAIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        // Debug: Print the key being used (masked)
        if !openAIKey.isEmpty {
            let keyLength = openAIKey.count
            let prefix = String(openAIKey.prefix(8))
            let suffix = String(openAIKey.suffix(4))
            print("UserPreferences: Using API Key: \(prefix)...\(suffix) (Length: \(keyLength))")
            // Deep Debug: Print first 10 bytes to check for hidden characters
            let bytes = openAIKey.prefix(10).utf8.map { String($0) }.joined(separator: ", ")
            print("UserPreferences: Key Bytes (first 10): [\(bytes)]")
            
        } else {
                    print("UserPreferences: API Key is empty")
                }
       
           
               
        load()
    }
    
    func toggleInterest(_ interest: String) {
        if interests.contains(interest) {
            interests.remove(interest)
        } else {
            interests.insert(interest)
        }
    }
    
    private func save() {
        UserDefaults.standard.set(Array(interests), forKey: "userInterests")
        // We no longer save the API key to UserDefaults
    }
    
    private func load() {
        if let savedInterests = UserDefaults.standard.array(forKey: "userInterests") as? [String] {
            interests = Set(savedInterests)
        }
        // We no longer load the API key from UserDefaults
    }
}
