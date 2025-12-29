//
//  ArtOverlayView.swift
//  MuseumMuse
//
//  Created by Peter Sun on 12/26/25.
//
import SwiftUI

struct ArtOverlayView: View {
    let art: ArtPiece?
    let capturedImage: UIImage?
    @ObservedObject var audioGuide: AudioGuide
    @ObservedObject var userPreferences: UserPreferences
    @Binding var recognizedArt: ArtPiece?
    @Binding var capturedImageBinding: UIImage?
    
    var body: some View {
        if let art = art {
            ScrollView {
                VStack(spacing: 16) {
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                    
                    Text(art.title)
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    Text(art.artist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(art.year)
                        .font(.caption)
                    
                    // Context Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(userPreferences.localized("About this piece"))
                            .font(.headline)
                        Text(art.description)
                            .font(.body)
                        
                        Divider()
                        
                        Text(userPreferences.localized("Did you know?"))
                            .font(.headline)
                        Text(art.context)
                            .font(.body)
                            .italic()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    Button(action: {
                        audioGuide.speak("This is \(art.title) by \(art.artist). \(art.description). Context: \(art.context)", language: userPreferences.selectedLanguage)
                    }) {
                        Label(userPreferences.localized("Listen Guide"), systemImage: "speaker.wave.2.fill")
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // AI Chat Section
                    AIChatView(context: "Title: \(art.title)\nArtist: \(art.artist)\nDescription: \(art.description)", audioGuide: audioGuide)
                        .environmentObject(userPreferences)
                        .padding(.vertical)
                    
                    Button(userPreferences.localized("Close")) {
                        audioGuide.stop() // Stop audio on close
                        withAnimation {
                            recognizedArt = nil
                            capturedImageBinding = nil
                        }
                    }
                    .padding(.top)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(radius: 10)
            }
            .padding()
            .transition(.move(edge: .bottom))
        }
    }
}
