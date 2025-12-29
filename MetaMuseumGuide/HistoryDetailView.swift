//
//  HistoryDetailView.swift
//  MuseumMuse
//
//  Created by Peter Sun on 12/27/25.
//
import SwiftUI
import AVFoundation

struct HistoryDetailView: View {
    let art: ArtPiece
    let language: String
    @StateObject private var audioGuide = AudioGuide() // Local audio guide for this view
    @EnvironmentObject var userPreferences: UserPreferences
    @State private var harvardDetails: ArtObject?
    @State private var isFetchingDetails = false
    @State private var showDetailsSheet = false
    
    var shareText: String {
        var text = """
        Title: \(art.title)
        Artist: \(art.artist)
        Year: \(art.year)
        """
        
        if let loc = art.locationName {
            text += "\nLocation: \(loc)"
        }
        
        text += """
        
        
        About this piece:
        \(art.description)
        
        Did you know?
        \(art.context)
        """
        return text
    }
    
    var shareImage: Image {
        if let data = art.imageData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "photo")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let data = art.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
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
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 5)
                
                Button(action: {
                    audioGuide.speak("This is \(art.title) by \(art.artist). \(art.description). Context: \(art.context)", language: language)
                }) {
                    Label(userPreferences.localized("Listen Guide"), systemImage: "speaker.wave.2.fill")
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Harvard Museum "Learn More"
                if (art.locationName?.contains("Harvard") == true || art.locationName == "Harvard Art Museums") {
                    Button(action: fetchHarvardDetails) {
                        HStack {
                            if isFetchingDetails {
                                ProgressView()
                            } else {
                                Text(userPreferences.localized("Learn More (Harvard API)"))
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.top)
                }
                
                // AI Chat Section
                AIChatView(context: "Title: \(art.title)\nArtist: \(art.artist)\nDescription: \(art.description)", audioGuide: audioGuide)
                    .padding(.vertical)
            }
            .padding()
            .onAppear {
                 // Init AudioGuide with ElevenLabs
                 audioGuide.setup(apiKey: userPreferences.elevenLabsAPIKey, voiceID: userPreferences.elevenLabsVoiceID)
            }
        }
        .background(Color(.systemGroupedBackground)) // Subtle background for the scroll view
        .navigationTitle(userPreferences.localized("Art Details"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let data = art.imageData, let uiImage = UIImage(data: data) {
                    ShareLink(item: shareText, preview: SharePreview(art.title, image: Image(uiImage: uiImage))) {
                        Image(systemName: "square.and.arrow.up")
                    }
                } else {
                    ShareLink(item: shareText) {
                         Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showDetailsSheet) {
            if let details = harvardDetails {
                LiquidGlassView(details: details)
            }
        }
        .onDisappear {
            audioGuide.stop() // Stop audio when leaving details
        }
    }
    
    private func fetchHarvardDetails() {
        guard !userPreferences.harvardAPIKey.isEmpty else { return }
        isFetchingDetails = true
        
        let service = MuseumLookupService(apiKey: userPreferences.harvardAPIKey)
        
        Task {
            do {
                if let details = try await service.fetchArtDetails(query: art.title) {
                    DispatchQueue.main.async {
                        self.harvardDetails = details
                        self.showDetailsSheet = true
                        self.isFetchingDetails = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isFetchingDetails = false
                        // Handle no results
                    }
                }
            } catch {
                print("Error: \(error)")
                DispatchQueue.main.async {
                    self.isFetchingDetails = false
                }
            }
        }
    }
}

struct LiquidGlassView: View {
    let details: ArtObject
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userPreferences: UserPreferences
    @StateObject private var audioGuide = AudioGuide()
    
    var body: some View {
        ZStack {
            // Background Blur with gradient
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .background(Material.ultraThinMaterial)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            VStack(alignment: .leading, spacing: 0) {
                // Header Control
                HStack {
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Title & Metadata
                        VStack(alignment: .leading, spacing: 8) {
                            Text(details.title)
                                .font(.largeTitle)
                                .bold()
                            
                            if let culture = details.culture {
                                Text(culture)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let dated = details.dated {
                                Text(dated)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary.opacity(0.8))
                            }
                        }
                        
                        // Image Gallery
                        if let images = details.images, !images.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(images) { image in
                                        if let urlString = image.baseimageurl, let url = URL(string: urlString) {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                        .frame(width: 200, height: 200)
                                                case .success(let img):
                                                    img.resizable()
                                                        .scaledToFit()
                                                        .frame(height: 300)
                                                        .cornerRadius(12)
                                                        .shadow(radius: 5)
                                                case .failure:
                                                    Image(systemName: "photo")
                                                        .frame(width: 200, height: 200)
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } else if let primaryStr = details.primaryimageurl, let url = URL(string: primaryStr) {
                             AsyncImage(url: url) { image in
                                 image.resizable()
                                     .scaledToFit()
                                     .cornerRadius(12)
                                     .shadow(radius: 5)
                             } placeholder: {
                                 ProgressView()
                             }
                        }
                        
                        // Audio Content
                        if let audios = details.audio, !audios.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Audio Content", systemImage: "headphones")
                                    .font(.headline)
                                
                                ForEach(audios) { audio in
                                    if let urlString = audio.primaryurl, let url = URL(string: urlString) {
                                        Link(destination: url) {
                                            HStack {
                                                Image(systemName: "play.circle.fill")
                                                    .font(.title2)
                                                VStack(alignment: .leading) {
                                                    Text(audio.description ?? "Audio Clip")
                                                        .font(.body)
                                                        .foregroundColor(.primary)
                                                    if let duration = audio.duration {
                                                        Text(String(format: "%.0f seconds", duration))
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                Spacer()
                                                Image(systemName: "arrow.up.right")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding()
                                            .background(.ultraThinMaterial)
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 12) {
                             if let People = details.people {
                                 Text("People")
                                     .font(.headline)
                                 ForEach(People) { person in
                                     Text("\(person.displayname ?? "Unknown") (\(person.role ?? "Role"))")
                                         .font(.subheadline)
                                 }
                                 Divider()
                             }
                            
                            Text(details.voiceReadyDescription)
                                .font(.body)
                                .lineSpacing(6)
                            
                            if let tech = details.technique {
                                Text("Technique: \(tech)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                            
                            if let classif = details.classification {
                                Text("Classification: \(classif)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // AI Chat Section (Reusable)
                        AIChatView(context: "Title: \(details.title)\nDate: \(details.dated ?? "")\nTechnique: \(details.technique ?? "")\nDescription: \(details.voiceReadyDescription)", audioGuide: audioGuide)
                            .padding(.vertical)
                        
                        // Website Link
                        if let urlString = details.url, let url = URL(string: urlString) {
                            Link(destination: url) {
                                HStack {
                                    Text("View on Harvard Art Museums Website")
                                    Spacer()
                                    Image(systemName: "safari")
                                }
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.top)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
             audioGuide.setup(apiKey: userPreferences.elevenLabsAPIKey, voiceID: userPreferences.elevenLabsVoiceID)
        }
        .onDisappear {
            audioGuide.stop()
        }
    }
}

// Helper for corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
