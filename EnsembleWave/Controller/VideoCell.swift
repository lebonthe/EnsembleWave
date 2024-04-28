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
    var downloadSession: AVAssetDownloadURLSession?
    var activeDownloadTask: AVAssetDownloadTask?
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        setupUI()
//    }

    func setupUI() {
        contentView.backgroundColor = .black
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
        let asset = AVURLAsset(url: url)
        if CachingPlayerItem.isDownloaded(for: asset.url) {
            let localURL = CachingPlayerItem.localFileURL(for: url)
            let cachedAsset = AVURLAsset(url: url)
            let playerItem = AVPlayerItem(asset: cachedAsset)
            player.replaceCurrentItem(with: playerItem)
            setupObserversForPlayerItem(playerItem, with: player)
        } else {
            startDownload(asset: asset)
            let playerItem = AVPlayerItem(asset: asset)
            player.replaceCurrentItem(with: playerItem)
            setupObserversForPlayerItem(playerItem, with: player)
        }
        
        if playerLayer == nil {
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.videoGravity = .resizeAspectFill
            if let layer = playerLayer {
                videoView.layer.addSublayer(layer)
            }
        }
        playerLayer?.frame = videoView.bounds
//        let playerItem = AVPlayerItem(url: url)
//        player.replaceCurrentItem(with: playerItem)
        
    }
    func startDownload(asset: AVURLAsset) {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.yourapp.videodownload")
        downloadSession = AVAssetDownloadURLSession(configuration: configuration, assetDownloadDelegate: nil, delegateQueue: OperationQueue())
        let options = [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265_000]
        
        activeDownloadTask = downloadSession?.makeAssetDownloadTask(asset: asset, assetTitle: "Video", assetArtworkData: nil, options: options)
        activeDownloadTask?.resume()
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

class CachingPlayerItem {
    static func isDownloaded(for url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: localFileURL(for: url).path)
    }

    static func localFileURL(for url: URL) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = url.lastPathComponent
        return documentsPath.appendingPathComponent(fileName)
    }
}
