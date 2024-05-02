//
//  MusicViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/22.
//

import UIKit
import MediaPlayer
import MobileCoreServices
import UniformTypeIdentifiers
import AVFoundation

protocol MusicSelectionDelegate: AnyObject {
    func musicViewController(_ controller: MusicViewController, didSelectMusic music: MusicType)
}

class MusicViewController: UIViewController {
    var audioPlayer: AVAudioPlayer?
    var timer: Timer?
    var audioFile: AVAudioFile!
    let exitButton = UIButton()
    let titleLabel = UILabel()
    let pickMusicButton = UIButton()
    let musicImageView = UIImageView()
    let songTitleLabel = UILabel()
    
    var playButton = UIButton()
    var pauseButton = UIButton()
    var progressSlider = UISlider()
//
//    var engine = AudioEngine()
//    var player: AudioPlayer!
//    var waveformView: WaveformView!
    var musicPlayer: MPMusicPlayerController?
    weak var delegate: MusicSelectionDelegate?
    var selectedMusic: MusicType?
    private var toggleMusicButton = UISwitch()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAudioSession()
        setupUI()
    }
    func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowBluetooth, .defaultToSpeaker])
            try audioSession.setActive(true)
            print("Audio session is set to allow mixing with other apps.")
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
    func setupUI() {
        view.backgroundColor = .black
        titleLabel.text = "錄影時一邊播放音樂作為參考"
        titleLabel.textColor = .white
        pickMusicButton.setTitle("選取音樂", for: .normal)
        pickMusicButton.tintColor = .white
        pickMusicButton.layer.cornerRadius = 8
        pickMusicButton.backgroundColor = CustomColor.finance2
        pickMusicButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        musicImageView.image = UIImage(systemName: "music.note")
        songTitleLabel.text = ""
        songTitleLabel.textColor = .white
        songTitleLabel.numberOfLines = 0
        view.addSubview(titleLabel)
        view.addSubview(pickMusicButton)
        view.addSubview(musicImageView)
        view.addSubview(songTitleLabel)
        view.addSubview(playButton)
        playButton.setTitle("Play", for: .normal)
        playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
        playButton.backgroundColor = .white
        playButton.layer.cornerRadius = 10
        playButton.setTitleColor(.black, for: .normal)
        playButton.tintColor = CustomColor.finance2
        playButton.addTarget(self, action: #selector(playAudio), for: .touchUpInside)
        view.addSubview(pauseButton)
        pauseButton.setTitle("Pause", for: .normal)
        pauseButton.backgroundColor = .white
        pauseButton.tintColor = CustomColor.finance2
        pauseButton.layer.cornerRadius = 10
        pauseButton.setTitleColor(.black, for: .normal)
        pauseButton.setImage(UIImage(systemName: "pause.circle"), for: .normal)
        pauseButton.addTarget(self, action: #selector(pauseAudio), for: .touchUpInside)
        progressSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        progressSlider.tintColor = CustomColor.gray2
        view.addSubview(progressSlider)
        view.addSubview(exitButton)
        exitButton.setBackgroundImage(UIImage(systemName: "xmark"), for: .normal)
//        exitButton.backgroundColor = .gray
        exitButton.tintColor = CustomColor.red
        exitButton.addTarget(self, action: #selector(leave), for: .touchUpInside)
        view.addSubview(toggleMusicButton)
        toggleMusicButton.isOn = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        pickMusicButton.translatesAutoresizingMaskIntoConstraints = false
        musicImageView.translatesAutoresizingMaskIntoConstraints = false
        songTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        toggleMusicButton.translatesAutoresizingMaskIntoConstraints = false
        let theView = UIView()
        view.addSubview(theView)
        theView.translatesAutoresizingMaskIntoConstraints = false
        theView.backgroundColor = CustomColor.mattBlack
        theView.layer.cornerRadius = 10
        theView.addSubview(exitButton)
        theView.addSubview(titleLabel)
        theView.addSubview(toggleMusicButton)
        theView.addSubview(pickMusicButton)
        theView.addSubview(musicImageView)
        theView.addSubview(songTitleLabel)
        theView.addSubview(playButton)
        theView.addSubview(pauseButton)
        theView.addSubview(progressSlider)
        NSLayoutConstraint.activate([
            theView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 716),
            theView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            theView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            theView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            exitButton.topAnchor.constraint(equalTo: theView.topAnchor, constant: 16),
            exitButton.leadingAnchor.constraint(equalTo: theView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            exitButton.heightAnchor.constraint(equalToConstant: 30),
            titleLabel.topAnchor.constraint(equalTo: exitButton.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            toggleMusicButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            toggleMusicButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 16),
            pickMusicButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            pickMusicButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            pickMusicButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            pickMusicButton.heightAnchor.constraint(equalToConstant: 30),
            
            musicImageView.topAnchor.constraint(equalTo: pickMusicButton.bottomAnchor, constant: 16),
            musicImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            musicImageView.widthAnchor.constraint(equalToConstant: 30),
            musicImageView.heightAnchor.constraint(equalToConstant: 30),
            
            songTitleLabel.centerYAnchor.constraint(equalTo: musicImageView.centerYAnchor),
            songTitleLabel.leadingAnchor.constraint(equalTo: musicImageView.trailingAnchor, constant: 16),
            songTitleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            playButton.topAnchor.constraint(equalTo: songTitleLabel.bottomAnchor, constant: 16),
            playButton.leadingAnchor.constraint(equalTo: musicImageView.trailingAnchor, constant: 16),
            playButton.widthAnchor.constraint(equalToConstant: 80),
            pauseButton.topAnchor.constraint(equalTo: songTitleLabel.bottomAnchor, constant: 16),
            pauseButton.widthAnchor.constraint(equalToConstant: 80),
            
            pauseButton.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 16),
            progressSlider.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 16),
            progressSlider.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            progressSlider.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
        ])
    }
    @objc func buttonTapped(_ sender: UIButton) {
        let controller = UIAlertController(title: "播放音樂來源", message: nil, preferredStyle: .actionSheet)
       
        let actionFile = UIAlertAction(title: "從檔案", style: .default) {_ in
            self.selectMusic()
        }
        let actionaAppleMusic = UIAlertAction(title: "我的音樂", style: .default) { _ in
            self.selectAppleMusic()
        }
        controller.addAction(actionFile)
        controller.addAction(actionaAppleMusic)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        controller.addAction(cancelAction)
        // Check if the device is iPad to configure popover presentation
        if let popoverController = controller.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds 
        }
        present(controller, animated: true)
    }
    
    @objc func playAudio() {
        audioPlayer?.play()
        startTimer()
    }
    
    @objc func pauseAudio() {
        audioPlayer?.pause()
        stopTimer()
    }
    @objc func sliderValueChanged(_ sender: UISlider) {
        if audioPlayer != nil {
               audioPlayer?.currentTime = TimeInterval(sender.value)
           }
    }
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
    @objc func updateSlider() {
        if let player = musicPlayer {
            progressSlider.value = Float(player.currentPlaybackTime)
            print(Float(player.currentPlaybackTime))
        } else {
            progressSlider.value = Float(audioPlayer?.currentTime ?? 0.0)
        }
        
    }
    
    func selectMusic() {
        changePlaySet(set: "File")
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.audio], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        self.present(documentPicker, animated: true)
    }
    func selectAppleMusic() {
        changePlaySet(set: "Apple")
        let mediaPicker = MPMediaPickerController(mediaTypes: .music)
        mediaPicker.delegate = self
        mediaPicker.allowsPickingMultipleItems = false
        mediaPicker.showsCloudItems = false
        self.present(mediaPicker, animated: true)
    }
    func changePlaySet(set: String) {
        if set == "Apple" {
            playButton.removeTarget(self, action: #selector(playAudio), for: .touchUpInside)
            pauseButton.removeTarget(self, action: #selector(pauseAudio), for: .touchUpInside)
            playButton.addTarget(self, action: #selector(playAppleAudio), for: .touchUpInside)
            pauseButton.addTarget(self, action: #selector(pauseAppleAudio), for: .touchUpInside)
        } else {
            playButton.removeTarget(self, action: #selector(playAppleAudio), for: .touchUpInside)
            pauseButton.removeTarget(self, action: #selector(pauseAppleAudio), for: .touchUpInside)
            playButton.addTarget(self, action: #selector(playAudio), for: .touchUpInside)
            pauseButton.addTarget(self, action: #selector(pauseAudio), for: .touchUpInside)
        }
    }
    @objc func playAppleAudio() {
        musicPlayer?.play()
    }

    @objc func pauseAppleAudio() {
        musicPlayer?.pause()
        stopTimer()
    }

    @objc func playbackStateChanged(notification: NSNotification) {
        if let player = notification.object as? MPMusicPlayerController {
            if player.playbackState == .playing {
                
            } else if player.playbackState == .paused {
              
            }
        }
    }

    @objc func leave() {
        if let selectedMusic = selectedMusic, toggleMusicButton.isOn {
            delegate?.musicViewController(self, didSelectMusic: selectedMusic)
            print("selectedMusic:\(selectedMusic)")
        }
        audioPlayer?.stop()
        musicPlayer?.stop()
        dismiss(animated: true)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .MPMusicPlayerControllerPlaybackStateDidChange, object: musicPlayer)
        musicPlayer?.endGeneratingPlaybackNotifications()
        print("===== MusicViewController deinit =====")
    }

}
extension MusicViewController: MPMediaPickerControllerDelegate {
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        guard let mediaItem = mediaItemCollection.items.first else {
                mediaPicker.dismiss(animated: true)
                return
            }
        let persistentID = String(mediaItem.persistentID)
            selectedMusic = .appleMusic(id: persistentID)
        mediaPicker.dismiss(animated: true)
        musicPlayer = MPMusicPlayerController.applicationMusicPlayer
        musicPlayer?.setQueue(with: mediaItemCollection)
        songTitleLabel.text = mediaItem.title
        progressSlider.isHidden = true
        musicPlayer?.play()
        startTimer()
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStateChanged), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: musicPlayer)
        
        musicPlayer?.beginGeneratingPlaybackNotifications()
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true)
        
    }
}
extension MusicViewController: UIDocumentPickerDelegate, AVAudioPlayerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        selectedMusic = .mp3(url: url)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
           
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            progressSlider.isHidden = false
            progressSlider.maximumValue = Float(audioPlayer?.duration ?? 0.0)
            
            songTitleLabel.text = url.lastPathComponent
            
            audioFile = try AVAudioFile(forReading: url)
            
        } catch {
            print("Error loading audio: \(error.localizedDescription)")
        }
    }
}
