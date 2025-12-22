//
//  GlassesManager.swift
//  MetaMuseumGuide
//
//  Created by Peter Sun on 12/5/25.
//
import Foundation
import SwiftUI
// import MWDATCore
// import MWDATCamera

import AVFoundation

class GlassesManager: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var connectionStatus: String = "Disconnected"
    
    // The "Glasses" feed (Simulated using Phone Camera)
    @Published var glassesSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "glasses.session.queue")
    private var photoOutput = AVCapturePhotoOutput()
    
    func connect() {
        connectionStatus = "Searching..."
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isConnected = true
            self.connectionStatus = "Connected to Ray-Ban Meta"
            self.startStreaming()
        }
    }
    
    func disconnect() {
        self.isConnected = false
        self.connectionStatus = "Disconnected"
        self.stopStreaming()
    }
    
    private func startStreaming() {
        // Setup and start the camera session to simulate the glasses feed
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.configureSession()
            if !self.glassesSession.isRunning {
                self.glassesSession.startRunning()
            }
        }
    }
    
    private func stopStreaming() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.glassesSession.isRunning {
                self.glassesSession.stopRunning()
            }
        }
    }
    
    private func configureSession() {
        glassesSession.beginConfiguration()
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            glassesSession.commitConfiguration()
            return
        }
        
        // Input
        if let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
           glassesSession.canAddInput(videoDeviceInput) {
            glassesSession.addInput(videoDeviceInput)
        }
        
        // Output
        if glassesSession.canAddOutput(photoOutput) {
            glassesSession.addOutput(photoOutput)
            if #available(iOS 16.0, *) {
                if let maxDimensions = videoDevice.activeFormat.supportedMaxPhotoDimensions.last {
                    photoOutput.maxPhotoDimensions = maxDimensions
                }
            } else {
                photoOutput.isHighResolutionCaptureEnabled = true
            }
        }
        
        glassesSession.commitConfiguration()
    }
    
    func captureImage(completion: @escaping (UIImage?) -> Void) {
        guard isConnected else {
            print("Not connected to glasses")
            completion(nil)
            return
        }
        
        print("GlassesManager: Capturing image from stream...")
        
        // Capture from the session
        let settings = AVCapturePhotoSettings()
        let delegate = PhotoCaptureDelegate { image in
            completion(image)
        }
        // Retain delegate
        self.currentCaptureDelegate = delegate
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }
    
    private var currentCaptureDelegate: PhotoCaptureDelegate?
}

// Helper Delegate for capturing photo
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
            completion(image)
        } else {
            completion(nil)
        }
    }
}
