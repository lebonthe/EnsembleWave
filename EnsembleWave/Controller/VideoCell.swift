//
//  VideoCell.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/17.
//

import UIKit
import AVFoundation

class VideoCell: UITableViewCell {
    var urlString: String? {
        didSet {
            configurePlayer()
        }
    }
    let videoView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    let replayButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "play.circle"), for: .normal)
        button.tintColor = .gray
        return button
    }()
    var playerLayer: AVPlayerLayer?
    let player = AVPlayer()

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    func setupUI() {
        contentView.addSubview(videoView)
        contentView.addSubview(replayButton)
        replayButton.isHidden = false
        replayButton.addTarget(self, action: #selector(play), for: .touchUpInside)

        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: contentView.topAnchor),
            videoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            videoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            replayButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            replayButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            replayButton.widthAnchor.constraint(equalToConstant: 60),
            replayButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    func configurePlayer() {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            print("Invalid URL string")
            return
        }
        if playerLayer == nil {
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.videoGravity = .resizeAspect
            if let layer = playerLayer {
                videoView.layer.addSublayer(layer)
            }
        }
        playerLayer?.frame = videoView.bounds
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        setupObserversForPlayerItem(playerItem, with: player)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = videoView.bounds
    }

    @objc func play() {
        player.play()
        replayButton.isHidden = true
    }
    func setupObserversForPlayerItem(_ playerItem: AVPlayerItem, with player: AVPlayer) {
            NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        }
    @objc func videoDidEnd(notification: NSNotification) {
        replayButton.isHidden = false
    }
    deinit {
            NotificationCenter.default.removeObserver(self)
        }
}
