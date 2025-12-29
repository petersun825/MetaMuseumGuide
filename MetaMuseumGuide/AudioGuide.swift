//
//  Audioguide.swift
//  MetaMuseumGuide
//
//  Created by Peter Sun on 12/5/25.
//
import Foundation
import AVFoundation

class AudioGuide: ObservableObject {
    private var elevenLabsService: ElevenLabsService?
    private let synthesizer = AVSpeechSynthesizer() // Fallback
    
    func setup(apiKey: String, voiceID: String) {
        // Initialize ElevenLabs Service
        self.elevenLabsService = ElevenLabsService(apiKey: apiKey, voiceID: voiceID)
        
        // Configure audio session for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioGuide: Failed to setup audio session - \(error)")
        }
    }
    
    func speak(_ text: String, language: String = "English") {
        if let elevenLabs = elevenLabsService {
            print("AudioGuide: Speaking with ElevenLabs...")
            elevenLabs.speak(text: text)
        } else {
            print("AudioGuide: Speaking with Native TTS (Fallback)...")
            let utterance = AVSpeechUtterance(string: text)
            
            let languageCode: String
            switch language {
            case "French": languageCode = "fr-FR"
            case "Spanish": languageCode = "es-ES"
            case "Italian": languageCode = "it-IT"
            case "Chinese": languageCode = "zh-CN"
            case "Japanese": languageCode = "ja-JP"
            case "German": languageCode = "de-DE"
            case "Portuguese": languageCode = "pt-PT"
            default: languageCode = "en-US"
            }
            
            utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
            utterance.rate = 0.5
            synthesizer.speak(utterance)
        }
    }
    
    func stop() {
        elevenLabsService?.stop()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
