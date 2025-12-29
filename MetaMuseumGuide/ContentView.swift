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
    
    
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashScreenView {
                    showSplash = false
                }
            } else {
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
                                            cameraService.startSession()
                                        } else {
                                            cameraService.stopSession()
                                            glassesManager.connect()
                                        }
                                    }
                                
                                VStack(alignment: .leading) {
                                    Text(userPreferences.localized("Meta Glasses"))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text(userPreferences.localized(glassesManager.connectionStatus == "Connected" ? "Connected" : glassesManager.connectionStatus == "Disconnected" ? "Disconnected" : "Connecting..."))
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
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .onTapGesture(count: 2) {
                                // Double tap HUD to simulate exit for debugging
                                simulateExit()
                            }
                            
                            // Museum Status & Recommendations
                            if let museum = locationManager.currentMuseum {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "building.columns.fill")
                                            .foregroundColor(.purple)
                                        Text("\(userPreferences.localized("You are at")) **\(museum.name)**")
                                            .foregroundColor(.white)
                                    }
                                    
                                    if !locationManager.recommendations.isEmpty {
                                        Text(userPreferences.localized("Recommended for you:"))
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
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
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
                                ArtOverlayView(
                                    art: art,
                                    capturedImage: capturedImage,
                                    audioGuide: audioGuide,
                                    userPreferences: userPreferences,
                                    recognizedArt: $recognizedArt,
                                    capturedImageBinding: $capturedImage
                                )
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
                            .environmentObject(userPreferences)
                    }
                    .sheet(isPresented: $showMap) {
                        NavigationView {
                            ArtMapView(historyManager: historyManager, locationManager: locationManager)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button(userPreferences.localized("Done")) {
                                            showMap = false
                                        }
                                    }
                                }
                        }
                        .environmentObject(userPreferences)
                    }
                    .onAppear {
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
        }
        .onReceive(NotificationCenter.default.publisher(for: LocationManager.museumExitNotification)) { notification in
            handleMuseumExit(notification)
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
        scanStatus = userPreferences.localized("Listening...")
        
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
                scanStatus = userPreferences.localized("Thinking about this artwork...")
            }
            
            
            recognizer.recognizeArt(image: image, language: userPreferences.selectedLanguage, onPartial: { partialArt in
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
                        // Save to History
                        historyManager.saveArt(art)
                        audioGuide.speak("This is \(art.title). \(art.description)", language: userPreferences.selectedLanguage)
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
    
    // MARK: - Podcast Logic
    private func handleMuseumExit(_ notification: Notification) {
        guard let artRef = notification.userInfo?["art"] as? [ArtPiece] else { return }
        
        print("ContentView: Museum Exit Detected! Generating Podcast...")
        scanStatus = "Creating your visit summary..."
        isScanning = true // Reuse scanning UI for feedback
        
        // Use Gemini to write the script
        let gemini = GeminiService(apiKey: userPreferences.geminiAPIKey)
        gemini.createVisitSummary(artworks: artRef, preferences: userPreferences) { result in
        DispatchQueue.main.async {
                isScanning = false
                scanStatus = ""
                
                switch result {
                case .success(let script):
                    print("ContentView: Podcast Script Ready: \(script)")
                    // Speak with ElevenLabs
                    audioGuide.speak(script, language: userPreferences.selectedLanguage)
                case .failure(let error):
                    print("ContentView: Podcast Generation Failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Debug
    private func simulateExit() {
        locationManager.simulateExit()
        // If location manager thinks we are not visiting (because we manually reset or something), warning is printed.
    }
}
// Removed Structs - they are now in their own files
