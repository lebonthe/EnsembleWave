//
//  PlayerControlUtility.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/17.
//

import UIKit
import AVFoundation
import MediaPlayer
class PlayerControlUtility {
    func playAllVideos(players: [AVPlayer],
                       playerLayers: [AVPlayerLayer],
                       videoViews: [UIView],
                       recSettings: inout RecordingSettings,
                       cameraPreviewLayer: AVCaptureVideoPreviewLayer?,
                       video0URL: URL?,
                       video1URL: URL?,
                       videoURLs: inout [URL],
                       ensembleVideoURL: String?,
                       playerVolume: Float,
                       replayButton: UIButton,
                       viewModel: CreateViewModel) {
        if recSettings.style == 0 {
            cameraPreviewLayer?.removeFromSuperlayer()
        } else {
            if let cameraPreviewLayer = cameraPreviewLayer {
                if !cameraPreviewLayer.isPreviewing {
                    print("isPreviewing:\(cameraPreviewLayer.isPreviewing)")
                    cameraPreviewLayer.removeFromSuperlayer()
                }
            }
            if recSettings.isRecording {
                adjustVolumeForRecording()
            } else {Cannot find 'adjustVolumeForRecording' in scope
                MPVolumeView.setVolume(playerVolume)
                print("set playerVolume:\(playerVolume)")
            }
        }
        
        videoURLs.removeAll()
        for (index, player) in players.enumerated() {
            print("index:\(index),player:\(player)")
            let playerLayer = playerLayers[index]
            if index == 1 && ensembleVideoURL/*ensembleUserID*/ != nil { // 1 且有合奏影片
                guard let url = URL(string: ensembleVideoURL!) else {
                    print("ensembleUserID 轉換失敗")
                    return
                }
                videoURLs.append(url)
                let playerItem = AVPlayerItem(url: url)
                player.replaceCurrentItem(with: playerItem)
                viewModel.setupObserversForPlayerItem(playerItem, with: player)
            } else {
                if let url = (index == 0 ? video0URL : video1URL) {
                    videoURLs.append(url)
                    let playerItem = AVPlayerItem(url: url)
                    player.replaceCurrentItem(with: playerItem)
                    viewModel.setupObserversForPlayerItem(playerItem, with: player)
                } else {
                    if let videoURL = getVideoURL(for: index) {
                        videoURLs.append(videoURL)
                        let playerItem = AVPlayerItem(url: videoURL)
                        player.replaceCurrentItem(with: playerItem)
                        viewModel.setupObserversForPlayerItem(playerItem, with: player)
                    }
                }
            }
            player.play()
            recSettings.isPlaying = true
            if recSettings.style == 0 {
                videoViews[0].layer.addSublayer(playerLayer)
                playerLayer.frame = videoViews[0].bounds
            } else {
                videoViews[index].layer.addSublayer(playerLayer)
                playerLayer.frame = videoViews[index].bounds
            }
            playerLayer.videoGravity = .resizeAspectFill
        }
        
        replayButton.isHidden = true
    }
}
