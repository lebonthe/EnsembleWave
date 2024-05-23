//
//  CameraSessionManager.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/23.
//

import AVFoundation

protocol CameraSessionManager {
    var currentDevice: AVCaptureDevice? { get set }
    var devices: [AVCaptureDevice] { get set }
    var captureSession: AVCaptureSession { get }
    var isFrontCamera: Bool { get set }
    func configureSessionWithNewInput(_ newInput: AVCaptureDeviceInput)
    func setupDevices()
}

class DefaultCameraSessionManager: CameraSessionManager {
    var currentDevice: AVCaptureDevice?
    var devices: [AVCaptureDevice] = []
    var captureSession: AVCaptureSession = AVCaptureSession()
    
    var isFrontCamera =  Bool() {
        didSet {
            currentDevice = isFrontCamera ? devices[0] : devices[1]
            guard let newInput = try? AVCaptureDeviceInput(device: currentDevice!) else {
                print("Unable to create input from the device.")
                return
            }
            configureSessionWithNewInput(newInput)
        }
    }
    
    func configureSessionWithNewInput(_ newInput: AVCaptureDeviceInput) {
        captureSession.beginConfiguration()
        for input in captureSession.inputs {
            if let deviceInput = input as? AVCaptureDeviceInput, deviceInput.device.hasMediaType(.video) {
                captureSession.removeInput(deviceInput)
            }
        }
        if captureSession.canAddInput(newInput) {
            captureSession.addInput(newInput)
        } else {
            print("Can't add new video input to the session.")
        }
        captureSession.commitConfiguration()
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    func setupDevices() {
        guard let frontDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let backDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get the camera device")
            return
        }
        devices.append(frontDevice)
        devices.append(backDevice)
        currentDevice = devices[0]
    }
}
