//
//  RecordingManager.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/23.
//

import AVFoundation

protocol RecordingManager {
    var videoFileOutput: AVCaptureMovieFileOutput? { get set }
    func setCaptureSession(_ session: AVCaptureSession)
    func startRecording(to url: URL, recordingDelegate: AVCaptureFileOutputRecordingDelegate)
    func stopRecording()
}

class DefaultRecordingManager: RecordingManager {
    var videoFileOutput: AVCaptureMovieFileOutput?
    private var captureSession: AVCaptureSession?
    
    func setCaptureSession(_ session: AVCaptureSession) {
        self.captureSession = session
    }
    
    func startRecording(to url: URL, recordingDelegate: AVCaptureFileOutputRecordingDelegate) {
        videoFileOutput = AVCaptureMovieFileOutput()
        
        guard let captureSession = captureSession else {
            print("No capture session available")
            return
        }
        
        if captureSession.canAddOutput(videoFileOutput!) {
            captureSession.addOutput(videoFileOutput!)
            videoFileOutput?.startRecording(to: url, recordingDelegate: recordingDelegate)
        } else {
            print("Can't add video output to the session.")
        }
    }
    
    func stopRecording() {
        videoFileOutput?.stopRecording()
    }
}
