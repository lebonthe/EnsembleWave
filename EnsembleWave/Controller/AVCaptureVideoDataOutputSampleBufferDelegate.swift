//
//  AVCaptureVideoDataOutputSampleBufferDelegate.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/20.
//

import UIKit
import AVFoundation
import Vision

extension CreateViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([handPoseRequest])
            guard let observation = handPoseRequest.results?.first else {
                return
            }

            let indexFingerPoints = try observation.recognizedPoints(.indexFinger)
            let littleFingerPoints = try observation.recognizedPoints(.littleFinger)
            let wristPoints = try observation.recognizedPoints(.all)
            let middleFingerPoints = try observation.recognizedPoints(.middleFinger)
            let ringFingerPoints = try observation.recognizedPoints(.ringFinger)
            print("index:\(indexFingerPoints), little:\(littleFingerPoints), wrist:\(wristPoints), middle:\(middleFingerPoints), ring:\(ringFingerPoints)")
            guard let indexTipPoint = indexFingerPoints[.indexTip],
                  let middleTipPoint = middleFingerPoints[.middleTip],
                  let ringTipPoint = ringFingerPoints[.ringTip],
                  let littleTipPoint = littleFingerPoints[.littleTip],
                  let wristPoint = wristPoints[.wrist] else {
                return
            }

            let confidenceThreshold: Float = 0.6
            if indexTipPoint.confidence > confidenceThreshold &&
               littleTipPoint.confidence > confidenceThreshold &&
               wristPoint.confidence > confidenceThreshold {

                if isRockOnGesture(indexTip: indexTipPoint.location, littleTip: littleTipPoint.location, wrist: wristPoint.location, middleTip: middleTipPoint.location, ringTip: ringTipPoint.location) {
                    DispatchQueue.main.async {
                        self.capture(sender: NSObject())
                    }
                }
            }
        } catch {
            print("Failed to perform HandPoseRequest: \(error)")
        }
    }
    
    func isRockOnGesture(indexTip: CGPoint, littleTip: CGPoint, wrist: CGPoint, middleTip: CGPoint, ringTip: CGPoint) -> Bool {
        let indexYDistance = abs(wrist.y - indexTip.y)
        let littleYDistance = abs(wrist.y - littleTip.y)
        let middleYDistance = abs(wrist.y - middleTip.y)
        let ringYDistance = abs(wrist.y - ringTip.y)
        let xDistance = abs(littleTip.x - indexTip.x)

        let verticalThreshold = 0.03
        let horizontalThreshold = 0.01
        let verticalSmallThreshold = 0.15
        print("indexYDistance > verticalThreshold: \(indexYDistance > verticalThreshold)")
        print("littleYDistance > verticalThreshold: \(littleYDistance > verticalThreshold)")
        print("middleYDistance < verticalSmallThreshold: \(middleYDistance < verticalSmallThreshold)")
        print("ringYDistance < verticalSmallThreshold: \(ringYDistance < verticalSmallThreshold)")
        print("xDistance > horizontalThreshold: \(xDistance > horizontalThreshold)")
        print("是否為 Rock On: \(indexYDistance > verticalThreshold && littleYDistance > verticalThreshold && middleYDistance < verticalSmallThreshold && ringYDistance < verticalSmallThreshold && xDistance > horizontalThreshold)")
        return indexYDistance > verticalThreshold && littleYDistance > verticalThreshold && middleYDistance < verticalSmallThreshold && ringYDistance < verticalSmallThreshold && xDistance > horizontalThreshold
    }

    func addGestureRecognitionToSession() {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32BGRA)]
        videoOutput.alwaysDiscardsLateVideoFrames = true

        let videoOutputQueue = DispatchQueue(label: "VideoOutputQueue")
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            print("Could not add video output for gesture recognition")
        }
    }
}
