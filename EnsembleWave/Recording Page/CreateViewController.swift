//
//  CreateViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/9.
//

import UIKit
import AVFoundation // 錄影
import AVKit // 播放影像
import Photos // 儲存影像

class CreateViewController: UIViewController {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var stretchScreenButton: UIButton!
    @IBOutlet weak var shrinkScreenButton: UIButton!
    var style = 0
    var length = 15
    var devices = [AVCaptureDevice]()
    var isFrontCamera: Bool = true {
        didSet {
            currentDevice = isFrontCamera ? devices[0] : devices[1]
            guard let newInput = try? AVCaptureDeviceInput(device: currentDevice) else {
                print("Unable to create input from the device.")
                return
            }
            configureSessionWithNewInput(newInput)
        }
    }
    let captureSession = AVCaptureSession()
    var currentDevice: AVCaptureDevice!
    var videoFileOutput: AVCaptureMovieFileOutput!
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var isRecording = false
    var players: [AVPlayer] = []
    var playerLayers: [AVPlayerLayer] = []
//    var player: AVPlayer?
//    var playerLayer: AVPlayerLayer?
    var replayButton = UIButton()
    @IBOutlet private var containerViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var containerViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerViewRatio: NSLayoutConstraint!
    @IBOutlet weak var headphoneAlertLabel: UILabel!
    var videoViews: [UIView] = []
//    let leftView = UIView()
//    let rightView = UIView()
    let line = UIView()
    var chooseViewButtons = [UIButton]()

