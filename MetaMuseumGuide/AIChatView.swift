//
//  AIChatView.swift
//  MuseumMuse
//
//  Created by Peter Sun on 12/28/25.
//
import SwiftUI

struct AIChatView: View {
    let context: String
    @ObservedObject var audioGuide: AudioGuide
    @EnvironmentObject var userPreferences: UserPreferences
    
    // Chat State
    @State private var chatMessage: String = ""
    @State private var chatHistory: [(role: String, text: String)] = []
    @State private var isSending: Bool = false
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
            Text("Ask the AI Guide")
                .font(.headline)
            
            // Chat History
            if !chatHistory.isEmpty {
                ForEach(0..<chatHistory.count, id: \.self) { index in
                    let message = chatHistory[index]
                    HStack {
                        if message.role == "user" {
                            Spacer()
                            Text(message.text)
                                .padding(10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .cornerRadius(4, corners: .bottomRight)
                        } else {
                            Text(message.text)
                                .padding(10)
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                                .cornerRadius(4, corners: .bottomLeft)
                            Spacer()
                        }
                    }
                }
            } else {
                Text("Ask questions like 'Who painted this?' or 'What is the technique?'")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            // Input Bar
            HStack(spacing: 12) {
                TextField("Ask a question...", text: $chatMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isSending || speechRecognizer.isRecording)
                    .onChange(of: speechRecognizer.transcript) { newValue in
                        if !newValue.isEmpty {
                            chatMessage = newValue
                        }
                    }
                
                // Voice Button
                Button(action: {
                    if speechRecognizer.isRecording {
                        speechRecognizer.stopRecording()
                    } else {
                        audioGuide.stop() // Stop previous audio when recording starts
                        chatMessage = "" // Clear old text
                        speechRecognizer.startRecording()
                    }
                }) {
                    Image(systemName: speechRecognizer.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title2)
                        .foregroundColor(speechRecognizer.isRecording ? .red : .blue)
                }
                
                // Send Button
                if !speechRecognizer.isRecording {
                    Button(action: sendMessage) {
                        if isSending {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(chatMessage.isEmpty ? .gray : .green)
                        }
                    }
                    .disabled(chatMessage.isEmpty || isSending)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .onChange(of: speechRecognizer.isRecording) { isRecording in
                if !isRecording && !chatMessage.isEmpty {
                    sendMessage()
                }
            }
        }
    }
    
    func sendMessage() {
        guard !chatMessage.isEmpty else { return }
        let question = chatMessage
        chatMessage = "" // Clear input immediately
        audioGuide.stop() // Stop any previous speech
        
        // Add User Message
        chatHistory.append((role: "user", text: question))
        isSending = true
        
        let historyStrings = chatHistory.map { "\($0.role): \($0.text)" }
        let gemini = GeminiService(apiKey: userPreferences.geminiAPIKey)
        
        gemini.chatAboutArt(history: historyStrings, question: question, context: context) { result in
            DispatchQueue.main.async {
                isSending = false
                switch result {
                case .success(let answer):
                    chatHistory.append((role: "model", text: answer))
                    // Speak the answer with ElevenLabs
                    audioGuide.speak(answer, language: userPreferences.selectedLanguage)
                case .failure(let error):
                    chatHistory.append((role: "model", text: "Sorry, I couldn't get an answer. \(error.localizedDescription)"))
                }
            }
        }
    }
}
