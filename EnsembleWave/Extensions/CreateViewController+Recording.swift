//
//  CreateViewController+Recording.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/16.
//

import UIKit
import AVFoundation
import MediaPlayer
extension CreateViewController: AVCaptureFileOutputRecordingDelegate {
    func configure(for style: Int) {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .allowBluetooth, .defaultToSpeaker])
            try audioSession.setActive(true)
            print("Audio session is set to allow mixing with other apps.")
        } catch {
            print("Failed to set audio session category: \(error)")
        }
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        if style == 1 && players.count > 2 {
            players = Array(players.prefix(2))
        }
        
        for index in 0...style {
            if index == 1 && ensembleVideoURL != nil {
                guard let url = URL(string: ensembleVideoURL!) else {
                    print("no ensembleVideoURL")
                    return
                }
                print("ensembleVideoURL:\(url)")
                let player = AVPlayer(url: url)
                if players.count <= index {
                    players.append(player)
                } else {
                    players[index] = player
                }
                if let currentItem = player.currentItem {
                    setupObserversForPlayerItem(currentItem, with: player)
                }
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = videoViews[index].bounds
                playerLayer.videoGravity = .resizeAspectFill
                videoViews[index].layer.addSublayer(playerLayer)
                if playerLayers.count <= index {
                    playerLayers.append(playerLayer)
                } else {
                    playerLayers[index] = playerLayer
                }
                //                let playerItem = AVPlayerItem(url: URL(string: url)!)
                //                players[index].replaceCurrentItem(with: playerItem)
                player.play()
            } else if index < players.count {
                if let videoURL = getVideoURL(for: index) {
                    let playerItem = AVPlayerItem(url: videoURL)
                    players[index].replaceCurrentItem(with: playerItem)
                    setupObserversForPlayerItem(playerItem, with: players[index])
                    print("In configure, players[\(players[index])] playerItem:\(playerItem)")
                }
            } else {
                let player = AVPlayer()
                players.append(player)
                if let currentItem = player.currentItem {
                    setupObserversForPlayerItem(currentItem, with: player)
                }
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = videoViews[index].bounds
                playerLayer.videoGravity = .resizeAspectFill
                videoViews[index].layer.addSublayer(playerLayer)
                playerLayers.append(playerLayer)
            }
            print("playerLayer count:\(playerLayers.count)")
        }
        
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
        guard let frontDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let backDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get the camera device")
            return
        }
        
        devices.append(frontDevice)
        devices.append(backDevice)
        currentDevice = devices[0]
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: currentDevice) else {
            print("Failed to set the camera input")
            return
        }
        
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        if captureSession.canAddInput(captureDeviceInput) {
            captureSession.addInput(captureDeviceInput)
        }
        
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            print("Failed to get the audio device")
            return
        }
        
        guard let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
            print("Failed to create audio input")
            return
        }
        
        if captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }
        
        if videoFileOutput == nil {
            videoFileOutput = AVCaptureMovieFileOutput()
            if captureSession.canAddOutput(videoFileOutput) {
                captureSession.addOutput(videoFileOutput)
            }
        }
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        if style == 0 {
            postProductionView.isHidden = true
            if let cameraPreviewLayer = cameraPreviewLayer {
                containerView.layer.addSublayer(cameraPreviewLayer)
                cameraPreviewLayer.frame = containerView.layer.bounds
            } else {
                print("no cameraPreviewLayer")
            }
        } else if style == 1 {
            // 在 chooseView() 畫 cameraPreviewLayer
            postProductionView.isHidden = false
        }
        containerView.clipsToBounds = true
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }

    func startRecording() {
        recSettings.isRecording = true
        toggleRecordingButtons(isRecording: recSettings.isRecording)
        startCountdownTimer()
        cameraButton.setBackgroundImage(UIImage(named: "stopButton"), for: .normal)
        if recSettings.style == 0 {
            if let cameraPreviewLayer = cameraPreviewLayer {
                videoViews[0].layer.addSublayer(cameraPreviewLayer)
                cameraPreviewLayer.frame = videoViews[0].bounds
            }
        } else {
            replayVideo()
        }
        
        let outputPath = NSTemporaryDirectory() + "output\(recSettings.currentRecordingIndex).mov"
        outputFileURL = URL(fileURLWithPath: outputPath)
        
        if let outputFileURL = outputFileURL {
            self.playMusic()
            videoFileOutput?.startRecording(to: outputFileURL, recordingDelegate: self)
        }
    }

    @IBAction func capture(sender: AnyObject) {
        if !recSettings.isRecording { // 不在錄影有分兩種，一種是還沒開始，一種是倒數計時被取消錄影
            if timerBeforePlay != nil { // 倒數計時被取消錄影
                stopCountdwonBeforeRecording()
                toggleRecordingButtons(isRecording: false)
                if useHandPoseStartRecording {
                    addGestureRecognitionToSession()
                }
            } else {// 還沒開始
                if useHandPoseStartRecording {
                    disableGestureRecognition()
                }
                if countBeforeRecording { // 要倒數計時
                    startCountdown()
                } else { // 不要倒數計時
                    startRecording()
                }
            }
        } else { // 正在錄影
            stopCountdownTimer()
            cameraButton.setBackgroundImage(UIImage(named: "recordingButton"), for: .normal)
            cameraButton.layer.removeAllAnimations()
            videoFileOutput?.stopRecording()
            recSettings.isRecording = false
            toggleRecordingButtons(isRecording: recSettings.isRecording)
        }
    }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        guard error == nil else {
            print(error ?? "")
            return
        }
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        playerVolume = previousVolume
        musicPlayer?.pause()
        audioPlayer?.pause()
        print("didFinishRecording，previousVolume:\(previousVolume)")
        
        let alertViewController = UIAlertController(title: "影片錄製成功？", message: "", preferredStyle: .alert)
        let successAction = UIAlertAction(title: "OK", style: .default) { _ in
            self.playAllVideos()
            self.launchTrimTopView()
        }
        let againAction = UIAlertAction(title: "重來", style: .cancel) { _ in
            if self.useHandPoseStartRecording {
                self.addGestureRecognitionToSession()
            }
            self.recordingTopView.countdownLabel.text = TimeFormatter.format(seconds: self.recSettings.length)
            self.clearVideoView(for: self.recSettings.currentRecordingIndex)
            self.chooseView(self.chooseViewButtons[self.recSettings.currentRecordingIndex])
        }
        alertViewController.addAction(successAction)
        alertViewController.addAction(againAction)
        present(alertViewController, animated: true)
    }
    @objc func clearVideoView(for index: Int) {
        if recSettings.style == 0 {
            replayButton.isHidden = true
        } else {
            let otherIndex = index == 0 ? 1 : 0
            if let hasContent = videoViewHasContent[otherIndex], hasContent {
                replayButton.isHidden = false
            } else {
                replayButton.isHidden = true
            }
        }
        print("=====status of replayButton isHidden: \(replayButton.isHidden)==========")
        if let tapGesture = videoViews[index].gestureRecognizers?.first(where: { $0 is UITapGestureRecognizer }) {
                videoViews[index].removeGestureRecognizer(tapGesture)
        }
        let player = players[index]
        stopAllVideos()
        player.replaceCurrentItem(with: nil)
        print("index: \(index), currentItem: \(player.currentItem ?? nil)")
        playerLayers[index].removeFromSuperlayer()
        if let url = getVideoURL(for: index) {
            do {
                try FileManager.default.removeItem(at: url)
                print("成功清除影片檔案")
                self.videoViewHasContent[index] = false
                print(" self.videoViewHasContent[self.recSettings.currentRecordingIndex] :\(self.videoViewHasContent[self.recSettings.currentRecordingIndex] )")
            } catch {
                print("清除影片檔案失敗: \(error)")
            }
        } else if index == 0 {
            if let url = video0URL {
                do {
                    try FileManager.default.removeItem(at: url)
                    print("成功清除影片檔案")
                    self.videoViewHasContent[index] = false
                } catch {
                    print("清除影片檔案失敗: \(error)")
                }
            }
        } else if index == 1 {
            if let url = video1URL {
                do {
                    try FileManager.default.removeItem(at: url)
                    print("成功清除影片檔案")
                    self.videoViewHasContent[index] = false
                } catch {
                    print("清除影片檔案失敗: \(error)")
                }
            }
        } else {
            self.videoViewHasContent[index] = false
        }
        print("clearViewView videoViewHasContent- index:\(index), videoViewHasContent:\(self.videoViewHasContent[index])")
        videoViews[index].subviews.forEach { subview in
            if let button = subview as? UIButton, chooseViewButtons.contains(button) {
                button.isHidden = false
            }
        }
    }
    // 刪除重錄回到有+的畫面
    @objc func prepareRecording(for index: Int) {
        //        configure(for: style)
        chooseViewButtons[index].isHidden = false
    }
    
    func playAllVideos() {
        if recSettings.style == 0 {
            self.cameraPreviewLayer?.removeFromSuperlayer()
        } else {
            if let cameraPreviewLayer = cameraPreviewLayer {
                if !cameraPreviewLayer.isPreviewing {
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
        
        videoURLs.removeAll()
        for (index, player) in players.enumerated() {
            print("index:\(index),player:\(player)")
            let playerLayer = playerLayers[index]
            if index == 1 && ensembleUserID != nil { // 1 且有合奏影片
                guard let url = URL(string: ensembleVideoURL!) else {
                    print("ensembleUserID 轉換失敗")
                    return
                }
                videoURLs.append(url)
                let playerItem = AVPlayerItem(url: url)
                player.replaceCurrentItem(with: playerItem)
                setupObserversForPlayerItem(playerItem, with: player)
            } else {
                if let url = (index == 0 ? video0URL : video1URL) {
                    videoURLs.append(url)
                    let playerItem = AVPlayerItem(url: url)
                    player.replaceCurrentItem(with: playerItem)
                    setupObserversForPlayerItem(playerItem, with: player)
                } else {
                    if let videoURL = getVideoURL(for: index) {
                        videoURLs.append(videoURL)
                        let playerItem = AVPlayerItem(url: videoURL)
                        player.replaceCurrentItem(with: playerItem)
                        setupObserversForPlayerItem(playerItem, with: player)
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
    
    @objc func replayVideo() {
        playAllVideos()
        for player in self.players {
            player.seek(to: .zero)
            player.play()
            replayButton.isHidden = true
        }
    }
    func stopAllVideos() {
        for player in players {
            player.pause()
        }
        musicPlayer?.pause()
        audioPlayer?.pause()
    }
}

