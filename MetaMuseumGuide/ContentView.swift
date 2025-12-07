import SwiftUI

struct ContentView: View {
    @EnvironmentObject var glassesManager: GlassesManager
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var userPreferences = UserPreferences()
    @StateObject private var audioGuide = AudioGuide()
    @StateObject private var cameraService = CameraService()
    
    @State private var recognizedArt: ArtPiece?
    @State private var isScanning = false
    @State private var showSettings = false
    @State private var showAPIKeyAlert = false
    @State private var recognitionError: Error?
    @State private var showRecognitionError = false
    
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Camera Preview
                if !cameraService.isSessionRunning {
                    Color.black.edgesIgnoringSafeArea(.all)
                } else {
                    CameraPreview(session: cameraService.session)
                        .edgesIgnoringSafeArea(.all)
                }
                
                // Overlay Content
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: glassesManager.isConnected ? "eyeglasses" : "eyeglasses.slash")
                            .foregroundColor(glassesManager.isConnected ? .green : .white)
                            .font(.largeTitle)
                        
                        VStack(alignment: .leading) {
                            Text("Meta Glasses")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(glassesManager.connectionStatus)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                        
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
                        .onChange(of: userPreferences.interests) { _ in
                            locationManager.updateRecommendations(for: userPreferences)
                        }
                    }
                    
                    Spacer()
                    
                    // Art Display (Overlay)
                    if let art = recognizedArt {
                        ScrollView {
                            VStack(spacing: 16) {
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
                                    Image(systemName: "camera.shutter.button.fill")
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
            .onAppear {
                glassesManager.connect()
                locationManager.requestPermission()
                cameraService.checkPermissions()
                
                // Init AudioGuide with key if available
                if !userPreferences.openAIKey.isEmpty {
                    audioGuide.setup(apiKey: userPreferences.openAIKey)
                }
            }
            .onChange(of: userPreferences.openAIKey) { newKey in
                audioGuide.setup(apiKey: newKey)
            }
            .alert(item: $cameraService.alertError) { alertError in
                Alert(title: Text(alertError.title), message: Text(alertError.message), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showAPIKeyAlert) {
                Alert(title: Text("API Key Missing"), message: Text("Please enter your OpenAI API Key in Settings to use this feature."), dismissButton: .default(Text("OK")))
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
        let recognizer = OpenAIArtRecognizer(apiKey: userPreferences.openAIKey)
        
        if userPreferences.openAIKey.isEmpty {
            print("ContentView: Warning - API Key in preferences is empty. Attempting scan anyway (assuming hardcoded key).")
        }
        
        print("ContentView: Starting scan...")
        isScanning = true
        scanStatus = "Listening..."
        
        // Use CameraService to capture photo
        cameraService.capturePhoto { image, error in
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
                    case .success(let art):
                        withAnimation {
                            self.recognizedArt = art
                        }
                        audioGuide.speak("This is \(art.title). \(art.description)")
                    case .failure(let error):
                        print("Error recognizing art: \(error)")
                        self.recognitionError = error
                        self.showRecognitionError = true
                    }
                }
            })
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