    @IBOutlet weak var postProductionView: UIView!
    var outputFileURL: URL?
    var currentRecordingView = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI(style, length)
        setupReplayButton()
        bookEarphoneState()
        configurePlayersAndAddObservers()
        clearTemporaryVideos()
//        let initialCameraPosition: AVCaptureDevice.Position = isFrontCamera ? .front : .back
//            camera(initialCameraPosition)
        configure(for: style)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
    }
    func setupUI(_ style: Int, _ length: Int) {
        videoViews.forEach { $0.removeFromSuperview() }
        videoViews.removeAll()
        players.removeAll()
        playerLayers.removeAll()
        let cameraPositionButton = UIBarButtonItem(image: UIImage(systemName: "arrow.triangle.2.circlepath.camera"), style: .plain, target: self, action: #selector(toggleCameraPosition(_:)))
        self.navigationItem.rightBarButtonItem = cameraPositionButton
        print("style in setupUI: \(style)")
        containerView.layer.borderColor = UIColor.black.cgColor
        containerView.layer.borderWidth = 2
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerViewLeadingConstraint.constant = 16
        containerViewTrailingConstraint.constant = -16
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
        for index in 0...style {
            let videoView = UIView()
            videoView.backgroundColor = .systemGray4
            containerView.addSubview(videoView)
            videoViews.append(videoView)
        }
        
        if style == 0 {
            videoViews[0].frame = containerView.bounds
        } else if style == 1 {

            line.backgroundColor = .black
            containerView.addSubview(line)
            
            let button1 = UIButton()
            let button2 = UIButton()
            chooseViewButtons.append(button1)
            chooseViewButtons.append(button2)
            containerView.addSubview(chooseViewButtons[0])
            containerView.addSubview(chooseViewButtons[1])
            chooseViewButtons[0].setBackgroundImage(UIImage(systemName: "plus"), for: .normal)
            chooseViewButtons[1].setBackgroundImage(UIImage(systemName: "plus"), for: .normal)
            chooseViewButtons[0].translatesAutoresizingMaskIntoConstraints = false
            chooseViewButtons[1].translatesAutoresizingMaskIntoConstraints = false
            chooseViewButtons[0].tintColor = .black
            chooseViewButtons[1].tintColor = .black
            videoViews[0].translatesAutoresizingMaskIntoConstraints = false
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
                chooseViewButton.addTarget(self, action: #selector(chooseView(_:)), for: .touchUpInside)
            }
        }
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        stretchScreenButton.translatesAutoresizingMaskIntoConstraints = false
        shrinkScreenButton.translatesAutoresizingMaskIntoConstraints = false
        postProductionView.translatesAutoresizingMaskIntoConstraints = false
        postProductionView.backgroundColor = .white
        NSLayoutConstraint.activate([
            cameraButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            cameraButton.heightAnchor.constraint(equalToConstant: 60),
            cameraButton.widthAnchor.constraint(equalToConstant: 60),
            stretchScreenButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            stretchScreenButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            stretchScreenButton.heightAnchor.constraint(equalToConstant: 60),
            stretchScreenButton.widthAnchor.constraint(equalToConstant: 60),
            shrinkScreenButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            shrinkScreenButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            shrinkScreenButton.heightAnchor.constraint(equalToConstant: 60),
            shrinkScreenButton.widthAnchor.constraint(equalToConstant: 60),
            postProductionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            postProductionView.heightAnchor.constraint(equalToConstant: 60),
            postProductionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            postProductionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        shrinkScreenButton.isHidden = true
        
    }
    func configure(for style: Int) {
        for index in 0...style {
            let player = AVPlayer()
            players.append(player)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = videoViews[index].bounds
            playerLayer.videoGravity = .resizeAspectFill
            videoViews[index].layer.addSublayer(playerLayer)
            playerLayers.append(playerLayer)
            if let videoURL = getVideoURL(for: index) {
                let playerItem = AVPlayerItem(url: videoURL)
                players[index].replaceCurrentItem(with: playerItem)
            }
            print("playerLayer count:\(playerLayers.count)")
        }
        if captureSession.isRunning {
                captureSession.stopRunning()
            }
        
        captureSession.sessionPreset = AVCaptureSession.Preset.high
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
            containerView.layer.addSublayer(cameraPreviewLayer!)
        } else if style == 1 {
            postProductionView.isHidden = false
        }
        containerView.clipsToBounds = true
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.frame = containerView.layer.bounds

        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }


    @objc func toggleCameraPosition(_ sender: UIBarButtonItem) {
        guard !isRecording else {
               print("錄製中，無法切換鏡頭")
               return
           }

        isFrontCamera.toggle()
    }

    @IBAction func capture(sender: AnyObject) {
        if !isRecording {
            isRecording = true
            UIView.animate(withDuration: 0.5, delay: 0.0, options: [.repeat, .autoreverse, .allowUserInteraction], animations: { () -> Void
                in
                self.cameraButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            },
                           completion: nil
            )
            
            let outputPath = NSTemporaryDirectory() + "output\(currentRecordingView).mov"
            outputFileURL = URL(fileURLWithPath: outputPath)
            if let outputFileURL = outputFileURL {
                videoFileOutput?.startRecording(to: outputFileURL, recordingDelegate: self)
            }
        } else {
            isRecording = false
            UIView.animate(withDuration: 0.5, delay: 1.0, options: [], animations: { () -> Void
            in
                self.cameraButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }, completion: nil)
            cameraButton.layer.removeAllAnimations()
            videoFileOutput?.stopRecording()
        }
    }

    func playAllVideos() {
        self.cameraPreviewLayer?.removeFromSuperlayer()
        for (index, player) in players.enumerated() {
            print("index:\(index),player:\(player)")
            let playerLayer = playerLayers[index]
                if let videoURL = getVideoURL(for: index) {
                    let playerItem = AVPlayerItem(url: videoURL)
                    player.replaceCurrentItem(with: playerItem)
                    NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
                    NotificationCenter.default.addObserver(self,
                                                           selector: #selector(videoDidEnd),
                                                           name: .AVPlayerItemDidPlayToEndTime,
                                                           object: playerItem)
                    player.play()
                        videoViews[index].layer.addSublayer(playerLayer)
                    playerLayer.frame = videoViews[index].bounds
//                    containerView.bringSubviewToFront(videoViews[index])
                }
            }

        replayButton.isHidden = true
//        NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: players[0].currentItem)
//        player?.play()
    }
    
    func stopAllVideos() {
        for player in players {
            player.pause()
        }
    }
//    @objc func videoDidEnd(notification: NSNotification) {
//        guard let playerItem = notification.object as? AVPlayerItem else { return }
//           for (index, player) in players.enumerated() {
//               if player.currentItem == playerItem {
//                   print("Player \(index) finished playing")
//                   break
//               }
//           }
//           replayButton.isHidden = false
//           containerView.bringSubviewToFront(replayButton)
//    }
    @objc func videoDidEnd(notification: NSNotification) {
        guard let playerItem = notification.object as? AVPlayerItem else { return }
        replayButton.isHidden = false
        containerView.bringSubviewToFront(replayButton)
        
        for (index, player) in players.enumerated() {
            containerView.bringSubviewToFront(chooseViewButtons[index])
            if player.currentItem == playerItem {
                print("Player \(index) finished playing")
                if chooseViewButtons.count > 1 {
                    
                    chooseViewButtons[index].isHidden = player.status == .readyToPlay && player.currentItem != nil
                print("=======player.status:\(player.status)，player.currentItem==nil:\(player.currentItem == nil)")
                }
                break
            }
        }
//        let allVideosEnded = players.allSatisfy { $0.rate == 0 && $0.currentItem?.status == .readyToPlay }
    }


}

extension CreateViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        guard error == nil else {
            print(error ?? "")
            return
        }
        let alertViewController = UIAlertController(title: "影片錄製成功？", message: "", preferredStyle: .alert)
        let successAction = UIAlertAction(title: "OK", style: .default) { _ in
//            self.playVideo(url: outputFileURL)
            self.playAllVideos()
            self.setupCutting()
        }
        let againAction = UIAlertAction(title: "重來", style: .cancel)
        alertViewController.addAction(successAction)
        alertViewController.addAction(againAction)
        present(alertViewController, animated: true)
    }
}

