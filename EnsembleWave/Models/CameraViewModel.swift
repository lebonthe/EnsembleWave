//
//  CameraViewModel.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/23.
//

import AVFoundation

class CameraViewModel {
    private var cameraSessionManager: CameraSessionManager
    private let recordingManager: RecordingManager
    
    var isFrontCamera: Bool {
        get { return cameraSessionManager.isFrontCamera }
        set { cameraSessionManager.isFrontCamera = newValue }
    }
    
    var captureSession: AVCaptureSession {
        return cameraSessionManager.captureSession
    }
    
    var devices: [AVCaptureDevice] {
        get { return cameraSessionManager.devices }
        set { cameraSessionManager.devices = newValue }
    }
    
    var currentDevice: AVCaptureDevice? {
        get { return cameraSessionManager.currentDevice }
        set { cameraSessionManager.currentDevice = newValue }
    }
    
    init(cameraSessionManager: CameraSessionManager, recordingManager: RecordingManager) {
        self.cameraSessionManager = cameraSessionManager
        self.recordingManager = recordingManager
        self.cameraSessionManager.setupDevices()
    }
    
    func configureSessionWithNewInput(_ newInput: AVCaptureDeviceInput) {
        cameraSessionManager.configureSessionWithNewInput(newInput)
    }
    
    func startRecording(to url: URL, recordingDelegate: AVCaptureFileOutputRecordingDelegate) {
        recordingManager.startRecording(to: url, recordingDelegate: recordingDelegate)
    }
    
    func stopRecording() {
        recordingManager.stopRecording()
    }
}
