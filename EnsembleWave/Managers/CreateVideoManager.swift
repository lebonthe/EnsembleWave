//
//  CreateVideoManager.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/16.
//

import AVFoundation
import UIKit

class CreateVideoManager {
    static let shared = CreateVideoManager()
    
    private init() {}
    
    func exportCroppedVideo(asset: AVAsset, startTime: CMTime, endTime: CMTime, outputURL: URL, completion: @escaping (Bool) -> Void) {
        print("asset.tracks:\(asset.tracks)")
        guard asset.tracks(withMediaType: .video).first != nil else {
            print("導出失敗: 沒有找到 video track")
            completion(false)
            return
        }
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            print("導出失敗: 無法創建 exportSession")
            completion(false)
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.timeRange = CMTimeRange(start: startTime, end: endTime)
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    print("裁剪和導出成功，文件已更新")
                    completion(true)
                case .failed:
                    print("導出失敗: \(exportSession.error?.localizedDescription ?? "未知錯誤")")
                    completion(false)
                case .cancelled:
                    print("導出取消")
                    completion(false)
                default:
                    print("導出狀態未知")
                    completion(false)
                }
            }
        }
    }
    
    func mergeMedia(videoURLs: [URL], audioURLs: [URL], outputURL: URL, videoFrames: [CGRect], containerViewFrame: CGRect, completion: @escaping (Bool) -> Void) {
        let mixComposition = AVMutableComposition()
        var instructions = [AVMutableVideoCompositionLayerInstruction]()
//        var videoFrames = [CGRect]()
//        if Thread.isMainThread {
//            for videoView in self.videoViews {
//                videoFrames.append(videoView.frame)
//                print("===videoView.frame:\(videoView.frame)")
//            }
//        } else {
//            DispatchQueue.main.sync {
//                for videoView in self.videoViews {
//                    videoFrames.append(videoView.frame)
//                }
//            }
//        }
        let dispatchGroup = DispatchGroup()
        for (index, videoURL) in videoURLs.enumerated() {
            print("videoURLs.count:\(videoURLs.count)")
            print("index:\(index),videoURL:\(videoURL)")
            dispatchGroup.enter()
            let videoAsset = AVURLAsset(url: videoURL)
            guard let videoTrack = videoAsset.tracks(withMediaType: .video).first,
                  let audioTrack = videoAsset.tracks(withMediaType: .audio).first else {
                continue
            }
            print("Video Track Count: \(videoAsset.tracks(withMediaType: .video).count)")
            print("Audio Track Count: \(videoAsset.tracks(withMediaType: .audio).count)")
            videoAsset.loadTracks(withMediaType: .video) { tracks, error in
                
                guard let videoTrack = tracks?.first
                else {
                    dispatchGroup.leave()
                    return
                }
                print("videoTrack:\(videoTrack)")
                print("Preferred Transform: \(videoTrack.preferredTransform)")
                
                do {
                    if let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
                        print("Video track added successfully.")
                        try compositionVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoAsset.duration), of: videoTrack, at: .zero)
                        if let compositionAudioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                            try? compositionAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoAsset.duration), of: audioTrack, at: .zero)
                        }
                        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
                        let preferredTransform = videoTrack.preferredTransform
                        let videoSize = videoTrack.naturalSize
                        print("videoSize:\(videoSize)") // (1280, 720)
                        let videoFrame = videoFrames[index] // (0.0, 0.0, 170.5, 343.0), (172.5, 0.0, 170.5, 343.0)
                        let scaleToFitRatioWidth = videoFrame.size.width / videoSize.height
                        print("index:\(index),scaleToFitRatioWidth:\(scaleToFitRatioWidth)")
                        let scaleToFitRatioHeight = videoFrame.size.height / videoSize.width
                        print("index:\(index),scaleToFitRatioHeight:\(scaleToFitRatioHeight)")
                        let undoTranslation = CGAffineTransform(translationX: -videoSize.height, y: 0)
                        let transformWithUndoTranslation = preferredTransform.concatenating(undoTranslation)
                        let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatioWidth, y: scaleToFitRatioHeight)
                        let transformWithScale = transformWithUndoTranslation.concatenating(scaleFactor)
                        print("index:\(index), transformWithScale:\(transformWithScale)")
                        
                        var translation = CGAffineTransform(translationX: CGFloat(index) * videoFrame.origin.x + videoFrame.width + 2, y: videoFrame.origin.y)
                        if index == 0 {
                        } else {
                            translation.tx += 0.5
                        }
                        print("index:\(index), translation:\(translation)")
                        let finalTransform = transformWithScale.concatenating(translation)
                        print("index:\(index),finalTransform:\(finalTransform)")
                        layerInstruction.setTransform(finalTransform, at: .zero)
                        print("index:\(index),layerInstruction:\(layerInstruction)")
                        instructions.append(layerInstruction)
                        print("Current number of layerInstructions: \(instructions.count)")
                        print("Scale to fit ratio (Width): \(scaleToFitRatioWidth), (Height): \(scaleToFitRatioHeight)")
                        print("Transform applied: \(transformWithScale)")
                        print("Translation applied: \(translation)")
                        print("Final Transform: \(finalTransform)")
                    } else {
                        print("Failed to add video track.")
                    }
                } catch {
                    print("Error with inserting video into composition: \(error)")
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            print("Final instructions count: \(instructions.count)")
            let mainInstruction = AVMutableVideoCompositionInstruction()
            mainInstruction.timeRange = CMTimeRange(start: .zero, duration: mixComposition.duration)
            mainInstruction.layerInstructions = instructions
            
            print("Final video composition instructions: \(mainInstruction.layerInstructions)")
            let videoComposition = AVMutableVideoComposition()
            videoComposition.renderSize = CGSize(width: containerViewFrame.width, height: containerViewFrame.height)
            print("videoComposition.renderSize: \(videoComposition.renderSize)")
            print("videoComposition.frame:\(videoComposition)")
            videoComposition.frameDuration = CMTime(value: 1, timescale: 30) // 幀率
            videoComposition.instructions = [mainInstruction]
            guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {
                print("無法創建 ExportSession")
                completion(false)
                return
            }
            exporter.outputURL = outputURL
            exporter.outputFileType = .mov
            exporter.videoComposition = videoComposition
            print("exporter:\(exporter)")
            print("exporter.videoComposition:\(exporter.videoComposition)")
            exporter.exportAsynchronously {
                DispatchQueue.main.async {
                    print("Export Status: \(exporter.status)")
                    print("Export Session Error: \(String(describing: exporter.error))")
                    switch exporter.status {
                    case .completed:
                        print("導出完成")
                        completion(true)
                    case .failed:
                        print("導出失敗：\(exporter.error?.localizedDescription ?? "未知錯誤")")
                        completion(false)
                    default:
                        print("導出未完成")
                        completion(false)
                    }
                }
            }
        }
    }
}