extension CreateViewController {
    func setupReplayButton() {
        replayButton.setBackgroundImage(UIImage(systemName: "play.circle"), for: .normal)
        replayButton.addTarget(self, action: #selector(replayVideo), for: .touchUpInside)
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
        @objc func replayVideo() {
            playAllVideos()
//            playVideo(url: <#T##URL#>)
            for player in self.players {
                player.seek(to: .zero)
                player.play()
                replayButton.isHidden = true
            }
//            if let player = player {
//                    player.seek(to: .zero)
//                    player.play()
//                    replayButton.isHidden = true
//                }
        }
    @IBAction func toggleScreenSize(sender: UIButton) {
        if sender == stretchScreenButton {
            stretchScreenButton.isHidden = true
            shrinkScreenButton.isHidden = false
            self.containerViewLeadingConstraint.constant = 0
            self.containerViewTrailingConstraint.constant = 0
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
                self.cameraPreviewLayer?.frame = self.containerView.layer.bounds
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
    func setupCutting() {
        let shareButton = UIBarButtonItem(title: "分享", style: .plain, target: self, action: #selector(pushSharePage(_:)))
        self.navigationItem.rightBarButtonItem = shareButton
    }
    func bookEarphoneState() {
        headphoneAlertLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headphoneAlertLabel.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 20),
            headphoneAlertLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
        let route = AVAudioSession.sharedInstance().currentRoute
        for output in route.outputs {
            if output.portType == .headphones {
                print("耳機已連接")
                headphoneAlertLabel.isHidden = true
            } else {
                print("使用外放")
                headphoneAlertLabel.isHidden = false
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    @objc func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        switch reason {
        case .newDeviceAvailable:
            print("新增了耳機")
            headphoneAlertLabel.isHidden = true
        case .oldDeviceUnavailable:
            if let previousRoute = userInfo[AVAudioSessionRouteChangeReasonKey] as? AVAudioSessionRouteDescription {
                let wasUsingHeadPhones = previousRoute.outputs.contains {
                    $0.portType == .headphones
                }
                if wasUsingHeadPhones {
                    print("耳機已移除")
                    headphoneAlertLabel.isHidden = false
                }
            }
            print("無耳機")
            headphoneAlertLabel.isHidden = false
        default: break
        }
    }
//    @objc func chooseView(_ sender: UIButton) {
//        postProductionView.isHidden = true
//        if sender == chooseViewButtons[0] {
//            currentRecordingView = 0
//            videoViews[0].layer.addSublayer(cameraPreviewLayer!)
//            chooseViewButtons[0].isHidden = true
//            if let playerOne = players.count > 1 ? players[1] : nil, playerOne.currentItem != nil {
//                       chooseViewButtons[1].isHidden = true
//                   } else {
//                       chooseViewButtons[1].isHidden = false
//                   }
//        } else if sender == chooseViewButtons[1] {
//            currentRecordingView = 1
//            videoViews[1].layer.addSublayer(cameraPreviewLayer!)
//            chooseViewButtons[1].isHidden = true
//            if let playerZero = players.count > 0 ? players[0] : nil, playerZero.currentItem != nil {
//                       chooseViewButtons[0].isHidden = true
//                   } else {
//                       chooseViewButtons[0].isHidden = false
//                   }
//        }
//    }
    // TODO: 修理 + 跟 replayButton
    @objc func chooseView(_ sender: UIButton) {
        replayButton.isHidden = true
        postProductionView.isHidden = true
            let viewIndex = sender == chooseViewButtons[0] ? 0 : 1
            currentRecordingView = viewIndex
            videoViews[viewIndex].layer.addSublayer(cameraPreviewLayer!)
        
            chooseViewButtons[viewIndex].isHidden = true
            let otherIndex = viewIndex == 0 ? 1 : 0
            if players.count > otherIndex {
                let otherPlayerHasItem = players[otherIndex].currentItem != nil && players[otherIndex].currentItem?.duration.seconds ?? 0 > 0
                chooseViewButtons[otherIndex].isHidden = otherPlayerHasItem
                
            }
    }
    @objc func pushSharePage(_ sender: UIBarButtonItem) {
        let shareVC = ShareViewController()
        shareVC.url = outputFileURL
        navigationController?.pushViewController(shareVC, animated: true)
    }
    func getVideoURL(for index: Int) -> URL? {
        let outputPath = NSTemporaryDirectory() + "output\(index).mov"
        outputFileURL = URL(fileURLWithPath: outputPath)
        print("getVideoURL:\(outputFileURL!)")
        return outputFileURL
    }
    func configurePlayersAndAddObservers() {
        guard !players.isEmpty else {
            return
        }
        for player in players {
            if let currentItem = player.currentItem {
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(videoDidEnd),
                                                       name: .AVPlayerItemDidPlayToEndTime,
                                                       object: currentItem)
            }
        }
    }
    func clearTemporaryVideos() {
        let fileManager = FileManager.default
        let tempDirectoryPath = NSTemporaryDirectory()

        do {
            let tempFiles = try fileManager.contentsOfDirectory(atPath: tempDirectoryPath)
            for file in tempFiles {
                let filePath = (tempDirectoryPath as NSString).appendingPathComponent(file)
                try fileManager.removeItem(atPath: filePath)
            }
        } catch let error {
            print("Failed to clear temporary files: \(error)")
        }
    }
    private func configureSessionWithNewInput(_ newInput: AVCaptureDeviceInput) {
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

