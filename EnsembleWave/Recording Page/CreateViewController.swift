//
//  CreateViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/9.
//

import UIKit
import AVFoundation
import AVKit

class CreateViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var cameraPositionButton: UIBarButtonItem!
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI(style, length)
        
    }
    override func viewWillAppear(_ animated: Bool) {
        print("view width:\(UIScreen.main.bounds.width)")
        print("containerView.frame:\(containerView.frame)")
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configure(position: .front)
    }
    func setupUI(_ style: Int, _ length: Int) {
        print("style in setupUI: \(style)")
        if style == 0 {
            containerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
                containerView.heightAnchor.constraint(equalToConstant: view.bounds.width - 32)
            ])
        }
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cameraButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            cameraButton.heightAnchor.constraint(equalToConstant: 60),
            cameraButton.widthAnchor.constraint(equalToConstant: 60)
        ])
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
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
