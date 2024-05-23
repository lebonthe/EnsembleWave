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
import VideoTrim // 裁切影片
import Vision // 手勢
import PhotosUI // 選取相簿影片
import Lottie // 動畫

class CreateViewController: UIViewController {
    var recSettings = RecordingSettings()
    var cameraViewModel: CameraViewModel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var stretchScreenButton: UIButton!
    @IBOutlet weak var shrinkScreenButton: UIButton!
    var videoFileOutput: AVCaptureMovieFileOutput!
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var players: [AVPlayer] = []
    var playerLayers: [AVPlayerLayer] = []
    var replayButton = UIButton()
    @IBOutlet var containerViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var containerViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerViewRatio: NSLayoutConstraint!
    @IBOutlet weak var headphoneAlertLabel: UILabel!
    var videoViews: [UIView] = []
    let line = UIView()
    var chooseViewButtons = [UIButton]()
    @IBOutlet weak var postProductionView: UIView!
    var outputFileURL: URL?
    var videoURLs: [URL] = []
    var audioURLs: [URL] = []
    var playerVolume: Float = 0.5
    var previousVolume: Float = 0.5
    @IBOutlet weak var trimView: TrimView!
    var endTimeObservers: [AVPlayer: Any] = [:]
    let recordingTopView = RecordingTopView()
    var countdownTimer: Timer?
    var videoViewHasContent: [Int: Bool] = [:]
    lazy var tapGesture00 = UITapGestureRecognizer(target: self, action: #selector(videoViewTapped(_:)))
    lazy var tapGesture01 = UITapGestureRecognizer(target: self, action: #selector(videoViewTapped(_:)))
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
    var restingHand = true
    @IBOutlet weak var cameraBottomView: UIView!
    var video0URL: URL?
    var video1URL: URL?
    var volumeObservation: NSKeyValueObservation?
    override func viewDidLoad() {
        super.viewDidLoad()
        print("===== CreateViewController viewDidLoad =====")
        print("viewDidLoad ensembleVideoURL:\(ensembleVideoURL ?? "no ensembleVideoURL")")
        videoURLs.removeAll()
        setupUI(recSettings.style)
        setupReplayButton()
        bookEarphoneState()
        configurePlayersAndAddObservers()
        clearTemporaryVideos()
        cameraViewModel = CameraViewModel(cameraSessionManager: DefaultCameraSessionManager(), recordingManager: DefaultRecordingManager())
        cameraViewModel.isFrontCamera = true
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("===== CreateViewController viewWillAppear =====")
        recSettings.reset()
        print("style:\(recSettings.style)")
        getCurrentSystemVolume()
        observeVolumeChanges()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("===== CreateViewController viewDidLayoutSubviews =====")
    }
    func stopAnim() {
        animView?.stop()
        animView?.removeFromSuperview()
        animView = nil
    }
    override func viewWillDisappear(_ animated: Bool) {
        recordingTopView.isHidden = true
        for player in players {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        }
        volumeObservation?.invalidate()
        volumeObservation = nil
//        AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
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
        replayButton.isHidden = true
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("===== CreateViewController viewDidDisappear =====")
        //        dchCheckDeallocation()
    }
    override func viewDidAppear(_ animated: Bool) {
        print("===== CreateViewController viewDidAppear =====")
        if ensembleVideoURL != nil && recSettings.style == 1 {
            chooseView(chooseViewButtons[0])
            chooseViewButtons[1].isHidden = true
            videoViewHasContent[1] = true
            videoViews[1].addGestureRecognizer(tapGesture01)
        }
    }
    @objc func preparedToShare() {
        mergingAnimation()
        let asset = AVURLAsset(url: videoURLs[recSettings.currentRecordingIndex])
        let keys = ["tracks"]
        
        asset.loadValuesAsynchronously(forKeys: keys) {
                var error: NSError?
                let status = asset.statusOfValue(forKey: "tracks", error: &error)
                if status == .loaded {
                    if asset.tracks(withMediaType: .video).isEmpty {
                        print("asset 中沒有影片 tracks")
                    } else {
                        DispatchQueue.main.async {
                            self.continuePreparedToShare(with: asset)
                        }
                    }
                } else {
                    print("資源的軌道加載未成功: \(error?.localizedDescription ?? "未知錯誤")")
                }
        }
    }

    func continuePreparedToShare(with asset: AVAsset) {
        setupShareButton()
        
        let startTime = trimView.videoTrim.startTime
        let endTime = trimView.videoTrim.endTime
        
        if let outputURL = getVideoURL(for: recSettings.currentRecordingIndex) {
            print("開始導出到: \(outputURL)")
            do {
                // 如果這個位置已經有檔案存在，導出會失敗，因此要先刪除
                try FileManager.default.removeItem(at: outputURL)
            } catch {
                print("清除舊檔案失敗: \(error.localizedDescription)")
            }
            CreateVideoManager.shared.exportCroppedVideo(asset: asset, startTime: startTime, endTime: endTime, outputURL: outputURL) { success in
                DispatchQueue.main.async {
                    if success {
                        let playerItem = AVPlayerItem(url: outputURL)
                        self.players[self.recSettings.currentRecordingIndex].replaceCurrentItem(with: playerItem)
                        self.players[self.recSettings.currentRecordingIndex].seek(to: CMTime.zero)
                        self.players[self.recSettings.currentRecordingIndex].play()
                        self.replayVideo()
                        self.setupEndTimeObserver(for: self.players[self.recSettings.currentRecordingIndex], startTime: startTime, endTime: endTime)
                        self.setupObserversForPlayerItem(playerItem, with: self.players[self.recSettings.currentRecordingIndex])
                        print("裁剪和導出成功")
                        self.videoViewHasContent[self.recSettings.currentRecordingIndex] = true
                        if self.recSettings.style > 0 {
                            let otherIndex = self.recSettings.currentRecordingIndex == 0 ? 1 : 0
                            if let hasContent = self.videoViewHasContent[otherIndex], hasContent {
                                if otherIndex == 0 {
                                    self.videoViews[otherIndex].addGestureRecognizer(self.tapGesture00)
                                } else if otherIndex == 1 {
                                    self.videoViews[otherIndex].addGestureRecognizer(self.tapGesture01)
                                }
                                print("preparedToShare self.videoViewHasContent[otherIndex]:\(hasContent)")
                            } else {
                                self.chooseViewButtons[otherIndex].isHidden = false
                                print("preparedToShare self.videoViewHasContent[otherIndex]: no")
                            }
                        }
                        if self.recSettings.currentRecordingIndex == 0 {
                            self.videoViews[self.recSettings.currentRecordingIndex].addGestureRecognizer(self.tapGesture00)
                            self.videoViews[0].isUserInteractionEnabled = true
                        } else if self.recSettings.currentRecordingIndex == 1 {
                            self.videoViews[self.recSettings.currentRecordingIndex].addGestureRecognizer(self.tapGesture01)
                            self.videoViews[1].isUserInteractionEnabled = true
                        }
                        print("videoViews[0].subviews:\(self.videoViews[0].subviews)")
                        let durationInSeconds = CMTimeGetSeconds(asset.duration)
                        self.duration = Int(durationInSeconds.rounded())
                        print("儲存的影片長度為: \(self.duration ?? 0) 秒")
                        self.stopAnim()
                    } else {
                        print("裁剪和導出失敗")
                        self.stopAnim()
                        CustomFunc.customAlert(title: "裁剪和導出失敗", message: "再試一次", vc: self, actionHandler: nil)
                    }
                }
            }
        }
    }
    
    @objc func recordAgain() {
        stopAllVideos()
        if recSettings.style == 0 {
            startToRecordingView()
        } else {
            chooseView(chooseViewButtons[recSettings.currentRecordingIndex])
            chooseViewButtons[recSettings.currentRecordingIndex].isHidden = true
        }
        self.navigationItem.leftBarButtonItem = nil
        trimView.isHidden = true
        stopCountdownTimer()
        recordingTopView.countdownLabel.text = TimeFormatter.format(seconds: self.recSettings.length)
        self.clearVideoView(for: self.recSettings.currentRecordingIndex)
        if useHandPoseStartRecording {
            addGestureRecognitionToSession()
        }
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
    func startCountdownTimer() {
        var remainingTime = recSettings.length
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true){ [weak self] _ in
            guard let self = self else { return }
            remainingTime -= 1
            recordingTopView.updateCountdownLabel(remainingTime)
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
    func launchTrimTopView() {
        guard navigationController != nil else {
            print("There is no navigation controller")
            return
        }
        recordingTopView.isHidden = true
        setupTrimView()
    }
    @objc func changeHandPoseMode(_ sender: UIButton) {
        if sender.title(for: .normal) == "🙅‍♀️" {
            sender.setTitle("🤘", for: .normal)
            addGestureRecognitionToSession()
            
        } else {
            sender.setTitle("🙅‍♀️", for: .normal)
            disableGestureRecognition()
        }
        print("Updated Hand Pose Button Title: \(sender.title(for: .normal) ?? "nil")")
        useHandPoseStartRecording.toggle()
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

    func stopCountdwonBeforeRecording() {
        timerBeforePlay?.invalidate()
        timerBeforePlay = nil
        countdownImageView.isHidden = true
        currentImageIndex = 0
    }
    func startCountdown() {
        if useHandPoseStartRecording {
            if let emojiImage = UIImage.from(text: "🤘", font: UIFont.systemFont(ofSize: 50)) {
                countdownImageView.image = emojiImage
                countdownImageView.backgroundColor = .clear
                countdownImageView.isHidden = false
            }
        }
        timerBeforePlay = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateImage), userInfo: nil, repeats: true)
    }
    func toggleRecordingButtons(isRecording: Bool) {
        musicButton.isHidden = recSettings.isRecording
        albumButton.isHidden = recSettings.isRecording
        recordingTopView.countdownButton.isHidden = recSettings.isRecording
        recordingTopView.cameraPositionButton.isHidden = recSettings.isRecording
        recordingTopView.handPoseButton.isHidden = recSettings.isRecording
    }
    @objc func updateImage() {
        print("currentImageIndex:\(currentImageIndex)")
        if currentImageIndex < countingImages.count {
            countdownImageView.isHidden = currentImageIndex == 0
            countdownImageView.backgroundColor = .white
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

    func setupObserversForPlayerItem(_ playerItem: AVPlayerItem, with player: AVPlayer) {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
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
                    recSettings.currentRecordingIndex = 0
                }
                break
            }
        }
    }
}

extension CreateViewController {
    // style 0 的準備錄影（還不是錄影）介面
    @objc func startToRecordingView() {
        if recordingTopView.isHidden {
            recordingTopView.isHidden = false
            recordingTopView.updateCountdownLabel(recSettings.length)
        } else {
            setupRecordingTopView()
        }
        configure(for: recSettings.style)
        replayButton.isHidden = true
        postProductionView.isHidden = true
        trimView.isHidden = true
        cameraPreviewLayer?.frame = videoViews[0].bounds
        if let cameraPreviewLayer = cameraPreviewLayer {
            videoViews[0].layer.addSublayer(cameraPreviewLayer)
        } else {
            print("no cameraPreviewLayer")
        }
        chooseViewButtons[0].isHidden = true
    }
    
    @objc func chooseView(_ sender: UIButton) {
        stopAllVideos()
        print("chooseView===========recordingTopView.isHidden:\(recordingTopView.isHidden)")
        print("sender:\(sender)")
        if recordingTopView.isHidden {
            recordingTopView.isHidden = false
            recordingTopView.updateCountdownLabel(recSettings.length)
            if useHandPoseStartRecording {
                addGestureRecognitionToSession()
            }
        } else {
            setupRecordingTopView()
        }
        configure(for: recSettings.style)
        replayButton.isHidden = true
        postProductionView.isHidden = true
        trimView.isHidden = true
        let viewIndex = sender == chooseViewButtons[0] ? 0 : 1
        print("viewIndex:\(viewIndex)")
        recSettings.currentRecordingIndex = viewIndex
        if cameraViewModel.isFrontCamera {
                cameraViewModel.isFrontCamera = true
            } else {
                cameraViewModel.isFrontCamera = false
            }
        if let cameraPreviewLayer = cameraPreviewLayer {
            videoViews[viewIndex].layer.addSublayer(cameraPreviewLayer)
            cameraPreviewLayer.frame = videoViews[viewIndex].bounds
        } else {
            print("no cameraPreviewLayer")
        }
        chooseViewButtons[viewIndex].isHidden = true
        let otherIndex = viewIndex == 0 ? 1 : 0
        if recSettings.style > 0 {
            videoViews[otherIndex].isUserInteractionEnabled = false
        }
        // 如果是 style 1
        if players.count > 1 && players.count > recSettings.style {
            if videoViewHasContent[otherIndex] == true  {
                if let hasContent = videoViewHasContent[otherIndex], hasContent {
                    self.chooseViewButtons[otherIndex].isHidden = hasContent
                } else {
                    self.containerView.bringSubviewToFront(self.chooseViewButtons[otherIndex])
                }
            } else {
                DispatchQueue.main.async {
                    self.chooseViewButtons[otherIndex].isHidden = false
                    self.containerView.bringSubviewToFront(self.chooseViewButtons[otherIndex])
                }
            }
        }
    }
    @objc func pushSharePage(_ sender: UIBarButtonItem) {
        mergingAnimation()
        guard !videoURLs.isEmpty else {
            print("videoURLs 空的")
            let alert = UIAlertController(title: "請先錄影", message: "點擊 + 鍵開始錄製", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true, completion: nil)
            return
        }
        guard let outputFileURL = outputFileURL, let duration = duration else {
            print("點擊分享鍵，但輸出失敗")
            let alert = UIAlertController(title: "背景輸出中", message: "請稍等片刻，再嘗試分享", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true, completion: nil)
            return
        }
        let outputMergedFileURL = URL(fileURLWithPath: NSTemporaryDirectory() + "mergedOutput.mov")
        if recSettings.style > 0 {
            var videoFrames = [CGRect]()
            for videoView in self.videoViews {
                videoFrames.append(videoView.frame)
            }
            CreateVideoManager.shared.mergeMedia(videoURLs: videoURLs, audioURLs: audioURLs, outputURL: outputMergedFileURL, videoFrames: videoFrames, containerViewFrame: containerView.frame) { [weak self] success in
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
    
    func observeVolumeChanges() {
        let audioSession = AVAudioSession.sharedInstance()
        volumeObservation = audioSession.observe(\.outputVolume, options: [.new]) { [weak self] (audioSession, change) in
            if let newVolume = change.newValue {
                self?.playerVolume = newVolume
                print("playerVolume: \(newVolume)")
            }
        }
    }
}
