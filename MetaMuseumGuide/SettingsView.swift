//
//  SettingsView.swift
//  MuseumMuse
//
//  Created by Peter Sun on 12/27/25.
//
import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: UserPreferences
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                // Glass Background
                LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Language Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text(preferences.localized("Language"))
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 1) {
                                ForEach(UserPreferences.availableLanguages, id: \.self) { language in
                                    Button(action: {
                                        preferences.selectedLanguage = language
                                    }) {
                                        HStack {
                                            Text(language)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if preferences.selectedLanguage == language {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding()
                                        .background(.ultraThinMaterial)
                                    }
                                }
                            }
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                            .padding(.horizontal)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    .padding(.horizontal)
                            )
                        }
                        
                        // Interests Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text(preferences.localized("Your Interests"))
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                                ForEach(UserPreferences.availableInterests, id: \.self) { interest in
                                    Button(action: {
                                        preferences.toggleInterest(interest)
                                    }) {
                                        HStack {
                                            Text(interest)
                                                .font(.subheadline)
                                            Spacer()
                                            if preferences.interests.contains(interest) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.blue)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(.secondary.opacity(0.5))
                                            }
                                        }
                                        .padding()
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(preferences.interests.contains(interest) ? Color.blue.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 2)
                                        )
                                    }
                                    .foregroundColor(.primary)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(preferences.localized("Preferences"))
            .toolbar {
                Button(preferences.localized("Done")) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
