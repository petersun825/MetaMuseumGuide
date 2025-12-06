import SwiftUI
struct ContentView: View {
    @EnvironmentObject var glassesManager: GlassesManager
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var audioGuide = AudioGuide()
    
    @State private var recognizedArt: ArtPiece?
    @State private var isScanning = false
    @State private var showPermissionAlert = false
    
    private let artRecognizer = AppleVisionArtRecognizer() // Uses Apple Vision Framework
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Image(systemName: glassesManager.isConnected ? "eyeglasses" : "eyeglasses.slash")
                        .foregroundColor(glassesManager.isConnected ? .green : .gray)
                        .font(.largeTitle)
                    
                    VStack(alignment: .leading) {
                        Text("Meta Glasses")
                            .font(.headline)
                        Text(glassesManager.connectionStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Museum Status
                if let museum = locationManager.currentMuseum {
                    HStack {
                        Image(systemName: "building.columns.fill")
                            .foregroundColor(.purple)
                        Text("You are at **\(museum)**")
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    Text("Locating Museum...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Art Display
                if let art = recognizedArt {
                    VStack(spacing: 16) {
                        // Placeholder for Art Image
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                            .cornerRadius(12)
                        
                        Text(art.title)
                            .font(.title2)
                            .bold()
                        
                        Text(art.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(art.year)
                            .font(.caption)
                            .padding(.bottom, 4)
                        
                        ScrollView {
                            Text(art.description)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button(action: {
                            audioGuide.speak(art.description)
                        }) {
                            Label("Listen Again", systemImage: "speaker.wave.2.fill")
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .transition(.opacity)
                } else {
                    VStack {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Look at an artwork and scan")
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                }
                
                Spacer()
                
                // Controls
                Button(action: scanArt) {
                    HStack {
                        if isScanning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(isScanning ? "Analyzing..." : "Identify Art")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(glassesManager.isConnected ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!glassesManager.isConnected || isScanning)
                
            }
            .padding()
            .navigationTitle("Museum Guide")
            .onAppear {
                glassesManager.connect()
                locationManager.requestPermission()
            }
        }
    }
    
    private func scanArt() {
        isScanning = true
        recognizedArt = nil
        
        glassesManager.captureImage { image in
            guard let image = image else {
                isScanning = false
                return
            }
            
            artRecognizer.recognizeArt(image: image) { result in
                DispatchQueue.main.async {
                    isScanning = false
                    switch result {
                    case .success(let art):
                        withAnimation {
                            self.recognizedArt = art
                        }
                        audioGuide.speak("This is \(art.title) by \(art.artist). \(art.description)")
                    case .failure(let error):
                        print("Error recognizing art: \(error)")
                    }
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
