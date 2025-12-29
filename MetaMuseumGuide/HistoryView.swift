//
//  HistoryView.swift
//  MuseumMuse
//
//  Created by Peter Sun on 12/27/25.
//
import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyManager: HistoryManager
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userPreferences: UserPreferences
    
    var body: some View {
        NavigationView {
            ZStack {
                // Global background for the "Glass" effect
                LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if historyManager.history.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("No history yet.")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                Text("Scan some art to populate your collection.")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.top, 50)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                        } else {
                            ForEach(historyManager.history) { art in
                                NavigationLink(destination: HistoryDetailView(art: art, language: userPreferences.selectedLanguage).environmentObject(userPreferences)) {
                                    HStack(spacing: 16) {
                                        // Image Thumbnail
                                        if let data = art.imageData, let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(12)
                                                .clipped()
                                        } else {
                                            Rectangle()
                                                .fill(Color.white.opacity(0.1))
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(12)
                                                .overlay(Image(systemName: "photo").foregroundColor(.white.opacity(0.5)))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(art.title)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                                .lineLimit(2)
                                            
                                            Text(art.artist)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            
                                            if let date = art.date {
                                                Text(date, style: .date)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary.opacity(0.8))
                                            }
                                        }
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary.opacity(0.5))
                                    }
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle(userPreferences.localized("History"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        historyManager.clearHistory()
                    }) {
                        Text(userPreferences.localized("Clear"))
                            .foregroundColor(.red)
                    }
                    .disabled(historyManager.history.isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(userPreferences.localized("Done")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
