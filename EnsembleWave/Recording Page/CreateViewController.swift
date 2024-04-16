//
//  CreateViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/9.
//

import UIKit
import AVFoundation // 錄影
import AVKit // 播放影像 access to AVPlayer
import Photos // 儲存影像
import MediaPlayer // 改變音量
import VideoConverter // 裁切影片
import VideoTrim

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
    var replayButton = UIButton()
    @IBOutlet private var containerViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var containerViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerViewRatio: NSLayoutConstraint!
    @IBOutlet weak var headphoneAlertLabel: UILabel!
    var videoViews: [UIView] = []
    let line = UIView()
    var chooseViewButtons = [UIButton]()

    @IBOutlet weak var postProductionView: UIView!
    var outputFileURL: URL?
    var currentRecordingIndex = 0
    
    var videoURLs: [URL] = []
    var audioURLs: [URL] = []
    var playerVolume: Float = 0.5
    var previousVolume: Float = 0.5
    
    @IBOutlet weak var trimView: UIView!
    var endTimeObservers: [AVPlayer: Any] = [:]
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let trimContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
    private let videoTrim: VideoTrim = {
        let videoTrim = VideoTrim()
        videoTrim.translatesAutoresizingMaskIntoConstraints = false
        videoTrim.topMargin = 4
        videoTrim.bottomMargin = 8
        return videoTrim
    }()

    private var videoConverter: VideoConverter?
    private var isPlaying = false
    private var preset: String?
    var endTimeObserver: Any? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        videoURLs.removeAll()
        setupUI(style, length)
        setupReplayButton()
        bookEarphoneState()
        configurePlayersAndAddObservers()
        clearTemporaryVideos()
        configure(for: style)
        getCurrentSystemVolume()
        self.videoTrim.delegate = self
    }
    @objc func preparedToShare() {
        // 創建 AVURLAsset
            let asset = AVURLAsset(url: videoURLs[currentRecordingIndex])
            // 我們想要非同步加載的資訊鍵
            let keys = ["tracks"]

            // 非同步加載資訊
            asset.loadValuesAsynchronously(forKeys: keys) {
                // 主線程上處理加載後的結果，因為我們將更新UI
                DispatchQueue.main.async {
                    var error: NSError?
                    let status = asset.statusOfValue(forKey: "tracks", error: &error)
                    if status == .loaded {
                        if asset.tracks(withMediaType: .video).isEmpty {
                            print("asset 中沒有影片 tracks")
                        } else {
                            self.continuePreparedToShare(with: asset)
                        }
                    } else {
                        print("資源的軌道加載未成功: \(error?.localizedDescription ?? "未知錯誤")")
                    }
                }
            }
    }
    func continuePreparedToShare(with asset: AVAsset) {
        trimView.isHidden = true
        let shareButton = UIBarButtonItem(title: "分享", style: .plain, target: self, action: #selector(pushSharePage(_:)))
        self.navigationItem.rightBarButtonItem = shareButton
        self.navigationItem.leftBarButtonItem = nil

        let startTime = videoTrim.startTime
        let endTime = videoTrim.endTime

        if let outputURL = getVideoURL(for: currentRecordingIndex) {
            print("開始導出到: \(outputURL)")
            do {
                try FileManager.default.removeItem(at: outputURL)
            } catch {
                print("清除舊檔案失敗: \(error.localizedDescription)")
            }
            exportCroppedVideo(asset: asset, startTime: startTime, endTime: endTime, outputURL: outputURL) { success in
                DispatchQueue.main.async {
                    if success {
                        let playerItem = AVPlayerItem(url: outputURL)
                        self.players[self.currentRecordingIndex].replaceCurrentItem(with: playerItem)
                        self.players[self.currentRecordingIndex].seek(to: CMTime.zero)
                        self.players[self.currentRecordingIndex].play()
                        self.replayVideo()
                        self.setupEndTimeObserver(for: self.players[self.currentRecordingIndex], startTime: startTime, endTime: endTime)
                        self.setupObserversForPlayerItem(playerItem, with: self.players[self.currentRecordingIndex])
                        print("裁剪和導出成功")
                    } else {
                        print("裁剪和導出失敗")
                    }
                }
            }
        }
    }

    @objc func recordAgain() {
        let cameraPositionButton = UIBarButtonItem(image: UIImage(systemName: "arrow.triangle.2.circlepath.camera"), style: .plain, target: self, action: #selector(toggleCameraPosition(_:)))
        self.navigationItem.rightBarButtonItem = cameraPositionButton
        self.navigationItem.leftBarButtonItem = nil
        trimView.isHidden = true
        
    }
    func setupTrimViewUI() {
        postProductionView.isHidden = false
        let trimOKButton = UIBarButtonItem(image: UIImage(systemName: "checkmark.circle.fill"), style: .plain, target: self, action: #selector(preparedToShare))
        let trimCancelButton = UIBarButtonItem(image: UIImage(systemName: "xmark.circle.fill"), style: .plain, target: self, action: #selector(recordAgain))
        self.navigationItem.rightBarButtonItem = trimOKButton
        self.navigationItem.leftBarButtonItem = trimCancelButton
        guard let videoFileURL = getVideoURL(for: currentRecordingIndex) else {
            print("在 setupTrimViewUI 內 getVideoURL 失敗")
            return
        }
        let asset = AVAsset(url: videoFileURL)
        videoTrim.asset = asset
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        trimView.backgroundColor = .red
        trimView.isHidden = false
        self.trimView.addSubview(self.scrollView)
        self.scrollView.addSubview(self.trimContainerView)
        scrollView.backgroundColor = .blue
        self.trimContainerView.addSubview(self.videoTrim)
        videoTrim.backgroundColor = .orange
        // trimContainerView 是 .black
        self.trimView.addConstraints([
            NSLayoutConstraint(item: self.scrollView, attribute: .leading, relatedBy: .equal, toItem: self.trimView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.scrollView, attribute: .trailing, relatedBy: .equal, toItem: self.trimView, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.scrollView, attribute: .top, relatedBy: .equal, toItem: self.trimView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.scrollView, attribute: .bottom, relatedBy: .equal, toItem: self.trimView, attribute: .bottom, multiplier: 1, constant: 0)
        ])
        let containerViewHeightConstraint = NSLayoutConstraint(item: self.trimContainerView, attribute: .height, relatedBy: .equal, toItem: self.scrollView, attribute: .height, multiplier: 1, constant: 0)
        containerViewHeightConstraint.priority = UILayoutPriority(rawValue: 1)
        self.scrollView.addConstraints([
            NSLayoutConstraint(item: self.trimContainerView, attribute: .leading, relatedBy: .equal, toItem: self.scrollView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimContainerView, attribute: .trailing, relatedBy: .equal, toItem: self.scrollView, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimContainerView, attribute: .top, relatedBy: .equal, toItem: self.scrollView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimContainerView, attribute: .bottom, relatedBy: .equal, toItem: self.scrollView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimContainerView, attribute: .width, relatedBy: .equal, toItem: self.scrollView, attribute: .width, multiplier: 1, constant: 0),
            containerViewHeightConstraint
        ])
        self.trimContainerView.addConstraints([
            NSLayoutConstraint(item: self.videoTrim, attribute: .top, relatedBy: .equal, toItem: self.trimContainerView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.videoTrim, attribute: .leading, relatedBy: .equal, toItem: self.trimContainerView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.videoTrim, attribute: .trailing, relatedBy: .equal, toItem: self.trimContainerView, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.videoTrim, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100)  // 設置一個固定高度
        ])

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        for (player, observer) in endTimeObservers {
                player.removeTimeObserver(observer)
            }
    }
    func setupUI(_ style: Int, _ length: Int) {
        trimView.isHidden = true
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
        for _ in 0...style {
            let videoView = UIView()
            videoView.backgroundColor = .systemGray4
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
            
            videoViews[0].frame = containerView.bounds
            NSLayoutConstraint.activate([
                videoViews[0].topAnchor.constraint(equalTo: containerView.topAnchor),
                videoViews[0].leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                videoViews[0].trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                videoViews[0].bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
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
            postProductionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
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
            containerView.layer.addSublayer(cameraPreviewLayer!)
            cameraPreviewLayer?.frame = containerView.layer.bounds
        } else if style == 1 {
            postProductionView.isHidden = false
        }
        containerView.clipsToBounds = true
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill

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
            if style == 0 {
                if let cameraPreviewLayer = cameraPreviewLayer {
                    videoViews[0].layer.addSublayer(cameraPreviewLayer)
                    cameraPreviewLayer.frame = videoViews[0].bounds
                }
            } else {
                replayVideo()
            }
            
            let outputPath = NSTemporaryDirectory() + "output\(currentRecordingIndex).mov"
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
        if style == 0 {
            self.cameraPreviewLayer?.removeFromSuperlayer()
        } else {
            if let cameraPreviewLayer = cameraPreviewLayer {
                if !cameraPreviewLayer.isPreviewing {
                    print("isPreviewing:\(cameraPreviewLayer.isPreviewing)")
                    self.cameraPreviewLayer?.removeFromSuperlayer()
                }
            }
            if isRecording {
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
                if let videoURL = getVideoURL(for: index) {
                    videoURLs.append(videoURL)
                    let playerItem = AVPlayerItem(url: videoURL)
                    player.replaceCurrentItem(with: playerItem)
                    setupObserversForPlayerItem(playerItem, with: player)
//                    if index == currentRecordingIndex {
//                        if let startTime = getCropStartTime(for: index) {
//                            player.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero)
//                        }
//                    }
                    player.play()
                    isPlaying = true
                    if style == 0 {
                        videoViews[0].layer.addSublayer(playerLayer)
                        playerLayer.frame = videoViews[0].bounds
                    } else {
                        videoViews[index].layer.addSublayer(playerLayer)
                        playerLayer.frame = videoViews[index].bounds
                        
                    }
                    playerLayer.videoGravity = .resizeAspectFill
                    }
                }
            replayButton.isHidden = true
    }
    func getCropStartTime(for index: Int) -> CMTime? {
        if index == currentRecordingIndex {
            return videoTrim.startTime
        }
        return nil
    }

    func setupObserversForPlayerItem(_ playerItem: AVPlayerItem, with player: AVPlayer) {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    func adjustVolumeForRecording() {
        if headphoneAlertLabel.isHidden {
            previousVolume = playerVolume
            print("previousVolume:\(previousVolume)")
            MPVolumeView.setVolume(0.0)
            print("isRecording Volume:\(0.0)")
        } else {
            MPVolumeView.setVolume(playerVolume)
            print("set playerVolume:\(playerVolume)")
        }
    }
    func stopAllVideos() {
        for player in players {
            player.pause()
        }
    }

    @objc func videoDidEnd(notification: NSNotification) {
        guard let playerItem = notification.object as? AVPlayerItem else { return }
        replayButton.isHidden = false
        containerView.bringSubviewToFront(replayButton)
        
        for (index, player) in players.enumerated() {
            if player.currentItem == playerItem {
                print("Player \(index) finished playing")
                if chooseViewButtons.count > 1 {
                    containerView.bringSubviewToFront(chooseViewButtons[index])
                    chooseViewButtons[index].isHidden = player.status == .readyToPlay && player.currentItem != nil
                print("=======player.status:\(player.status)，player.currentItem==nil:\(player.currentItem == nil)")
                } else {
                    currentRecordingIndex = 0
                }
                break
            }
        }
    }
}

extension CreateViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        guard error == nil else {
            print(error ?? "")
            return
        }
        playerVolume = previousVolume
        print("didFinishRecording，previousVolume:\(previousVolume)")
        let alertViewController = UIAlertController(title: "影片錄製成功？", message: "", preferredStyle: .alert)
        let successAction = UIAlertAction(title: "OK", style: .default) { _ in
            self.playAllVideos()
            self.setupTrimViewUI()
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
        for player in self.players {
            player.seek(to: .zero)
            player.play()
            replayButton.isHidden = true
        }
    }

    @IBAction func toggleScreenSize(sender: UIButton) {
        if style == 0 {
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
        } else if style == 1 {
            if sender == stretchScreenButton {
                stretchScreenButton.isHidden = true
                shrinkScreenButton.isHidden = false
                self.containerViewLeadingConstraint.constant = 0
                self.containerViewTrailingConstraint.constant = 0
                UIView.animate(withDuration: 0.5) {
                    self.view.layoutIfNeeded()
                    self.cameraPreviewLayer?.frame = self.videoViews[self.currentRecordingIndex].bounds
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

    func bookEarphoneState() {
        headphoneAlertLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headphoneAlertLabel.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 20),
            headphoneAlertLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
        let route = AVAudioSession.sharedInstance().currentRoute
        for output in route.outputs {
            if output.portType == .headphones || output.portType == .bluetoothA2DP {
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
                let wasUsingBlueToothEarPhones = previousRoute.outputs.contains {
                    $0.portType == .bluetoothA2DP
                }
                if wasUsingHeadPhones || wasUsingBlueToothEarPhones {
                    print("耳機已移除")
                    headphoneAlertLabel.isHidden = false
                }
            }
            print("無耳機")
            headphoneAlertLabel.isHidden = false
            if isRecording {
                adjustVolume(isHeadphonesConnected: false)
            }
        default: break
        }
    }
// 在錄音狀態改變系統音量
    private func adjustVolume(isHeadphonesConnected: Bool) {
        for player in players {
            if isHeadphonesConnected {
                       player.volume = playerVolume
                       print("Headphones connected. Restoring volume.")
                   } else {
                       player.volume = 0
                       print("Headphones disconnected. Muting audio.")
                   }
        }
    }
    @objc func chooseView(_ sender: UIButton) {
        replayButton.isHidden = true
        postProductionView.isHidden = true
        trimView.isHidden = true
        let viewIndex = sender == chooseViewButtons[0] ? 0 : 1
        currentRecordingIndex = viewIndex
        cameraPreviewLayer?.frame = videoViews[viewIndex].bounds
        videoViews[viewIndex].layer.addSublayer(cameraPreviewLayer!)
        chooseViewButtons[viewIndex].isHidden = true
        let otherIndex = viewIndex == 0 ? 1 : 0
        if players.count > otherIndex {
            let otherPlayerHasItem = players[otherIndex].currentItem != nil && players[otherIndex].currentItem?.duration.seconds ?? 0 > 0
            chooseViewButtons[otherIndex].isHidden = otherPlayerHasItem
        }
    }
    @objc func pushSharePage(_ sender: UIBarButtonItem) {
        guard let outputFileURL = outputFileURL, !videoURLs.isEmpty/*, !audioURLs.isEmpty*/ else {
            print("點擊分享鍵，但輸出失敗")
            return
        }
        let outputMergedFileURL = URL(fileURLWithPath: NSTemporaryDirectory() + "mergedOutput.mov")
        if style > 0 {
            mergeMedia(videoURLs: videoURLs, audioURLs: audioURLs, outputURL: outputMergedFileURL) { [weak self] success in
                    DispatchQueue.main.async {
                        if success {
                            let shareVC = ShareViewController()
                            shareVC.url = outputMergedFileURL
                            print("導出成功，建立並推送 ShareViewController")
                            self?.navigationController?.pushViewController(shareVC, animated: true)
                        } else {
                            let alert = UIAlertController(title: "導出錯誤", message: "無法導出影片", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "確定", style: .default))
                            self?.present(alert, animated: true, completion: nil)
                        }
                    }
                }
        } else {
            let shareVC = ShareViewController()
            shareVC.url = outputFileURL
            navigationController?.pushViewController(shareVC, animated: true)
        }
    }
    func getVideoURL(for index: Int) -> URL? {
        let outputPath = NSTemporaryDirectory() + "output\(index).mov"
        outputFileURL = URL(fileURLWithPath: outputPath)
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
    func mergeMedia(videoURLs: [URL], audioURLs: [URL], outputURL: URL, completion: @escaping (Bool) -> Void) {
        let mixComposition = AVMutableComposition()
        var instructions = [AVMutableVideoCompositionLayerInstruction]()
        var videoFrames = [CGRect]()
        if Thread.isMainThread { 
            for videoView in self.videoViews {
                videoFrames.append(videoView.frame)
                print("===videoView.frame:\(videoView.frame)")
            }
        } else {
            DispatchQueue.main.sync {
                for videoView in self.videoViews {
                    videoFrames.append(videoView.frame)
                }
            }
        }
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
            
            print("mainInstruction.layerInstructions:\(mainInstruction.layerInstructions)")
            let videoComposition = AVMutableVideoComposition()
            videoComposition.renderSize = CGSize(width: self.containerView.frame.width, height: self.containerView.frame.height)
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
    func getCurrentSystemVolume() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
        } catch {
            print("Unable to activate audio session")
        }
        playerVolume = audioSession.outputVolume
        print("Current system volume: \(playerVolume)")
        audioSession.addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions.new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
        } catch {
            print("Unable to activate audio session")
        }
        if keyPath == "outputVolume" {
            playerVolume = audioSession.outputVolume
            print("playerVolume: \(playerVolume)")
          }
    }
}

extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}
extension CreateViewController {
    private func updateTrimTime() {
        for (index, player) in players.enumerated() {
            if let currentItem = player.currentItem {
                let startTime = videoTrim.startTime
                let endTime = videoTrim.endTime
                let timeRange = CMTimeRange(start: startTime, end: endTime)
                currentItem.seek(to: startTime, completionHandler: nil)
                print("更新第 \(index) 個播放器的播放範圍為 \(timeRange)")
            }
        }
    }
}
extension CreateViewController: VideoTrimDelegate {
    func videoTrimStartTrimChange(_ view: VideoTrim) {
        isPlaying = false
        self.stopAllVideos()
    }

    func videoTrimEndTrimChange(_ view: VideoTrim) {
        self.updateTrimTime()
        
        let startTime = view.startTime
        let endTime = view.endTime
        let editingPlayer = players[currentRecordingIndex]
        updatePlayerRange(for: editingPlayer, withStartTime: startTime, endTime: endTime)
        isPlaying = true
        if isPlaying {
            playAllVideos()
        }
    }

    func videoTrimPlayTimeChange(_ view: VideoTrim) {
        let newTime = CMTime(value: CMTimeValue(view.playTime.value + view.startTime.value), timescale: view.playTime.timescale)
        let player = players[currentRecordingIndex]
        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func updatePlayerRange(for player: AVPlayer, withStartTime startTime: CMTime, endTime: CMTime) {
        guard let currentItem = player.currentItem else {
            return
        }
        let asset = currentItem.asset
        let newRange = CMTimeRange(start: startTime, duration: endTime - startTime)
        
        let newPlayerItem = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: newPlayerItem)
        
        player.seek(to: newRange.start) { [weak self] _ in
            guard let self = self else { return }
            player.play()
            self.setupEndTimeObserver(for: player, startTime: startTime, endTime: endTime)
        }
    }

    func setupEndTimeObserver(for player: AVPlayer, startTime: CMTime, endTime: CMTime) {
        if let observer = endTimeObservers[player] {
            player.removeTimeObserver(observer)
            endTimeObservers[player] = nil
        }

        let observer = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { [weak self] time in
            if time >= endTime {
                player.pause()
                player.seek(to: startTime)
            }
        }

        endTimeObservers[player] = observer
    }

    func exportCroppedVideo(asset: AVAsset, startTime: CMTime, endTime: CMTime, outputURL: URL, completion: @escaping (Bool) -> Void) {
        print("asset.tracks:\(asset.tracks)")
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
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
}
