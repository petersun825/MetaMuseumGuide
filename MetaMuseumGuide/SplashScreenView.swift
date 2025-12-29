//
//  SplashScreenView.swift
//  MuseumMuse
//
//  Created by Peter Sun on 12/27/25.
//
import SwiftUI

struct SplashScreenView: View {
    var onFinish: () -> Void
    
    @State private var opacity = 0.0
    @State private var scale = 0.8
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
//            ZStack {
//                          LinearGradient(gradient: Gradient(colors: [Color.white, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
//                          Image("SplashBackground")
//                              .resizable()
//                              .scaledToFill()
//                      }
//                      .edgesIgnoringSafeArea(.all)
//                          .overlay(Color.black.opacity(0.3)) // Overlay for readability
//        
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "eyeglasses")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                    .shadow(radius: 10)
                
                Text("MuseumMuse")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                
                Spacer()
                
                Text("Take photos of things you would like to learn more about.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
            }
            .opacity(opacity)
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                self.opacity = 1.0
                self.scale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation {
                    onFinish()
                }
            }
        }
    }
}

