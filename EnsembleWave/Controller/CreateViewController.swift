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
import VideoTrim // 裁切影片
import Vision // 手勢
import PhotosUI // 選取相簿影片
import Lottie // 動畫
import SwiftEntryKit
class CreateViewController: UIViewController {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var stretchScreenButton: UIButton!
    @IBOutlet weak var shrinkScreenButton: UIButton!
    var style = 0
    var length: Int = 15
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
    let countdownButton = UIButton() // 開始前的倒數計時
    let cameraPositionButton = UIButton()
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
    var endTimeObserver: Any?
    
    private let recordingTopView: UIView = {
       let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private let countdownLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var countdownTimer: Timer?
    var videoViewHasContent: [Bool] = []
    lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(videoViewTapped(_:)))
    var countBeforeRecording: Bool = true // 使用者點選相機，決定要不要倒數計時
    let countingImages = ["5.circle.fill", "4.circle.fill", "3.circle.fill", "2.circle.fill", "1.circle.fill"]
    var currentImageIndex = 0
    var countdownImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    var timerBeforePlay: Timer?
    var handPoseRequest = VNDetectHumanHandPoseRequest()
    var useHandPoseStartRecording: Bool = false
    var isHeadphoneConnected: Bool = false {
        didSet {
            headphoneAlertLabel.isHidden = isHeadphoneConnected
            print("耳機已連接:\(isHeadphoneConnected)")
        }
    }
    @IBOutlet weak var albumButton: UIButton!
    
    @IBOutlet weak var musicButton: UIButton!
    var selectedMusic: MusicType?
    var audioPlayer: AVAudioPlayer?
    var musicPlayer: MPMusicPlayerController?
    var animView: LottieAnimationView?
    var ensembleVideoURL: String?
    var ensembleUserID: String?
    var duration: Int?
    lazy var handPoseButton = UIButton()
    var restingHand = true
    
