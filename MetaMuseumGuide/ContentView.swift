import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var glassesManager: GlassesManager
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var userPreferences = UserPreferences()
    @StateObject private var audioGuide = AudioGuide()
    @StateObject private var cameraService = CameraService()
    @StateObject private var historyManager = HistoryManager()
    
    @State private var recognizedArt: ArtPiece?
    @State private var capturedImage: UIImage?
    @State private var isScanning = false
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showMap = false
    @State private var showAPIKeyAlert = false
    @State private var recognitionError: Error?
    @State private var showRecognitionError = false
    
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Camera Preview
                // If glasses are connected, we show the "Glasses Feed" (from GlassesManager)
                // If not, we show the Phone Camera (from CameraService)
                if glassesManager.isConnected {
                    CameraPreview(session: glassesManager.glassesSession)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            VStack {
                                Spacer()
                                Text("Live View: Ray-Ban Meta")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(4)
                                    .foregroundColor(.green)
                                    .padding(.bottom, 100)
                            }
                        )
                } else if cameraService.isSessionRunning {
                    CameraPreview(session: cameraService.session)
                        .edgesIgnoringSafeArea(.all)
                } else {
                    Color.black.edgesIgnoringSafeArea(.all)
                }
                
                // Overlay Content
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: glassesManager.isConnected ? "eyeglasses" : "eyeglasses.slash")
                            .foregroundColor(glassesManager.isConnected ? .green : .white)
                            .font(.largeTitle)
                            .onTapGesture {
                                if glassesManager.isConnected {
                                    glassesManager.disconnect()
                                } else {
                                    glassesManager.connect()
                                }
                            }
                        
                        VStack(alignment: .leading) {
                            Text("Meta Glasses")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(glassesManager.connectionStatus)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                        
                        Button(action: { showMap = true }) {
                            Image(systemName: "map")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 8)
                        
                        Button(action: { showHistory = true }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 8)
                        
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gear")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Museum Status & Recommendations
                    if let museum = locationManager.currentMuseum {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "building.columns.fill")
                                    .foregroundColor(.purple)
                                Text("You are at **\(museum.name)**")
                                    .foregroundColor(.white)
                            }
                            
                            if !locationManager.recommendations.isEmpty {
                                Text("Recommended for you:")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(locationManager.recommendations) { exhibit in
                                            VStack(alignment: .leading) {
                                                Text(exhibit.name)
                                                    .font(.subheadline)
                                                    .bold()
                                                    .foregroundColor(.white)
                                                Text(exhibit.locationInMuseum)
                                                    .font(.caption2)
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                            .padding(8)
                                            .background(Color.purple.opacity(0.3))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .onAppear {
                            locationManager.updateRecommendations(for: userPreferences)
                        }
                        .onChange(of: userPreferences.interests) { _, _ in
                            locationManager.updateRecommendations(for: userPreferences)
                        }
                    }
                    
                    Spacer()
                    
                    // Art Display (Overlay)
                    if let art = recognizedArt {
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
                                    Text("About this piece")
                                        .font(.headline)
                                    Text(art.description)
                                        .font(.body)
                                    
                                    Divider()
                                    
                                    Text("Did you know?")
                                        .font(.headline)
                                    Text(art.context)
                                        .font(.body)
                                        .italic()
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                
                                Button(action: {
                                    audioGuide.speak("This is \(art.title) by \(art.artist). \(art.description). Context: \(art.context)")
                                }) {
                                    Label("Listen Guide", systemImage: "speaker.wave.2.fill")
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                
                                Button("Close") {
                                    withAnimation {
                                        recognizedArt = nil
                                        capturedImage = nil
                                    }
                                }
                                .padding(.top)
                            }
                            .padding()
                            .background(Color(.systemBackground).opacity(0.95))
                            .cornerRadius(16)
                            .shadow(radius: 10)
                        }
                        .padding()
                        .transition(.move(edge: .bottom))
                    }
                    
                    Spacer()
                    
                    // Controls
                    if recognizedArt == nil {
                        Button(action: scanArt) {
                            HStack {
                                if isScanning {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: glassesManager.isConnected ? "eyeglasses" : "camera.shutter.button.fill")
                                        .font(.largeTitle)
                                }
                            }
                            .frame(width: 70, height: 70)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 4))
                        }
                        .disabled(isScanning)
                        .padding(.bottom, 30)
                        
                        if isScanning && !scanStatus.isEmpty {
                            Text(scanStatus)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                                .transition(.opacity)
                                .padding(.bottom, 10)
                        }
                    }
                }
            }
            .navigationTitle("Museum Guide")
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView(preferences: userPreferences)
            }
            .sheet(isPresented: $showHistory) {
                HistoryView(historyManager: historyManager)
            }
            .sheet(isPresented: $showMap) {
                NavigationView {
                    ArtMapView(historyManager: historyManager, locationManager: locationManager)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showMap = false
                                }
                            }
                        }
                }
            }
            .onAppear {
                glassesManager.connect()
                locationManager.requestPermission()
                cameraService.checkPermissions()
                
                // Init AudioGuide with ElevenLabs
                audioGuide.setup(apiKey: userPreferences.elevenLabsAPIKey, voiceID: userPreferences.elevenLabsVoiceID)
            }
            .onChange(of: userPreferences.elevenLabsAPIKey) { _, newKey in
                audioGuide.setup(apiKey: newKey, voiceID: userPreferences.elevenLabsVoiceID)
            }
            .onChange(of: userPreferences.elevenLabsVoiceID) { _, newVoiceID in
                audioGuide.setup(apiKey: userPreferences.elevenLabsAPIKey, voiceID: newVoiceID)
            }
            .alert(item: $cameraService.alertError) { alertError in
                Alert(title: Text(alertError.title), message: Text(alertError.message), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showAPIKeyAlert) {
                Alert(title: Text("API Key Missing"), message: Text("Please enter your Gemini API Key in UserPreferences.swift to use this feature."), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showRecognitionError) {
                Alert(title: Text("Recognition Failed"), message: Text(recognitionError?.localizedDescription ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    
    @State private var scanStatus: String = ""
    
    private func scanArt() {
        print("ContentView: scanArt button pressed")
        
        // Create recognizer directly, allowing empty key (supports hardcoded keys in ArtRecognizer)
        let recognizer = OpenAIArtRecognizer(apiKey: userPreferences.geminiAPIKey)
        
        if userPreferences.geminiAPIKey.isEmpty {
            print("ContentView: Warning - Gemini API Key in preferences is empty. Attempting scan anyway (assuming hardcoded key).")
        }
        
        print("ContentView: Starting scan...")
        isScanning = true
        scanStatus = "Listening..."
        
        // Capture Block
        let handleCapture: (UIImage?, Error?) -> Void = { image, error in
            guard let image = image else {
                DispatchQueue.main.async {
                    isScanning = false
                    print("Capture error: \(String(describing: error))")
                    self.recognitionError = error
                    self.showRecognitionError = true
                }
                return
            }
            
            DispatchQueue.main.async {
                self.capturedImage = image
                scanStatus = "Thinking about this artwork..."
            }
            
            recognizer.recognizeArt(image: image, onPartial: { partialArt in
                // Show instant feedback
                withAnimation {
                    self.recognizedArt = partialArt
                }
            }, onComplete: { result in
                DispatchQueue.main.async {
                    isScanning = false
                    scanStatus = ""
                    switch result {
                    case .success(var art):
                        // Attach image data
                        if let image = self.capturedImage {
                            art.imageData = image.jpegData(compressionQuality: 0.5)
                        }
                        
                        // Attach location
                        if let location = locationManager.lastKnownLocation {
                            art.latitude = location.coordinate.latitude
                            art.longitude = location.coordinate.longitude
                        }
                        if let museum = locationManager.currentMuseum {
                            art.locationName = museum.name
                        }
                        
                        withAnimation {
                            self.recognizedArt = art
                        }
                        // Set Date
                        art.date = Date()
                        
                        // Save to History
                        historyManager.saveArt(art)
                        audioGuide.speak("This is \(art.title). \(art.description)")
                    case .failure(let error):
                        print("Error recognizing art: \(error)")
                        self.recognitionError = error
                        self.showRecognitionError = true
                    }
                }
            })
        }
        
        // Route capture based on connection
        if glassesManager.isConnected {
            print("ContentView: Capturing from Glasses Stream...")
            glassesManager.captureImage { image in
                if let image = image {
                    handleCapture(image, nil)
                } else {
                    handleCapture(nil, NSError(domain: "GlassesManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to capture from glasses"]))
                }
            }
        } else {
            print("ContentView: Capturing from Phone Camera...")
            cameraService.capturePhoto(completion: handleCapture)
        }
    }
}

struct HistoryView: View {
    @ObservedObject var historyManager: HistoryManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                if historyManager.history.isEmpty {
                    Text("No history yet. Scan some art!")
                        .foregroundColor(.gray)
                } else {
                    ForEach(historyManager.history) { art in
                        NavigationLink(destination: HistoryDetailView(art: art)) {
                            HStack {
                                if let data = art.imageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                        .clipped()
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                        .overlay(Image(systemName: "photo").foregroundColor(.gray))
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(art.title)
                                        .font(.headline)
                                    Text(art.artist)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    if let date = art.date {
                                        Text(date, style: .date)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.leading, 4)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { indexSet in
                        historyManager.history.remove(atOffsets: indexSet)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        historyManager.clearHistory()
                    }
                    .disabled(historyManager.history.isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct HistoryDetailView: View {
    let art: ArtPiece
    @StateObject private var audioGuide = AudioGuide() // Local audio guide for this view
    
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
                    Text("About this piece")
                        .font(.headline)
                    Text(art.description)
                        .font(.body)
                    
                    Divider()
                    
                    Text("Did you know?")
                        .font(.headline)
                    Text(art.context)
                        .font(.body)
                        .italic()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                Button(action: {
                    audioGuide.speak("This is \(art.title) by \(art.artist). \(art.description). Context: \(art.context)")
                }) {
                    Label("Listen Guide", systemImage: "speaker.wave.2.fill")
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("Art Details")
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
    }
}

struct SettingsView: View {
    @ObservedObject var preferences: UserPreferences
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Your Interests")) {
                    ForEach(UserPreferences.availableInterests, id: \.self) { interest in
                        HStack {
                            Text(interest)
                            Spacer()
                            if preferences.interests.contains(interest) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            preferences.toggleInterest(interest)
                        }
                    }
                }
            }
            .navigationTitle("Preferences")
            .toolbar {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(GlassesManager())
            .environmentObject(LocationManager())
    }
}
