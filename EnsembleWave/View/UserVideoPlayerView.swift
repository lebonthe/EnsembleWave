//
//  UserVideoPlayerView.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/2.
//

import UIKit
import AVFoundation
class UserVideoPlayerView: UIView {
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    let playPauseButton = UIButton()

    init(frame: CGRect, urlString: String) {
            super.init(frame: frame)
            setupPlayer(urlString: urlString)
            setupPlayPauseButton()
        }
    
    required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    private func setupPlayer(urlString: String) {
        let videoURL = URL(string: "\(urlString)")!
        player = AVPlayer(url: videoURL)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = bounds
        playerLayer?.videoGravity = .resizeAspect
        if let playerLayer = playerLayer {
            layer.addSublayer(playerLayer)
        }
    }

    private func setupPlayPauseButton() {
        playPauseButton.frame = CGRect(x: 20, y: 20, width: 60, height: 60)
        playPauseButton.setImage(UIImage(systemName: "play"), for: .normal)
//        playPauseButton.setTitle("播放", for: .normal)
//        playPauseButton.backgroundColor = .blue
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        addSubview(playPauseButton)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playPauseButton.topAnchor.constraint(equalTo: self.topAnchor),
            playPauseButton.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }

    @objc func togglePlayPause() {
        if player?.rate == 0 {
            player?.play()
//            playPauseButton.setTitle("暫停", for: .normal)
            playPauseButton.setImage(UIImage(systemName: "pause"), for: .normal)
        } else {
            player?.pause()
//            playPauseButton.setTitle("播放", for: .normal)
            playPauseButton.setImage(UIImage(systemName: "play"), for: .normal)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
    
}