    @IBOutlet weak var cameraBottomView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        print("===== CreateViewController viewDidLoad =====")
        print("length:\(length)")
        withUnsafeBytes(of: &(players)) { (point) in
            print("players 在記憶體的位置:\(point)")
        }
        print("ensembleVideoURL:\(ensembleVideoURL ?? "no ensembleVideoURL")")
        videoURLs.removeAll()
        setupUI(style)
        setupReplayButton()
        bookEarphoneState()
        configurePlayersAndAddObservers()
        clearTemporaryVideos()
        self.videoTrim.delegate = self
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("===== CreateViewController viewWillAppear =====")
        print("style:\(style)")
        getCurrentSystemVolume()
//        if useHandPoseStartRecording {
//            addGestureRecognitionToSession()
//        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("===== CreateViewController viewDidLayoutSubviews =====")
    }
    override func viewWillDisappear(_ animated: Bool) {
        animView?.stop()
        animView?.removeFromSuperview()
        animView = nil
        recordingTopView.isHidden = true
//        recordingTopView.removeFromSuperview()
        for player in players {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        }
        AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
        for (player, observer) in endTimeObservers {
            player.removeTimeObserver(observer)
        }
            endTimeObservers.removeAll()
        for player in players {
                player.pause()
                player.replaceCurrentItem(with: nil)
            }
        musicPlayer?.stop()
        musicPlayer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
        for layer in playerLayers {
            layer.removeFromSuperlayer()
        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("===== CreateViewController viewDidDisappear =====")
//        dchCheckDeallocation()
    }
    override func viewDidAppear(_ animated: Bool) {
        print("===== CreateViewController viewDidAppear =====")
        if ensembleVideoURL != nil && style == 1 {
            chooseView(chooseViewButtons[0])
        }
    }
    @objc func preparedToShare() {
        let asset = AVURLAsset(url: videoURLs[currentRecordingIndex])
        let keys = ["tracks"]
        
        asset.loadValuesAsynchronously(forKeys: keys) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
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
    func setupShareButton() {
        trimView.isHidden = true
        let shareButton = UIBarButtonItem(title: "分享", style: .plain, target: self, action: #selector(pushSharePage(_:)))
        self.navigationItem.rightBarButtonItem = shareButton
        self.navigationItem.leftBarButtonItem = nil
    }
    func continuePreparedToShare(with asset: AVAsset) {
        setupShareButton()

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
                        self.videoViewHasContent[self.currentRecordingIndex] = true
                        self.videoViews[self.currentRecordingIndex].addGestureRecognizer(self.tapGesture)
                        print("videoViews[0].subviews:\(self.videoViews[0].subviews)")
                        let durationInSeconds = CMTimeGetSeconds(asset.duration)
                        self.duration = Int(durationInSeconds.rounded())
                        print("儲存的影片長度為: \(self.duration ?? 0) 秒")
                    } else {
                        print("裁剪和導出失敗")
                    }
                }
            }
        }
    }

    @objc func recordAgain() {
//        let cameraPositionButton = UIBarButtonItem(image: UIImage(systemName: "arrow.triangle.2.circlepath.camera"), style: .plain, target: self, action: #selector(toggleCameraPosition(_:)))
//        self.navigationItem.rightBarButtonItem = cameraPositionButton
        if style == 0 {
            startToRecordingView()
        } else {
            chooseView(chooseViewButtons[currentRecordingIndex])
        }
        self.navigationItem.leftBarButtonItem = nil
        trimView.isHidden = true
        stopCountdownTimer()
        self.countdownLabel.text = self.timeFormatter(sec: self.length)
        self.clearVideoView(for: self.currentRecordingIndex)
        self.prepareRecording(for: self.currentRecordingIndex)
        if useHandPoseStartRecording {
            addGestureRecognitionToSession()
        }
    }
    func setupTrimViewUI() {
        stopCountdownTimer()
        postProductionView.isHidden = false
//        view.bringSubviewToFront(postProductionView)
        let trimOKButton = UIBarButtonItem(image: UIImage(systemName: "checkmark.circle.fill"), style: .plain, target: self, action: #selector(preparedToShare))
        let trimCancelButton = UIBarButtonItem(image: UIImage(systemName: "xmark.circle.fill"), style: .plain, target: self, action: #selector(recordAgain))
        self.navigationItem.rightBarButtonItem = trimOKButton
        self.navigationItem.leftBarButtonItem = trimCancelButton
        var videoFileURL: URL?
        if style == 1 && ensembleVideoURL != nil {
            guard let url = URL(string: ensembleVideoURL!) else {
                print("no ensembleVideoURL")
                return
            }
            videoFileURL = url
        } else {
            guard let url = getVideoURL(for: currentRecordingIndex) else {
                print("在 setupTrimViewUI 內 getVideoURL 失敗")
                return
            }
            videoFileURL = url
        }
        guard let videoFileURL = videoFileURL else {
            return
        }
        let asset = AVAsset(url: videoFileURL)
        videoTrim.asset = asset
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        trimView.backgroundColor = CustomColor.red
        trimView.isHidden = false
        self.trimView.addSubview(self.scrollView)
        self.scrollView.addSubview(self.trimContainerView)
        scrollView.backgroundColor = .blue
        self.trimContainerView.addSubview(self.videoTrim)
        videoTrim.backgroundColor = .black
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
            NSLayoutConstraint(item: self.videoTrim, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100)
        ])
    }
    
    deinit {
        print("===== Enter CreatViewController deinit =====")
        withUnsafeBytes(of: &(players)) { (point) -> Void in
            print("players 在記憶體的位置:\(point)")
        }
        
        print("===== Leave CreatViewController deinit =====")
        withUnsafeBytes(of: &(players)) { (point) -> Void in
            print("players 在記憶體的位置:\(point)")
        }
        clearTemporaryFiles()
    }
    func clearTemporaryFiles() {
        let tempDirectoryPath = NSTemporaryDirectory()
        
        do {
            let fileManager = FileManager.default
            let tempFiles = try fileManager.contentsOfDirectory(atPath: tempDirectoryPath)
            for file in tempFiles {
                let filePath = (tempDirectoryPath as NSString).appendingPathComponent(file)
                try fileManager.removeItem(atPath: filePath)
            }
            print("Temporary files are deleted.")
        } catch {
            print("Failed to delete temporary files: \(error)")
        }
    }
    func setupUI(_ style: Int) {
//        headphoneAlertLabel.textColor = CustomColor.red
        let headphoneText = "Headphones are not detected, sound cannot be played during recording!"
        headphoneAlertLabel.attributedText = attributedTextForm(content: headphoneText, size: 15, kern: 0, color: CustomColor.red ?? .red)
        headphoneAlertLabel.numberOfLines = 0
        cameraButton.tintColor = CustomColor.red
        albumButton.tintColor = .white
        musicButton.tintColor = .white
        stretchScreenButton.tintColor = .white
        shrinkScreenButton.tintColor = .white
        view.backgroundColor = .black
        videoViewHasContent = Array(repeating: false, count: style + 1)
        trimView.isHidden = true
        videoViews.forEach { $0.removeFromSuperview() }
        videoViews.removeAll()
        players.removeAll()
        playerLayers.removeAll()
//        let cameraPositionButton = UIBarButtonItem(image: UIImage(systemName: "arrow.triangle.2.circlepath.camera"), style: .plain, target: self, action: #selector(toggleCameraPosition(_:)))
//        self.navigationItem.rightBarButtonItem = cameraPositionButton
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
            videoViews[0].tag = 0
            if videoViewHasContent[0] {
                videoViews[0].addGestureRecognizer(tapGesture)
            }
            videoViews[0].isUserInteractionEnabled = true
            videoViews[0].frame = containerView.bounds
            let startButton = UIButton()
            chooseViewButtons.append(startButton)
            videoViews[0].addSubview(chooseViewButtons[0])
            chooseViewButtons[0].setBackgroundImage(UIImage(systemName: "plus"), for: .normal)
            chooseViewButtons[0].translatesAutoresizingMaskIntoConstraints = false
            chooseViewButtons[0].tintColor = .white
            chooseViewButtons[0].addTarget(self, action: #selector(startToRecordingView), for: .touchUpInside)
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
            for (index, videoView) in videoViews.enumerated() {
                videoView.tag = index
                videoView.isUserInteractionEnabled = true
                if videoViewHasContent[index] {
                    videoView.addGestureRecognizer(tapGesture)
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
                chooseViewButton.addTarget(self, action: #selector(chooseView(_:)), for: .touchUpInside)
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
    @objc func videoViewTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view else {
            print("videoView sender 取得失敗")
            return
        }
        print("view:\(view)")
        
        let index = view.tag
        print("index:\(index)")
        let controller = UIAlertController(title: "選取影片", message: nil, preferredStyle: .alert)
        let deleteaAndRecordAction = UIAlertAction(title: "刪除並重錄", style: .default) {  [weak self] action in
            guard let self = self else { return }
            self.clearVideoView(for: index)
            self.prepareRecording(for: index)
        }

        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        controller.addAction(deleteaAndRecordAction)
        controller.addAction(cancelAction)
            
            present(controller, animated: true)
    }
    func timeFormatter(sec: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        let second: TimeInterval = Double(sec)
        guard let remainingTime = formatter.string(from: second) else {
            fatalError("時間轉換失敗")
        }
        print("remainingTime: \(remainingTime)")
        return "- \(remainingTime)"
    }
    func startCountdownTimer() {
        var remainingTime = length
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true){ [weak self] _ in
            guard let self = self else { return }
            remainingTime -= 1
            updateCountdownLabel(remainingTime)
            if remainingTime == 0 {
                stopCountdownTimer()
                capture(sender: cameraButton)
            }
        }
    }
    func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        timerBeforePlay?.invalidate()
        timerBeforePlay = nil
    }
    func updateCountdownLabel(_ remainingTime: Int) {
//        countdownLabel.text = timeFormatter(sec: remainingTime)
        countdownLabel.attributedText = attributedTextForm(content: timeFormatter(sec: remainingTime), size: 22, kern: 0, color: CustomColor.red ?? .red)
    }
    func launchTrimTopView() {
        guard navigationController != nil else {
            print("There is no navigation controller")
            return
        }
        recordingTopView.isHidden = true
//        recordingTopView.removeFromSuperview()
        setupTrimViewUI()
    }
    func setupRecordingTopView() {
        guard let navigationController = navigationController else {
            print("There is no navigation controller")
            return
        }
        countBeforeRecording = true
        useHandPoseStartRecording = false
        if let navigationController = self.navigationController, !navigationController.view.subviews.contains(recordingTopView) {
            navigationController.view.addSubview(recordingTopView)
        }
//        navigationController.view.addSubview(recordingTopView)
        recordingTopView.isHidden = false
        cameraPositionButton.setBackgroundImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        cameraPositionButton.tintColor = .white
        cameraPositionButton.addTarget(self, action: #selector(toggleCameraPosition), for: .touchUpInside)
        let cancelButton = UIButton()
        cancelButton.setBackgroundImage(UIImage(systemName: "xmark"), for: .normal)
        cancelButton.tintColor = .white
        cancelButton.addTarget(self, action: #selector(cancelRecording), for: .touchUpInside)
        cameraPositionButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        recordingTopView.translatesAutoresizingMaskIntoConstraints = false
        recordingTopView.addSubview(cameraPositionButton)
        recordingTopView.addSubview(cancelButton)
        recordingTopView.addSubview(countdownLabel)
        recordingTopView.backgroundColor = .black
        updateCountdownLabel(length)
//        countdownLabel.textColor = CustomColor.red
        let buttonSize = 28.0
        NSLayoutConstraint.activate([
            recordingTopView.topAnchor.constraint(equalTo: navigationController.view.topAnchor, constant: 30),
            recordingTopView.leadingAnchor.constraint(equalTo: navigationController.view.leadingAnchor),
            recordingTopView.trailingAnchor.constraint(equalTo: navigationController.view.trailingAnchor),
            recordingTopView.heightAnchor.constraint(equalToConstant: 50),
            countdownLabel.centerXAnchor.constraint(equalTo: recordingTopView.centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: recordingTopView.centerYAnchor),
            countdownLabel.heightAnchor.constraint(equalToConstant: buttonSize),
            cameraPositionButton.centerYAnchor.constraint(equalTo: recordingTopView.centerYAnchor),
            cameraPositionButton.trailingAnchor.constraint(equalTo: recordingTopView.trailingAnchor, constant: -16),
            cameraPositionButton.heightAnchor.constraint(equalToConstant: buttonSize),
            cameraPositionButton.widthAnchor.constraint(equalToConstant: buttonSize),
            cancelButton.centerYAnchor.constraint(equalTo: recordingTopView.centerYAnchor),
            cancelButton.leadingAnchor.constraint(equalTo: recordingTopView.leadingAnchor, constant: 16),
            cancelButton.heightAnchor.constraint(equalToConstant: buttonSize),
            cancelButton.widthAnchor.constraint(equalToConstant: buttonSize)
        ])
        // 開始前的倒數計時
        countdownButton.translatesAutoresizingMaskIntoConstraints = false
        countdownButton.setBackgroundImage(UIImage(systemName: "clock.badge.checkmark"), for: .normal)
        countdownButton.setBackgroundImage(UIImage(systemName: "clock.badge.xmark"), for: .selected)
        countdownButton.tintColor = .white
        countdownButton.isSelected = !countBeforeRecording
        recordingTopView.addSubview(countdownButton)
        countdownButton.addTarget(self, action: #selector(changeCountdownMode(_:)), for: .touchUpInside)
        NSLayoutConstraint.activate([
            countdownButton.centerYAnchor.constraint(equalTo: recordingTopView.centerYAnchor),
            countdownButton.trailingAnchor.constraint(equalTo: cameraPositionButton.leadingAnchor, constant: -16),
            countdownButton.heightAnchor.constraint(equalToConstant: buttonSize),
            countdownButton.widthAnchor.constraint(equalToConstant: buttonSize)
        ])
        
        handPoseButton.translatesAutoresizingMaskIntoConstraints = false
        handPoseButton.setTitle("🤘", for: .normal)
        handPoseButton.setTitle("🙅‍♀️", for: .selected)
        handPoseButton.isSelected = !useHandPoseStartRecording
        recordingTopView.addSubview(handPoseButton)
        handPoseButton.addTarget(self, action: #selector(changeHandPoseMode(_:)), for: .touchUpInside)
        NSLayoutConstraint.activate([
            handPoseButton.centerYAnchor.constraint(equalTo: recordingTopView.centerYAnchor),
            handPoseButton.trailingAnchor.constraint(equalTo: countdownButton.leadingAnchor, constant: -16),
            handPoseButton.heightAnchor.constraint(equalToConstant: buttonSize),
            handPoseButton.widthAnchor.constraint(equalToConstant: buttonSize)
        ])
        
    }
    @objc func changeHandPoseMode(_ sender: UIButton) {
        useHandPoseStartRecording.toggle()
        sender.isSelected = !useHandPoseStartRecording
        if useHandPoseStartRecording {
            addGestureRecognitionToSession()
        } else {
            disableGestureRecognition()
        }
    }

    @objc func changeCountdownMode(_ sender: UIButton) {
        countBeforeRecording.toggle()
        sender.isSelected = !countBeforeRecording
        if !countBeforeRecording {
            stopCountdwonBeforeRecording()
        }
        print("is countBeforeRecording:\(countBeforeRecording)")
    }
    // 按左上角x
    @objc func cancelRecording() {
        resetView()
    }
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
                    print("In configure, players[\(players[index])] playerItem:\(playerItem)")
                }
            } else {
                let player = AVPlayer()
                players.append(player)
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
            containerView.layer.addSublayer(cameraPreviewLayer!)
            cameraPreviewLayer?.frame = containerView.layer.bounds
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

    @objc func toggleCameraPosition(_ sender: UIBarButtonItem) {
        guard !isRecording else {
               print("錄製中，無法切換鏡頭")
               return
           }
        isFrontCamera.toggle()
    }
    func startRecording() {
        isRecording = true
        toggleRecordingButtons(isRecording: isRecording)
        startCountdownTimer()
//        cameraButton.setBackgroundImage(UIImage(systemName: "stop.circle"), for: .normal)
        cameraButton.setBackgroundImage(UIImage(named: "stopButton"), for: .normal)
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
            self.playMusic()
            videoFileOutput?.startRecording(to: outputFileURL, recordingDelegate: self)
        }
    }
    func stopCountdwonBeforeRecording() {
        timerBeforePlay?.invalidate()
        timerBeforePlay = nil
        countdownImageView.isHidden = true
        currentImageIndex = 0
    }
    func startCountdown() {
//        countdownImageView.image = UIImage(systemName: countingImages[currentImageIndex])
        
        timerBeforePlay = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateImage), userInfo: nil, repeats: true)
        }
    func toggleRecordingButtons(isRecording: Bool) {
        musicButton.isHidden = isRecording
        albumButton.isHidden = isRecording
        countdownButton.isHidden = isRecording
        cameraPositionButton.isHidden = isRecording
    }
    @objc func updateImage() {
        print("currentImageIndex:\(currentImageIndex)")
        if currentImageIndex < countingImages.count {
            countdownImageView.isHidden = currentImageIndex == 0
            countdownImageView.image = UIImage(systemName: countingImages[currentImageIndex])
        } else {
            print("invalidate")
            timerBeforePlay?.invalidate()
            timerBeforePlay = nil
            countdownImageView.isHidden = true
            startRecording()
            currentImageIndex = 0
        }
        currentImageIndex += 1
    }
    @IBAction func capture(sender: AnyObject) {
        if !isRecording { // 不在錄音有分兩種，一種是還沒開始，一種是倒數計時被取消錄影
            if timerBeforePlay != nil {
                stopCountdwonBeforeRecording()
                toggleRecordingButtons(isRecording: false)
            } else {
                if countBeforeRecording {
                    startCountdown()
                } else {
                    startRecording()
                }
            }
        } else {
            stopCountdownTimer()
//            cameraButton.setBackgroundImage(UIImage(systemName: "record.circle"), for: .normal)
            cameraButton.setBackgroundImage(UIImage(named: "recordingButton"), for: .normal)
            cameraButton.layer.removeAllAnimations()
            videoFileOutput?.stopRecording()
            isRecording = false
            toggleRecordingButtons(isRecording: isRecording)
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
            if index == 1 && ensembleUserID != nil {
                guard let url = URL(string: ensembleVideoURL!) else {
                    print("ensembleUserID 轉換失敗")
                    return
                }
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
            
        replayButton.isHidden = true
    }
//    func getCropStartTime(for index: Int) -> CMTime? {
//        if index == currentRecordingIndex {
//            return videoTrim.startTime
//        }
//        return nil
//    }

    func setupObserversForPlayerItem(_ playerItem: AVPlayerItem, with player: AVPlayer) {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    func adjustVolumeForRecording() {
        if isHeadphoneConnected == false {
            previousVolume = playerVolume
            print("previousVolume:\(previousVolume)")
            MPVolumeView.setVolume(0.0)
            print("isRecording Volume:\(0.0)")
        } else {
            MPVolumeView.setVolume(previousVolume)
            print("set playerVolume:\(previousVolume)")
        }
    }
    func stopAllVideos() {
        for player in players {
            player.pause()
        }
        musicPlayer?.pause()
        audioPlayer?.pause()
    }
    // 影片播放結束
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
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        playerVolume = previousVolume
        musicPlayer?.pause()
        audioPlayer?.pause()
        print("didFinishRecording，previousVolume:\(previousVolume)")
//        let customAlert = CustomAlertController(title: "影片錄製成功？")
//        customAlert.setOKButtonTitle("確定")
//        customAlert.setAgainButtonTitle("重來")
//        customAlert.onOKPressed = {
//            self.playAllVideos()
//            self.launchTrimTopView()
//        }
//        customAlert.onAgainPressed = {
//            self.countdownLabel.text = self.timeFormatter(sec: self.length)
//            self.clearVideoView(for: self.currentRecordingIndex)
//            self.prepareRecording(for: self.currentRecordingIndex)
//        }
//        customAlert.show()

        let alertViewController = UIAlertController(title: "影片錄製成功？", message: "", preferredStyle: .alert)
        let successAction = UIAlertAction(title: "OK", style: .default) { _ in
            self.playAllVideos()
            self.launchTrimTopView()
        }
        let againAction = UIAlertAction(title: "重來", style: .cancel) { _ in
            self.countdownLabel.text = self.timeFormatter(sec: self.length)
            self.clearVideoView(for: self.currentRecordingIndex)
            self.prepareRecording(for: self.currentRecordingIndex)
        }
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
            headphoneAlertLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            headphoneAlertLabel.heightAnchor.constraint(equalToConstant: 80),
            headphoneAlertLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor)
        ])
        let route = AVAudioSession.sharedInstance().currentRoute
        for output in route.outputs {
            if output.portType == .headphones || output.portType == .bluetoothA2DP || output.portType == .airPlay || output.portType == .usbAudio || output.portType == .HDMI {
                isHeadphoneConnected = true
                if previousVolume == 0 {
                    previousVolume = 0.5
                    MPVolumeView.setVolume(previousVolume)
                }
                break
            } else {
                isHeadphoneConnected = false
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
            isHeadphoneConnected = true
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
                    isHeadphoneConnected = false
                    headphoneAlertLabel.isHidden = false
                }
            }
            print("無耳機")
            headphoneAlertLabel.isHidden = false
            isHeadphoneConnected = false
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
    // TODO: 解決 containerView 跟 startToRecordingView 的位置衝突
   // style 0 的準備錄影（還不是錄影）介面
    @objc func startToRecordingView() {
        if recordingTopView.isHidden {
            recordingTopView.isHidden = false
        } else {
            setupRecordingTopView()
        }
        configure(for: style)
        replayButton.isHidden = true
        postProductionView.isHidden = true
        trimView.isHidden = true
        cameraPreviewLayer?.frame = videoViews[0].bounds
        videoViews[0].layer.addSublayer(cameraPreviewLayer!)
        chooseViewButtons[0].isHidden = true
        
    }
    // TODO: 進入 trimView 之後取消，如果是錄影沒有問題，可以繼續錄。如果用相簿選影片，則 recordingTopView 會不見
    @objc func chooseView(_ sender: UIButton) {
        print("chooseView===========recordingTopView.isHidden:\(recordingTopView.isHidden)")
        print("sender:\(sender)")
        if recordingTopView.isHidden {
            recordingTopView.isHidden = false
//            navigationController?.view.bringSubviewToFront(recordingTopView)
        } else {
            setupRecordingTopView()
        }
        configure(for: style)
        replayButton.isHidden = true
        postProductionView.isHidden = true
        trimView.isHidden = true
        let viewIndex = sender == chooseViewButtons[0] ? 0 : 1
        print("viewIndex:\(viewIndex)")
        currentRecordingIndex = viewIndex
        videoViews[viewIndex].layer.addSublayer(cameraPreviewLayer!)
        cameraPreviewLayer?.frame = videoViews[viewIndex].bounds
        chooseViewButtons[viewIndex].isHidden = true
        let otherIndex = viewIndex == 0 ? 1 : 0

        // 如果是 style 1
        if players.count > 1 && players.count > style {
            
            if let currentItemOfOtherIndex = players[otherIndex].currentItem {
                // otherPlayerHasItem 另一個 player 是否有影片
                let otherPlayerHasItem = players[otherIndex].currentItem != nil &&  currentItemOfOtherIndex.asset.isPlayable
                // 另一個+是否隱藏 = 另一個 player 是否有影片
                chooseViewButtons[otherIndex].isHidden = otherPlayerHasItem
                // 如果另一個+顯示
                if !chooseViewButtons[otherIndex].isHidden {
                    // 拉到最上層
                    containerView.bringSubviewToFront(chooseViewButtons[otherIndex])
                }
            }
        }
    }
    // 按左上角x
    @objc func resetView() {
        recordingTopView.isHidden = true
        postProductionView.isHidden = false
        trimView.isHidden = true
        cameraPreviewLayer?.removeFromSuperlayer()
        for chooseViewButton in chooseViewButtons {
            chooseViewButton.isHidden = false
        }
//        if players.count > 1 {
//            let otherPlayerHasItem = players[otherIndex].currentItem != nil && players[otherIndex].currentItem?.duration.seconds ?? 0 > 0
//            chooseViewButtons[otherIndex].isHidden = otherPlayerHasItem
//        }
    }
    @objc func pushSharePage(_ sender: UIBarButtonItem) {
        guard !videoURLs.isEmpty else {
            print("videoURLs 空的")
            let alert = UIAlertController(title: "請先錄影", message: "點擊 + 鍵開始錄製", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true, completion: nil)
            return
        }
        guard let outputFileURL = outputFileURL, let duration = duration/*, let ensembleUserID = ensembleUserID*/ else {
            print("點擊分享鍵，但輸出失敗")
            let alert = UIAlertController(title: "背景輸出中", message: "請稍等片刻，再嘗試分享", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true, completion: nil)
            return
        }
        mergingAnimation()
        let outputMergedFileURL = URL(fileURLWithPath: NSTemporaryDirectory() + "mergedOutput.mov")
        if style > 0 {
            mergeMedia(videoURLs: videoURLs, audioURLs: audioURLs, outputURL: outputMergedFileURL) { [weak self] success in
                    DispatchQueue.main.async {
                        if success {
                            let shareVC = ShareViewController()
                            shareVC.url = outputMergedFileURL
                            shareVC.duration = duration
                            if let ensembleUserID = self?.ensembleUserID {
                                shareVC.ensembleUserID = ensembleUserID
                            }
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
            shareVC.duration = duration
            navigationController?.pushViewController(shareVC, animated: true)
        }
    }
    func mergingAnimation() {
        if animView == nil {
            animView = LottieAnimationView(name: "Animation00", bundle: .main)
            animView?.frame = CGRect(x: 200, y: 350, width: 300, height: 300)
            animView?.center = self.view.center
            animView?.loopMode = .loop
            animView?.animationSpeed = 2
            self.view.addSubview(animView!)
        }
        animView?.play()
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
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: currentItem, queue: .main) { [weak self] notification in
                    self?.videoDidEnd(notification: notification as NSNotification)
                }
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
        if keyPath == "outputVolume", let volumeChange = change?[.newKey] as? Float {
            playerVolume = volumeChange
            print("playerVolume: \(playerVolume)")
            return
        } //else if keyPath == "status", let playerItem = object as? AVPlayerItem {
//            switch playerItem.status {
//            case .readyToPlay:
//                print("Video is ready to play")
//            case .failed:
//                print("Failed to load video: \(playerItem.error?.localizedDescription ?? "unknown error")")
//            default:
//                print("Video loading...")
//            }
//            return
//        }

        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
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
        let startTime = view.startTime
        let endTime = view.endTime
        updatePlayerRange(for: players[currentRecordingIndex], withStartTime: startTime, endTime: endTime)
    }

    func updatePlayerRange(for player: AVPlayer, withStartTime startTime: CMTime, endTime: CMTime) {
        guard let currentItem = player.currentItem else {
            return
        }
        let asset = currentItem.asset
        
        let duration = CMTimeSubtract(endTime, startTime)
        if CMTimeCompare(duration, .zero) <= 0 {
            print("結束時間必須大於開始時間")
            return
        }
        
        let newRange = CMTimeRange(start: startTime, duration: duration)
        
        let newPlayerItem = AVPlayerItem(asset: asset)
        newPlayerItem.forwardPlaybackEndTime = endTime
        player.replaceCurrentItem(with: newPlayerItem)
        player.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            player.play()
        }
    }

    func videoTrimPlayTimeChange(_ view: VideoTrim) {
        let newTime = CMTime(value: CMTimeValue(view.playTime.value + view.startTime.value), timescale: view.playTime.timescale)
        let player = players[currentRecordingIndex]
        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setupEndTimeObserver(for player: AVPlayer, startTime: CMTime, endTime: CMTime) {
        if let observer = endTimeObservers[player] {
            player.removeTimeObserver(observer)
            endTimeObservers[player] = nil
        }

        let observer = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .global()) { [weak self] time in
            if time >= endTime {
                DispatchQueue.main.async {
                    self?.stopAllVideos()
                    player.seek(to: startTime)
                }
            }
        }

        endTimeObservers[player] = observer
    }
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
    @objc func clearVideoView(for index: Int) {
        replayButton.isHidden = true
        let player = players[index]
        stopAllVideos()
        player.replaceCurrentItem(with: nil)
        print("index: \(index), currentItem: \(player.currentItem ?? nil)")
        playerLayers[index].removeFromSuperlayer()
        if let url = getVideoURL(for: index) {
            do {
                try FileManager.default.removeItem(at: url)
                print("成功清除影片檔案")
                self.videoViewHasContent[self.currentRecordingIndex] = false
            } catch {
                print("清除影片檔案失敗: \(error)")
            }
        }

        videoViews[index].subviews.forEach { subview in
            if let button = subview as? UIButton, chooseViewButtons.contains(button) {
                button.isHidden = false
            }
        }
    }
    // 刪除重錄回到有+的畫面
    @objc func prepareRecording(for index: Int) {
        configure(for: style)
        chooseViewButtons[index].isHidden = false
    }
    @IBAction func selectMusic(_ sender: Any) {
        recordingTopView.isHidden = true
        stopCountdownTimer()
        disableGestureRecognition()
        let controller = MusicViewController()
//        controller.modalPresentationStyle = .fullScreen
        controller.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        controller.modalPresentationStyle = .overCurrentContext
        controller.delegate = self
        present(controller, animated: true)
    }
}

extension CreateViewController: PHPickerViewControllerDelegate {
    @IBAction func selectVideo(_ sender: Any) {
        if videoURLs.count == 0 && currentRecordingIndex == 1 {
            CustomFunc.customAlert(title: "請先完成左側錄影", message: "", vc: self, actionHandler: nil)
        } else {
//            recordingTopView.isHidden = true
            stopCountdownTimer()
            disableGestureRecognition()
            var configuration = PHPickerConfiguration()
            configuration.filter = .videos
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            present(picker, animated: true)
        }
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let provider = results.first?.itemProvider, provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else {
            picker.dismiss(animated: true)
            return
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { (item, error) in
                guard let url = item as? URL, error == nil else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
//                let asset = AVAsset(url: url)
//                let durationInSeconds = CMTimeGetSeconds(asset.duration)
                // TODO: 修正-有時因為還沒得到 duration，先跳出警告
//                if durationInSeconds < 1 {
//                    DispatchQueue.main.async {
//                        self.alertUserForShortVideo(picker: picker)
//                    }
//                    return
//                }
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
               /* try FileManager.default.copyItem(at: url, to: URL(fileURLWithPath: NS*//*TemporaryDirectory() + "output\(self.currentRecordingIndex).mov"))*/
                DispatchQueue.main.async {
                    self.setupPlayer(with: sandboxURL)
//                    self.playAllVideos()
//                    self.recordingTopView.isHidden = false
//                    self.launchTrimTopView()
                    picker.dismiss(animated: true) {
                        self.addGestureRecognitionToSession()
                    }
                }
            } catch {
                print("檔案管理錯誤: \(error)")
            }
        }
    }
//    func alertUserForShortVideo(picker: PHPickerViewController) {
//        let alert = UIAlertController(title: "影片時長過短", message: "請選擇時長超過1秒的影片。", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
//            picker.dismiss(animated: true) {
//            }
//        })
//        picker.present(alert, animated: true)
//    }
    // 設定相簿輸入影片的播放器
    func setupPlayer(with url: URL) {
        recordingTopView.isHidden = false
        replayButton.isHidden = true
        if style == 0 {
            self.cameraPreviewLayer?.removeFromSuperlayer()
        } else {
            if let cameraPreviewLayer = cameraPreviewLayer {
                if cameraPreviewLayer.isPreviewing {
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
        if style == 1 && ensembleVideoURL != nil {
            videoURLs.insert(url, at: 0)
            players[0] = AVPlayer(url: url)
            playerLayers[0] = AVPlayerLayer(player: players[currentRecordingIndex])
            playerLayers[0].frame = videoViews[currentRecordingIndex].bounds
            videoViews[0].layer.addSublayer(playerLayers[currentRecordingIndex])
            playerLayers[0].videoGravity = .resizeAspectFill
            NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(videoDidEnd(notification:)),
                    name: .AVPlayerItemDidPlayToEndTime,
                    object: players[0].currentItem
                )
        } else {
            videoURLs.append(url)
            players[currentRecordingIndex] = AVPlayer(url: url)
            playerLayers[currentRecordingIndex] = AVPlayerLayer(player: players[currentRecordingIndex])
            playerLayers[currentRecordingIndex].frame = videoViews[currentRecordingIndex].bounds
            videoViews[currentRecordingIndex].layer.addSublayer(playerLayers[currentRecordingIndex])
            playerLayers[currentRecordingIndex].videoGravity = .resizeAspectFill
        }
//        let playerItem = AVPlayerItem(url: url) // --
//        setupObserversForPlayerItem(playerItem, with: players[currentRecordingIndex]) // --
        
        launchTrimTopView()
        for player in self.players {
            player.seek(to: CMTime.zero)
            player.play()
        }
    }
}
extension CreateViewController: MusicSelectionDelegate {
    func musicViewController(_ controller: MusicViewController, didSelectMusic music: MusicType) {
        selectedMusic = music
    }

     func playMusic() {
        guard let selectedMusic = selectedMusic else {
            print("No music selected")
            return
        }

        switch selectedMusic {
        case .mp3(let url):
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer.play()
                self.audioPlayer = audioPlayer
            } catch {
                print("Failed to play music from file: \(error)")
            }
        case .appleMusic(let id):
            requestMediaLibraryAccess(id: id)
            print("Apple Music ID: \(id)")
        }
    }
    func requestMediaLibraryAccess(id: String) {
        MPMediaLibrary.requestAuthorization { status in
            if status == .authorized {
                if let id = UInt64(id) {
                    self.fetchMediaItem(usingPersistentID: id)
                }
                
            } else {
                print("Access denied by the user")
            }
        }
    }
    func fetchMediaItem(usingPersistentID persistentID: UInt64) {
        let query = MPMediaQuery()
        let predicate = MPMediaPropertyPredicate(value: persistentID, forProperty: MPMediaItemPropertyPersistentID)
        query.addFilterPredicate(predicate)

        if let items = query.items, let item = items.first {
            let collection = MPMediaItemCollection(items: [item])
            playMediaItemCollection(collection)
        } else {
            print("No items found")
        }
    }
    func playMediaItemCollection(_ collection: MPMediaItemCollection) {
        musicPlayer = MPMusicPlayerController.systemMusicPlayer // .applicationMusicPlayer
        musicPlayer?.setQueue(with: collection)
        musicPlayer?.play()
    }
}
