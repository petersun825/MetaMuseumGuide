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
    // Gemini API Key Vertex API
    @Published var geminiAPIKey: String = "AQ.Ab8RN6JCMTbTosmJJxcoYZR5bP18UqAi9FdK0-yNEEgffz2Hsw" // Replace with your actual key
    // Harvard API Key
     @Published var harvardAPIKey: String = "96cb1943-feb9-4c02-aa9a-37a614db9dbe"
    
    // ElevenLabs API Key & Voice ID
    @Published var elevenLabsAPIKey: String = "sk_50425815b30e3a91766ac807acf2c11add7319bcc68257d4"
    @Published var elevenLabsVoiceID: String = "21m00Tcm4TlvDq8ikWAM" { // Default voice "Rachel"
        didSet {
            save()
        }
    }
//    @Published var openAIKey: String = ""
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
    
    // Available ElevenLabs Voices
    static let availableVoices = [
        "Rachel": "21m00Tcm4TlvDq8ikWAM",
        "Drew": "29vD33N1CtxCmqQRPOHJ",
        "Clyde": "2EiwWnXFnvU5JabPnv8n",
        "Mimi": "zrHiDhphv9ZnVXBqCLjf",
        "Fin": "D38z5RcWu1voky8WS1ja"
    ]
    
    // Available Languages
    static let availableLanguages = [
        "English",
        "French",
        "Spanish",
        "Italian",
        "Chinese",
        "Japanese",
        "German",
        "Portuguese"
    ]
    
    @Published var selectedLanguage: String = "English" {
        didSet {
            save()
        }
    }
    
    init() {
        // Trim whitespace from the hardcoded key to prevent copy-paste errors
        geminiAPIKey = geminiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        elevenLabsAPIKey = elevenLabsAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
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
        UserDefaults.standard.set(elevenLabsVoiceID, forKey: "elevenLabsVoiceID")
        UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
    }
    
    private func load() {
        if let savedInterests = UserDefaults.standard.array(forKey: "userInterests") as? [String] {
            interests = Set(savedInterests)
        }
        if let savedVoiceID = UserDefaults.standard.string(forKey: "elevenLabsVoiceID") {
            elevenLabsVoiceID = savedVoiceID
        }
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") {
            selectedLanguage = savedLanguage
        }
    }
    func localized(_ key: String) -> String {
          guard let translations = LocalizationData.translations[key],
                let translation = translations[selectedLanguage] else {
              return key // Fallback to key (English) if missing
          }
          return translation
      }
}
