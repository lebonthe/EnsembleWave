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
//    @IBOutlet private var containerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerViewRatio: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI(style, length)
        setupReplayButton()
        print("length: \(length)")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("viewDidLayoutSubviews cameraPreviewLayer?.frame,\(cameraPreviewLayer?.frame)")
}
    
    override func viewWillAppear(_ animated: Bool) {
        print("view width:\(UIScreen.main.bounds.width)")
        print("containerView.frame:\(containerView.frame)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configure(position: .front)
        print("viewDidAppear view width:\(UIScreen.main.bounds.width)")
        print("viewDidAppear containerView.frame:\(containerView.frame)")
        
    }
    func setupUI(_ style: Int, _ length: Int) {
        print("style in setupUI: \(style)")
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
//        containerViewHeightConstraint.constant = view.bounds.width - 32
        
        if style == 0 {
            containerViewLeadingConstraint.constant = 16
            containerViewTrailingConstraint.constant = -16
            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
            ])
        }
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        stretchScreenButton.translatesAutoresizingMaskIntoConstraints = false
        shrinkScreenButton.translatesAutoresizingMaskIntoConstraints = false
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
        containerView.layer.addSublayer(cameraPreviewLayer!)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.frame = containerView.layer.bounds
        print("初始 layer:\(cameraPreviewLayer?.frame)")
        containerView.clipsToBounds = true
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    @IBAction func toggleCameraPosition(_ sender: UIBarButtonItem) {
        isFrontCamera.toggle()
        print("Camera Position Toggled!")
        print("containerView.frame:\(containerView.frame)")
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

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "playVideo" {
//            let videoPlayerViewController = segue.destination as! AVPlayerViewController
//            let videoFileURL = sender as! URL
//            videoPlayerViewController.player = AVPlayer(url: videoFileURL)
//        }
//    }

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
//            self.performSegue(withIdentifier: "playVideo", sender: outputFileURL)
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
//                self.containerView.layoutIfNeeded()
                self.view.layoutIfNeeded()
                self.cameraPreviewLayer?.frame = self.containerView.layer.bounds
            }
            print("放大 cameraPreviewLayer?.frame,\(cameraPreviewLayer?.frame)")
        } else {
            stretchScreenButton.isHidden = false
            shrinkScreenButton.isHidden = true
            self.containerViewLeadingConstraint.constant = 16
            self.containerViewTrailingConstraint.constant = -16
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
//                self.containerView.layoutIfNeeded()
            }
            print("一般 cameraPreviewLayer?.frame,\(cameraPreviewLayer?.frame)")
        }
    }
    func setupCutting() {
        
    }
}
