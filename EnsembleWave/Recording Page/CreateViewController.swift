//
//  CreateViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/9.
//

import UIKit
import AVFoundation // 錄影
import AVKit // 播放影像

class CreateViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var cameraPositionButton: UIBarButtonItem!
    @IBOutlet weak var stretchScreenButton: UIButton!
    
    @IBOutlet weak var shrinkScreenButton: UIButton!
    var style = 0
    var length = 15
    var isFrontCamera: Bool = true {
        didSet {
            if isFrontCamera {
                configure(position: .front)
            } else {
                configure(position: .back)
            }
        }
    }
    let captureSession = AVCaptureSession()
    var currentDevice: AVCaptureDevice!
    var videoFileOutput: AVCaptureMovieFileOutput!
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var isRecording = false
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var replayButton = UIButton()
    @IBOutlet private var containerViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var containerViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerViewRatio: NSLayoutConstraint!
    
   
    @IBOutlet weak var headphoneAlertLabel: UILabel!
    let leftView = UIView()
    let rightView = UIView()
    let line = UIView()
    var chooseViewButtons = [UIButton]()
    
    
    
    @IBOutlet weak var postProductionView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI(style, length)
        setupReplayButton()
        bookEarphoneState()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
     
}
    
    override func viewWillAppear(_ animated: Bool) {

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configure(position: .front)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
    }
    func setupUI(_ style: Int, _ length: Int) {
        print("style in setupUI: \(style)")
        containerView.layer.borderColor = UIColor.black.cgColor
        containerView.layer.borderWidth = 2
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerViewLeadingConstraint.constant = 16
        containerViewTrailingConstraint.constant = -16
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
        if style == 0 {

        } else if style == 1 {
            leftView.backgroundColor = .systemGray4
            rightView.backgroundColor = .systemGray4
            line.backgroundColor = .black
            containerView.addSubview(leftView)
            containerView.addSubview(rightView)
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
            leftView.translatesAutoresizingMaskIntoConstraints = false
            rightView.translatesAutoresizingMaskIntoConstraints = false
            line.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                line.widthAnchor.constraint(equalToConstant: 2),
                line.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                line.topAnchor.constraint(equalTo: containerView.topAnchor),
                line.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                leftView.topAnchor.constraint(equalTo: containerView.topAnchor),
                leftView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                leftView.trailingAnchor.constraint(equalTo: line.leadingAnchor),
                leftView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                rightView.topAnchor.constraint(equalTo: containerView.topAnchor),
                rightView.leadingAnchor.constraint(equalTo: line.trailingAnchor),
                rightView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                rightView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                chooseViewButtons[0].centerXAnchor.constraint(equalTo: leftView.centerXAnchor),
                chooseViewButtons[0].centerYAnchor.constraint(equalTo: leftView.centerYAnchor),
                chooseViewButtons[0].widthAnchor.constraint(equalToConstant: 40),
                chooseViewButtons[0].heightAnchor.constraint(equalToConstant: 40),
                chooseViewButtons[1].centerXAnchor.constraint(equalTo: rightView.centerXAnchor),
                chooseViewButtons[1].centerYAnchor.constraint(equalTo: rightView.centerYAnchor),
                chooseViewButtons[1].widthAnchor.constraint(equalToConstant: 40),
                chooseViewButtons[1].heightAnchor.constraint(equalToConstant: 40),
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
    func configure(position: AVCaptureDevice.Position) {
        if captureSession.isRunning {
                captureSession.stopRunning()
            }
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            print("Failed to get the camera device")
            return
        }
        currentDevice = device
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
        
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.frame = containerView.layer.bounds
        containerView.clipsToBounds = true
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    @IBAction func toggleCameraPosition(_ sender: UIBarButtonItem) {
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
            let outputPath = NSTemporaryDirectory() + "output.mov"
            let outputFileURL = URL(fileURLWithPath: outputPath)
            videoFileOutput?.startRecording(to: outputFileURL, recordingDelegate: self)
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

    func playVideo(url: URL) {
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = containerView.bounds
        playerLayer?.videoGravity = .resizeAspectFill
        if let playerLayer = self.playerLayer {
            containerView.layer.addSublayer(playerLayer)
        }
        replayButton.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        player?.play()
    }
    @objc func videoDidEnd(notification: NSNotification) {
        replayButton.isHidden = false
        containerView.bringSubviewToFront(replayButton)
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
            self.playVideo(url: outputFileURL)
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
//        replayButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
        replayButton.setBackgroundImage(UIImage(systemName: "play.circle"), for: .normal)
        replayButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
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
            if let player = player {
                    player.seek(to: .zero)
                    player.play()
                    replayButton.isHidden = true
                }
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
    @objc func chooseView(_ sender: UIButton) {
        postProductionView.isHidden = true
        if sender == chooseViewButtons[0] {
            leftView.layer.addSublayer(cameraPreviewLayer!)
            chooseViewButtons[0].isHidden = true
            chooseViewButtons[1].isHidden = false
        } else if sender == chooseViewButtons[1] {
            rightView.layer.addSublayer(cameraPreviewLayer!)
            chooseViewButtons[0].isHidden = false
            chooseViewButtons[1].isHidden = true
        }
    }
}
