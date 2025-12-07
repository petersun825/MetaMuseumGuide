//
//  CameraService.swift
//  MuseumMuse
//
//  Created by Peter Sun on 12/6/25.
//
import Foundation
import AVFoundation
import UIKit

class CameraService: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isSessionRunning = false
    @Published var alertError: AlertError?
    
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var photoOutput = AVCapturePhotoOutput()
    private var photoCaptureCompletionBlock: ((UIImage?, Error?) -> Void)?
    
    struct AlertError: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }
    
    override init() {
        super.init()
        setupSession()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.startSession()
                }
            }
        case .restricted, .denied:
            DispatchQueue.main.async {
                self.alertError = AlertError(title: "Camera Access", message: "Please enable camera access in Settings to use this feature.")
            }
        case .authorized:
            startSession()
        @unknown default:
            break
        }
    }
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            
            // Input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                print("Default video device is unavailable.")
                self.session.commitConfiguration()
                return
            }
            
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                if self.session.canAddInput(videoDeviceInput) {
                    self.session.addInput(videoDeviceInput)
                }
            } catch {
                print("Couldn't create video device input: \(error)")
                self.session.commitConfiguration()
                return
            }
            
            // Output
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                self.photoOutput.isHighResolutionCaptureEnabled = true
            }
            
            self.session.commitConfiguration()
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?, Error?) -> Void) {
        print("CameraService: capturePhoto called")
        guard session.isRunning else {
            print("CameraService: Session not running")
            completion(nil, NSError(domain: "CameraService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Camera session not running"]))
            return
        }
        
        self.photoCaptureCompletionBlock = completion
        
        let photoSettings = AVCapturePhotoSettings()
        print("CameraService: Requesting capture...")
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("CameraService: didFinishProcessingPhoto called")
        if let error = error {
            print("CameraService: Photo capture error: \(error)")
            self.photoCaptureCompletionBlock?(nil, error)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            self.photoCaptureCompletionBlock?(nil, NSError(domain: "CameraService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not process photo data"]))
            return
        }
        
        // Fix orientation if needed (UIImage from data usually handles this, but sometimes needs help)
        // For simplicity, we return the image as is.
        self.photoCaptureCompletionBlock?(image, nil)
    }
}
