//
//  CreateViewController+Camera.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/16.
//

import UIKit
import AVFoundation

extension CreateViewController {
    @objc func toggleCameraPosition(_ sender: UIBarButtonItem) {
        guard !recSettings.isRecording else {
            print("錄製中，無法切換鏡頭")
            return
        }
        isFrontCamera.toggle()
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
            captureSession.startRunning()
        }
    }
}
