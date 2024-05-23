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
        self.backgroundColor = .black
            setupPlayer(urlString: urlString)
            setupPlayPauseButton()
        }
    
    required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    private func setupPlayer(urlString: String) {
        let videoURL = URL(string: urlString)!
        player = AVPlayer(url: videoURL)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = bounds
        playerLayer?.videoGravity = .resizeAspectFill
        if let playerLayer = playerLayer {
            layer.addSublayer(playerLayer)
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        PlayerManager.shared.registerPlayer(player!, delegate: self)
    }
    
    @objc private func playerDidFinishPlaying(note: NSNotification) {
        player?.seek(to: CMTime.zero)
        player?.pause()
        playPauseButton.setImage(UIImage(systemName: "play"), for: .normal)
    }
    private func setupPlayPauseButton() {
        playPauseButton.frame = CGRect(x: 20, y: 20, width: 60, height: 60)
        playPauseButton.setImage(UIImage(systemName: "play"), for: .normal)
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        addSubview(playPauseButton)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playPauseButton.topAnchor.constraint(equalTo: self.topAnchor),
            playPauseButton.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }

    @objc func togglePlayPause() {
        guard let player = player else { return }
        if player.rate == 0 {
            if player.currentItem?.status == .readyToPlay, let duration = player.currentItem?.duration {
                let currentTime = player.currentTime()
                if currentTime == duration {
                    player.seek(to: .zero)
                }
            }
            PlayerManager.shared.play(player: player)
            playPauseButton.setImage(UIImage(systemName: "pause"), for: .normal)
        } else {
            player.pause()
            playPauseButton.setImage(UIImage(systemName: "play"), for: .normal)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if let player = player {
            PlayerManager.shared.unregisterPlayer(player)
        }
    }
}
extension UserVideoPlayerView: PlayerManagerDelegate {
    func playerDidPause() {
        playPauseButton.setImage(UIImage(systemName: "play"), for: .normal)
        print("playerDidPause")
        }
    
    func playerDidPlay() {
        playPauseButton.setImage(UIImage(systemName: "pause"), for: .normal)
        print("playerDidPlay")
    }
}
