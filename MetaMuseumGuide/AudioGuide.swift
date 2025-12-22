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
        // ElevenLabs disabled by user request - reverting to native TTS
        // self.elevenLabsService = ElevenLabsService(apiKey: apiKey, voiceID: voiceID)
        
        // Configure audio session for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioGuide: Failed to setup audio session - \(error)")
        }
    }
    
    func speak(_ text: String) {
        // Force Native TTS
        print("AudioGuide: Speaking with Native TTS...")
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
        
        /* ElevenLabs Disabled
        if let elevenLabs = elevenLabsService {
            print("AudioGuide: Speaking with ElevenLabs...")
            elevenLabs.speak(text: text)
        } else {
            print("AudioGuide: Speaking with Native TTS (Fallback)...")
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.5
            synthesizer.speak(utterance)
        }
        */
    }
    
    func stop() {
        elevenLabsService?.stop()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
