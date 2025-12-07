//
//  Audioguide.swift
//  MetaMuseumGuide
//
//  Created by Peter Sun on 12/5/25.
//
import Foundation
import AVFoundation

class AudioGuide: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer?
    private var openAIService: OpenAIService?
    
    override init() {
        super.init()
        // We will inject the service or key later, or init with a default if needed.
        // For now, we'll rely on the caller to provide the service or key.
    }
    
    func setup(apiKey: String) {
        self.openAIService = OpenAIService(apiKey: apiKey)
    }
    
    func speak(_ text: String) {
        guard let service = openAIService else {
            print("AudioGuide: OpenAIService not initialized. Call setup(apiKey:) first.")
            return
        }
        
        service.generateAudio(text: text) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.playAudio(data: data)
                case .failure(let error):
                    print("TTS Error: \(error)")
                }
            }
        }
    }
    
    private func playAudio(data: Data) {
        do {
            // Configure audio session to play through system output (which would be the glasses if connected)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            print("Audio Playback Error: \(error)")
        }
    }
    
    func stop() {
        audioPlayer?.stop()
    }
}
