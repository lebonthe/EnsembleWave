//
//  VideoCell.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/17.
//

import UIKit
import AVFoundation

class VideoCell: UITableViewCell {
    var urlString: String = ""
    let videoView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    let replayButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    let player = AVPlayer()
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setupUI() {
        contentView.addSubview(videoView)
        contentView.addSubview(replayButton)
        replayButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
        replayButton.tintColor = .gray
        replayButton.isHidden = false
        replayButton.addTarget(self, action: #selector(play), for: .touchUpInside)
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: contentView.topAnchor),
            videoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            videoView.heightAnchor.constraint(equalTo: contentView.widthAnchor),
            replayButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            replayButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            replayButton.heightAnchor.constraint(equalToConstant: 60),
            replayButton.widthAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func configure() {
        let url = URL(string: urlString)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = videoView.bounds
        playerLayer.videoGravity = .resizeAspectFill
        videoView.layer.addSublayer(playerLayer)
        guard let url = url else {
            print("url 生成失敗")
            return
        }
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        setupObserversForPlayerItem(playerItem, with: player)
    }
    @objc func play() {
        let startTime = CMTime(seconds: 0, preferredTimescale: 1)
        player.seek(to: startTime) { [weak self] completed in
            if completed {
                self?.player.play()
                self?.replayButton.isHidden = true
            }
        }
    }
    func setupObserversForPlayerItem(_ playerItem: AVPlayerItem, with player: AVPlayer) {
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    @objc func videoDidEnd(notification: NSNotification) {
        replayButton.isHidden = false
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
