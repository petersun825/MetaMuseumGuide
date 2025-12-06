//
//  Audioguide.swift
//  MetaMuseumGuide
//
//  Created by Peter Sun on 12/5/25.
//

import Foundation
import AVFoundation

class AudioGuide: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        // Configure audio session to play through system output (which would be the glasses if connected)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
