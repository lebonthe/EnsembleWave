//
//  CreateViewController+UI.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/15.
//

import UIKit
import AVFoundation
import Lottie
extension CreateViewController {
    func setupUI(_ style: Int) {
        let headphoneText = "未偵測到耳機，播放時不會播放聲音"/*"Headphones are not detected, sound cannot be played during recording!"*/
        headphoneAlertLabel.attributedText = attributedTextForm(content: headphoneText, size: 15, kern: 0, color: CustomColor.red ?? .red)
        headphoneAlertLabel.numberOfLines = 0
        cameraButton.tintColor = CustomColor.red
        albumButton.tintColor = .white
        musicButton.tintColor = .white
        stretchScreenButton.tintColor = .white
        shrinkScreenButton.tintColor = .white
        view.backgroundColor = .black
        trimView.isHidden = true
        videoViews.forEach { $0.removeFromSuperview() }
        videoViews.removeAll()
        players.removeAll()
        playerLayers.removeAll()
        print("style in setupUI: \(style)")
        containerView.layer.borderColor = UIColor.white.cgColor
        containerView.layer.borderWidth = 2
        containerView.layer.cornerRadius = 10
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerViewLeadingConstraint.constant = 16
        containerViewTrailingConstraint.constant = -16
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50)
        ])
        for _ in 0...style {
            let videoView = UIView()
            videoView.backgroundColor = CustomColor.mattBlack
            containerView.addSubview(videoView)
            videoViews.append(videoView)
        }
        trimView.translatesAutoresizingMaskIntoConstraints = false
        videoViews[0].translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            trimView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            trimView.heightAnchor.constraint(equalToConstant: 200),
            trimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trimView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        if style == 0 {
            videoViewHasContent[0] = false
            videoViews[0].tag = 0
            if let hasContent = videoViewHasContent[0], hasContent {
                videoViews[0].addGestureRecognizer(tapGesture00)
            }
            videoViews[0].isUserInteractionEnabled = true
            videoViews[0].frame = containerView.bounds
            let startButton = UIButton()
            chooseViewButtons.append(startButton)
            videoViews[0].addSubview(chooseViewButtons[0])
            chooseViewButtons[0].setBackgroundImage(UIImage(systemName: "plus"), for: .normal)
            chooseViewButtons[0].translatesAutoresizingMaskIntoConstraints = false
            chooseViewButtons[0].tintColor = .white
            chooseViewButtons[0].addTarget(self, action: #selector(startToRecordingView), for: .touchDown)
            NSLayoutConstraint.activate([
                videoViews[0].topAnchor.constraint(equalTo: containerView.topAnchor),
                videoViews[0].leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                videoViews[0].trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                videoViews[0].bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                chooseViewButtons[0].centerXAnchor.constraint(equalTo: videoViews[0].centerXAnchor),
                chooseViewButtons[0].centerYAnchor.constraint(equalTo: videoViews[0].centerYAnchor),
                chooseViewButtons[0].widthAnchor.constraint(equalToConstant: 40),
                chooseViewButtons[0].heightAnchor.constraint(equalToConstant: 40)
            ])
        } else if style == 1 {
            videoViewHasContent[0] = false
            videoViewHasContent[1] = false
            for (index, videoView) in videoViews.enumerated() {
                videoView.tag = index
                videoView.isUserInteractionEnabled = true
                if let hasContent = videoViewHasContent[index], hasContent {
                    if index == 0 {
                        videoView.addGestureRecognizer(tapGesture00)
                    } else if index == 1 {
                        videoView.addGestureRecognizer(tapGesture01)
                    }
                }
            }
            line.backgroundColor = .white
            containerView.addSubview(line)
            
            let button0 = UIButton()
            let button1 = UIButton()
            chooseViewButtons.append(button0)
            chooseViewButtons.append(button1)
            containerView.addSubview(chooseViewButtons[0])
            containerView.addSubview(chooseViewButtons[1])
            chooseViewButtons[0].setBackgroundImage(UIImage(systemName: "plus"), for: .normal)
            chooseViewButtons[1].setBackgroundImage(UIImage(systemName: "plus"), for: .normal)
            chooseViewButtons[0].translatesAutoresizingMaskIntoConstraints = false
            chooseViewButtons[1].translatesAutoresizingMaskIntoConstraints = false
            chooseViewButtons[0].tintColor = .white
            chooseViewButtons[1].tintColor = .white
            videoViews[1].translatesAutoresizingMaskIntoConstraints = false
            line.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                line.widthAnchor.constraint(equalToConstant: 2),
                line.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                line.topAnchor.constraint(equalTo: containerView.topAnchor),
                line.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                videoViews[0].topAnchor.constraint(equalTo: containerView.topAnchor),
                videoViews[0].leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                videoViews[0].trailingAnchor.constraint(equalTo: line.leadingAnchor),
                videoViews[0].bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                videoViews[1].topAnchor.constraint(equalTo: containerView.topAnchor),
                videoViews[1].leadingAnchor.constraint(equalTo: line.trailingAnchor),
                videoViews[1].trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                videoViews[1].bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                chooseViewButtons[0].centerXAnchor.constraint(equalTo: videoViews[0].centerXAnchor),
                chooseViewButtons[0].centerYAnchor.constraint(equalTo: videoViews[0].centerYAnchor),
                chooseViewButtons[0].widthAnchor.constraint(equalToConstant: 40),
                chooseViewButtons[0].heightAnchor.constraint(equalToConstant: 40),
                chooseViewButtons[1].centerXAnchor.constraint(equalTo: videoViews[1].centerXAnchor),
                chooseViewButtons[1].centerYAnchor.constraint(equalTo: videoViews[1].centerYAnchor),
                chooseViewButtons[1].widthAnchor.constraint(equalToConstant: 40),
                chooseViewButtons[1].heightAnchor.constraint(equalToConstant: 40)
            ])
            for chooseViewButton in chooseViewButtons {
                chooseViewButton.addTarget(self, action: #selector(chooseView(_:)), for: .touchDown)
            }
        }
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        stretchScreenButton.translatesAutoresizingMaskIntoConstraints = false
        shrinkScreenButton.translatesAutoresizingMaskIntoConstraints = false
        postProductionView.translatesAutoresizingMaskIntoConstraints = false
        albumButton.translatesAutoresizingMaskIntoConstraints = false
        musicButton.translatesAutoresizingMaskIntoConstraints = false
        postProductionView.backgroundColor = .black
        
        NSLayoutConstraint.activate([
            cameraButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            cameraButton.heightAnchor.constraint(equalToConstant: 60),
            cameraButton.widthAnchor.constraint(equalToConstant: 60),
            albumButton.centerYAnchor.constraint(equalTo: cameraButton.centerYAnchor),
            albumButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            albumButton.heightAnchor.constraint(equalTo: cameraButton.heightAnchor, multiplier: 0.6),
            albumButton.widthAnchor.constraint(equalTo: cameraButton.widthAnchor, multiplier: 0.6),
            musicButton.leadingAnchor.constraint(equalTo: albumButton.trailingAnchor, constant: 15),
            musicButton.centerYAnchor.constraint(equalTo: cameraButton.centerYAnchor),
            musicButton.heightAnchor.constraint(equalTo: cameraButton.heightAnchor, multiplier: 0.6),
            musicButton.widthAnchor.constraint(equalTo: cameraButton.widthAnchor, multiplier: 0.6),
            stretchScreenButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            stretchScreenButton.centerYAnchor.constraint(equalTo: cameraButton.centerYAnchor),
            stretchScreenButton.heightAnchor.constraint(equalTo: cameraButton.heightAnchor, multiplier: 0.5),
            stretchScreenButton.widthAnchor.constraint(equalTo: cameraButton.widthAnchor, multiplier: 0.5),
            shrinkScreenButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            shrinkScreenButton.centerYAnchor.constraint(equalTo: cameraButton.centerYAnchor),
            shrinkScreenButton.heightAnchor.constraint(equalTo: cameraButton.heightAnchor, multiplier: 0.5),
            shrinkScreenButton.widthAnchor.constraint(equalTo: cameraButton.widthAnchor, multiplier: 0.5),
            postProductionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 8),
            postProductionView.heightAnchor.constraint(equalToConstant: 80),
            postProductionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            postProductionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        shrinkScreenButton.isHidden = true
        view.addSubview(countdownImageView)
        countdownImageView.layer.cornerRadius = 50
        countdownImageView.clipsToBounds = true
        countdownImageView.tintColor = CustomColor.red
        countdownImageView.backgroundColor = .white
        NSLayoutConstraint.activate([
            countdownImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            countdownImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            countdownImageView.heightAnchor.constraint(equalToConstant: 100),
            countdownImageView.widthAnchor.constraint(equalToConstant: 100)
        ])
        countdownImageView.isHidden = true
    }
    func setupReplayButton() {
        replayButton.setBackgroundImage(UIImage(systemName: "play.circle"), for: .normal)
        replayButton.addTarget(self, action: #selector(replayVideo), for: .touchDown)
        containerView.addSubview(replayButton)
        replayButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            replayButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            replayButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            replayButton.widthAnchor.constraint(equalToConstant: 50),
            replayButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        replayButton.isHidden = true
    }
    @IBAction func toggleScreenSize(sender: UIButton) {
        if recSettings.style == 0 {
            if sender == stretchScreenButton {
                stretchScreenButton.isHidden = true
                shrinkScreenButton.isHidden = false
                self.containerViewLeadingConstraint.constant = 0
                self.containerViewTrailingConstraint.constant = 0
                UIView.animate(withDuration: 0.5) {
                    self.view.layoutIfNeeded()
                    self.cameraPreviewLayer?.frame = self.containerView.bounds
                }
            } else {
                stretchScreenButton.isHidden = false
                shrinkScreenButton.isHidden = true
                self.containerViewLeadingConstraint.constant = 16
                self.containerViewTrailingConstraint.constant = -16
                UIView.animate(withDuration: 0.5) {
                    self.view.layoutIfNeeded()
                }
            }
        } else if recSettings.style == 1 {
            if sender == stretchScreenButton {
                stretchScreenButton.isHidden = true
                shrinkScreenButton.isHidden = false
                self.containerViewLeadingConstraint.constant = 0
                self.containerViewTrailingConstraint.constant = 0
                UIView.animate(withDuration: 0.5) {
                    self.view.layoutIfNeeded()
                    self.cameraPreviewLayer?.frame = self.videoViews[self.recSettings.currentRecordingIndex].bounds
                }
            } else {
                stretchScreenButton.isHidden = false
                shrinkScreenButton.isHidden = true
                self.containerViewLeadingConstraint.constant = 16
                self.containerViewTrailingConstraint.constant = -16
                UIView.animate(withDuration: 0.5) {
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
    func setupTrimView() {
        stopCountdownTimer()
        postProductionView.isHidden = false
        if recSettings.style > 0 {
            let otherIndex = recSettings.currentRecordingIndex == 0 ? 1 : 0
            chooseViewButtons[otherIndex].isHidden = true
        }
        let trimOKButton = UIBarButtonItem(image: UIImage(systemName: "checkmark.circle.fill"), style: .plain, target: self, action: #selector(preparedToShare))
        let trimCancelButton = UIBarButtonItem(image: UIImage(systemName: "xmark.circle.fill"), style: .plain, target: self, action: #selector(recordAgain))
        self.navigationItem.rightBarButtonItem = trimOKButton
        self.navigationItem.leftBarButtonItem = trimCancelButton
        var videoFileURL: URL?
        if recSettings.style == 1 && ensembleVideoURL != nil {
            guard let url = URL(string: ensembleVideoURL!) else {
                print("no ensembleVideoURL")
                return
            }
            videoFileURL = url
        } else {
            if recSettings.currentRecordingIndex == 0 && video0URL != nil {
                if let video0URL = video0URL {
                    videoFileURL = video0URL
                }
            } else if recSettings.currentRecordingIndex == 1 && video1URL != nil {
                if let video1URL = video1URL {
                    videoFileURL = video1URL
                }
            } else {
                guard let url = getVideoURL(for: recSettings.currentRecordingIndex) else {
                    print("在 setupTrimView 內 getVideoURL 失敗")
                    return
                }
                videoFileURL = url
            }
        }
        guard let videoFileURL = videoFileURL else {
            return
        }
        
        let asset = AVAsset(url: videoFileURL)
        trimView.configure(with: asset)
        trimView.isHidden = false
        trimView.videoTrim.delegate = self
    }
    // 按左上角x
    @objc func resetView() {
        stopCountdwonBeforeRecording()
        recordingTopView.isHidden = true
        postProductionView.isHidden = false
        trimView.isHidden = true
        cameraPreviewLayer?.removeFromSuperlayer()
        for chooseViewButton in chooseViewButtons {
            chooseViewButton.isHidden = false
        }
        if players.count > 1 {
            if let hasContent = videoViewHasContent[0], hasContent {
                chooseViewButtons[0].isHidden = true
                replayButton.isHidden = false
                if (videoViews[0].gestureRecognizers?.first(where: { $0 is UITapGestureRecognizer })) != nil {
                    videoViews[0].isUserInteractionEnabled = true
                } else {
                    videoViews[0].addGestureRecognizer(tapGesture00)
                }
            }
            if let hasContent = videoViewHasContent[1], hasContent {
                chooseViewButtons[1].isHidden = true
                replayButton.isHidden = false
                if (videoViews[1].gestureRecognizers?.first(where: { $0 is UITapGestureRecognizer })) != nil {
                    videoViews[1].isUserInteractionEnabled = true
                } else {
                    videoViews[1].addGestureRecognizer(tapGesture01)
                }
            }
        }
        stopAllVideos()
        playAllVideos()
    }
    func setupRecordingTopView() {
        guard let navigationController = navigationController else {
            print("There is no navigation controller")
            return
        }
//        countBeforeRecording = true
        useHandPoseStartRecording = false
        if let navigationController = self.navigationController, !navigationController.view.subviews.contains(recordingTopView) {
            navigationController.view.addSubview(recordingTopView)
        }
        recordingTopView.isHidden = false
        recordingTopView.translatesAutoresizingMaskIntoConstraints = false
        recordingTopView.updateCountdownLabel(recSettings.length)
        NSLayoutConstraint.activate([
            recordingTopView.topAnchor.constraint(equalTo: navigationController.view.topAnchor, constant: 30),
            recordingTopView.leadingAnchor.constraint(equalTo: navigationController.view.leadingAnchor),
            recordingTopView.trailingAnchor.constraint(equalTo: navigationController.view.trailingAnchor),
            recordingTopView.heightAnchor.constraint(equalToConstant: 50)
        ])
        recordingTopView.countdownButton.isSelected = !countBeforeRecording
        setupActions()
    }

    func mergingAnimation() {
        
        if animView == nil {
            animView = LottieAnimationView(name: "Animation02", bundle: .main)
            guard let animView = animView else {
                print("AnimView doesn't work.")
                return
            }
            animView.frame = CGRect(x: 200, y: 350, width: 300, height: 300)
            animView.center = self.view.center
            animView.loopMode = .loop
            animView.animationSpeed = 1
            self.view.addSubview(animView)
            let label = UILabel(frame: CGRect(x: Int(animView.bounds.minX + 50), y: Int(animView.bounds.midY), width: 200, height: 30))
            label.attributedText = attributedTextForm(content: "Video Processing...", size: 20, kern: 0, color: .white)
            label.textColor = .white
            animView.addSubview(label)
            animView.bringSubviewToFront(animView)
        }
        animView?.play()
    }
    
    func setupActions() {
        print("RecordingTopView: \(recordingTopView)")
        print("HandPoseButton: \(recordingTopView.handPoseButton)")
        recordingTopView.cameraPositionButton.addTarget(self, action: #selector(toggleCameraPosition(_:)), for: .touchUpInside)
        recordingTopView.cancelButton.addTarget(self, action: #selector(cancelRecording), for: .touchUpInside)
        recordingTopView.handPoseButton.addTarget(self, action: #selector(changeHandPoseMode(_:)), for: .touchUpInside)
        recordingTopView.handPoseButton.setTitle("🙅‍♀️", for: .normal)
        print("Hand Pose Button Title: \(recordingTopView.handPoseButton.title(for: .normal) ?? "nil")")
        recordingTopView.countdownButton.addTarget(self, action: #selector(changeCountdownMode(_:)), for: .touchDown)
        }
    
    func setupShareButton() {
        trimView.isHidden = true
        let shareButton = UIBarButtonItem(title: "分享", style: .plain, target: self, action: #selector(pushSharePage(_:)))
        self.navigationItem.rightBarButtonItem = shareButton
        self.navigationItem.leftBarButtonItem = nil
    }
}
