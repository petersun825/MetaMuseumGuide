//
//  ElevenLabs.swift
//  MuseumMuse
//
//  Created by Peter Sun on 12/19/25.
//
import Foundation
import AVFoundation

class ElevenLabsService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private let apiKey: String
    private let voiceID: String
    private var audioPlayer: AVAudioPlayer?
    
    init(apiKey: String, voiceID: String) {
        self.apiKey = apiKey
        self.voiceID = voiceID
        super.init()
    }
    
    deinit {
        print("ElevenLabsService: Deallocated")
    }
    
    func speak(text: String) {
        guard !apiKey.isEmpty, !voiceID.isEmpty else {
            print("ElevenLabsService: Missing API Key or Voice ID")
            return
        }
        
        // Use non-streaming endpoint for reliability with AVAudioPlayer
        let urlString = "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_multilingual_v2",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("ElevenLabsService: Requesting TTS for: \(text.prefix(20))...")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("ElevenLabsService: Error - \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("ElevenLabsService: HTTP Error - \(httpResponse.statusCode)")
                if let data = data, let errorText = String(data: data, encoding: .utf8) {
                    print("ElevenLabsService: Response: \(errorText)")
                }
                return
            }
            
            guard let data = data else { return }
            print("ElevenLabsService: Received audio data (\(data.count) bytes)")
            
            // Play audio data
            self?.playAudio(data: data)
        }
        task.resume()
    }
    
    private func playAudio(data: Data) {
        DispatchQueue.main.async {
            do {
                // Ensure session is active
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
                try AVAudioSession.sharedInstance().setActive(true)
                
                self.audioPlayer = try AVAudioPlayer(data: data)
                self.audioPlayer?.delegate = self
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
                print("ElevenLabsService: Playing audio with AVAudioPlayer...")
            } catch {
                print("ElevenLabsService: Failed to play audio - \(error)")
            }
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("ElevenLabsService: Audio finished playing (Success: \(flag))")
        // Deactivate session to let other audio resume if needed
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
