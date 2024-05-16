//
//  CreateViewController+PHPickerViewControllerDelegate.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/16.
//

import UIKit
import PhotosUI
import MediaPlayer 
extension CreateViewController: PHPickerViewControllerDelegate {
    @IBAction func selectVideo(_ sender: Any) {
        stopCountdownTimer()
        disableGestureRecognition()
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let provider = results.first?.itemProvider, provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else {
            picker.dismiss(animated: true)
            return
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { (item, error) in
                guard let url = item as? URL,
                        error == nil else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
            }
        } else {
            picker.dismiss(animated: true)
        }
        provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
            guard let url = url, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            let sandboxURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            do {
                if FileManager.default.fileExists(atPath: sandboxURL.path) {
                    try FileManager.default.removeItem(at: sandboxURL)
                }
                try FileManager.default.copyItem(at: url, to: sandboxURL)
                /* try FileManager.default.copyItem(at: url, to: URL(fileURLWithPath: NS*//*TemporaryDirectory() + "output\(self.recordingSettings.currentRecordingIndex).mov"))*/
                DispatchQueue.main.async {
                    if self.recSettings.currentRecordingIndex == 0 {
                        self.video0URL = sandboxURL
                    } else {
                        self.video1URL = sandboxURL
                    }
                    picker.dismiss(animated: true) {
                        self.playAllVideos()
                        self.launchTrimTopView()
                        if self.useHandPoseStartRecording {
                            self.addGestureRecognitionToSession()
                        }
                    }
                }
            } catch {
                print("檔案管理錯誤: \(error)")
            }
        }
    }
    // 設定相簿輸入影片的播放器
    func setupPlayer(with url: URL) {
        recordingTopView.isHidden = false
        replayButton.isHidden = true
        if recSettings.style == 0 {
            self.cameraPreviewLayer?.removeFromSuperlayer()
        } else {
            if let cameraPreviewLayer = cameraPreviewLayer {
                if cameraPreviewLayer.isPreviewing {
                    print("isPreviewing:\(cameraPreviewLayer.isPreviewing)")
                    self.cameraPreviewLayer?.removeFromSuperlayer()
                }
            }
            if recSettings.isRecording {
                adjustVolumeForRecording()
            } else {
                MPVolumeView.setVolume(playerVolume)
                print("set playerVolume:\(playerVolume)")
            }
        }
        if recSettings.style == 1 && ensembleVideoURL != nil {
            videoURLs.insert(url, at: 0)
            players[0] = AVPlayer(url: url)
            playerLayers[0] = AVPlayerLayer(player: players[recSettings.currentRecordingIndex])
            playerLayers[0].frame = videoViews[recSettings.currentRecordingIndex].bounds
            videoViews[0].layer.addSublayer(playerLayers[recSettings.currentRecordingIndex])
            playerLayers[0].videoGravity = .resizeAspectFill
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(videoDidEnd(notification:)),
                name: .AVPlayerItemDidPlayToEndTime,
                object: players[0].currentItem
            )
        } else {
            videoURLs.append(url)
            players[recSettings.currentRecordingIndex] = AVPlayer(url: url)
            playerLayers[recSettings.currentRecordingIndex] = AVPlayerLayer(player: players[recSettings.currentRecordingIndex])
            playerLayers[recSettings.currentRecordingIndex].frame = videoViews[recSettings.currentRecordingIndex].bounds
            videoViews[recSettings.currentRecordingIndex].layer.addSublayer(playerLayers[recSettings.currentRecordingIndex])
            playerLayers[recSettings.currentRecordingIndex].videoGravity = .resizeAspectFill
        }
        
        launchTrimTopView()
        for player in self.players {
            player.seek(to: CMTime.zero)
            player.play()
        }
    }
}
