//
//  VideoCell.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/17.
//
// TODO: 改善 cache 重複載入的問題
import UIKit
import AVFoundation
import Kingfisher
class VideoCell: UITableViewCell {
    var urlString: String? {
        didSet {
            configurePlayer()
        }
    }
    var imageURLString: String? {
        didSet {
            configureImageView() 
        }
    }
    
    var localVideoURL: URL?
    let videoView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    let replayButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
        button.alpha = 0.35
        button.tintColor = .lightGray
        return button
    }()
    var playerLayer: AVPlayerLayer?
    var player = AVPlayer()
    var isPlaying: Bool = false
    var currentTime: CMTime? = CMTime.zero
    var downloadSession: AVAssetDownloadURLSession?
    var activeDownloadTask: AVAssetDownloadTask?
    var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    func setupUI() {
        videoView.frame = contentView.bounds
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(togglePlayPause))
        videoView.addGestureRecognizer(tapGesture)
        videoView.isUserInteractionEnabled = true
        contentView.addSubview(videoView)
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(replayButton)
        thumbnailImageView.clipsToBounds = true
        replayButton.isHidden = false
        replayButton.addTarget(self, action: #selector(play), for: .touchUpInside)
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: contentView.topAnchor),
            videoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            videoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            thumbnailImageView.topAnchor.constraint(equalTo: videoView.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: videoView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: videoView.trailingAnchor),
            thumbnailImageView.bottomAnchor.constraint(equalTo: videoView.bottomAnchor),
            replayButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            replayButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            replayButton.widthAnchor.constraint(equalToConstant: 60),
            replayButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        videoView.backgroundColor = .black
        
        videoView.clipsToBounds = true
        videoView.layer.masksToBounds = true
        contentView.backgroundColor = .black
        contentView.tintColor = .black
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 15
        videoView.layer.cornerRadius = 15
        thumbnailImageView.layer.cornerRadius = 15
    }
    
    func configureImageView() {
        if let imageURLString =  imageURLString,
           let imageURL = URL(string: imageURLString) {
            thumbnailImageView.isHidden = false
            thumbnailImageView.kf.setImage(
                with: imageURL
            )
        } else {
            thumbnailImageView.image = nil
            thumbnailImageView.isHidden = true
        }
    }
    
    func configurePlayer() {
//        guard let urlString = urlString,
//              let url = URL(string: urlString) else {
//            print("Invalid URL string")
//            return
//        }
//        
//        let asset = AVURLAsset(url: url, options: nil)
//        if CachingPlayerItem.isDownloaded(for: url) {
//            
//            localVideoURL = CachingPlayerItem.localFileURL(for: asset.url)
//            guard let localVideoURL = localVideoURL else {
//                print("no localVideoURL")
//                return
//            }
//            let cachedAsset = AVURLAsset(url: localVideoURL)
//            let playerItem = AVPlayerItem(asset: cachedAsset)
//            player.replaceCurrentItem(with: playerItem)
//            setupObserversForPlayerItem(playerItem, with: player)
//        } else {
//            startDownload(asset: asset)
//            let playerItem = AVPlayerItem(asset: asset)
//            player.replaceCurrentItem(with: playerItem)
//            setupObserversForPlayerItem(playerItem, with: player)
//                }
        guard let urlString = urlString, let url = URL(string: urlString) else {
                print("Invalid URL string")
                return
            }

            let localURL = CachingPlayerItem.localFileURL(for: url)
        print("url:\(url)")
        print("localURL:\(localURL)")
        
            if CachingPlayerItem.isDownloaded(for: url) {
                let cachedAsset = AVURLAsset(url: localURL, options: nil)
                let playerItem = AVPlayerItem(asset: cachedAsset)
                player.replaceCurrentItem(with: playerItem)
                setupObserversForPlayerItem(playerItem, with: player)
            } else {
                let asset = AVURLAsset(url: url, options: nil)
                startDownload(asset: asset)
                let playerItem = AVPlayerItem(asset: asset)
                player.replaceCurrentItem(with: playerItem)
                setupObserversForPlayerItem(playerItem, with: player)
            }
//        guard let localVideoURL = self.localVideoURL else {
//            print("no localVideoURL")
//            return
//        }
//        let cachedAsset = AVURLAsset(url: localVideoURL)
//        let playerItem = AVPlayerItem(asset: cachedAsset)
//        player.replaceCurrentItem(with: playerItem)
//        setupObserversForPlayerItem(playerItem, with: player)
        if playerLayer == nil {
            playerLayer = AVPlayerLayer(player: player)
        }
        playerLayer?.frame = videoView.bounds
        playerLayer?.videoGravity = .resizeAspectFill
        
        if let layer = playerLayer {
            videoView.layer.addSublayer(layer)
            layer.masksToBounds = true
        }
        
        if let currentTime = currentTime {
            player.seek(to: currentTime, completionHandler: { _ in
                if self.isPlaying {
                    self.player.play()
                }
            })
        }
    }
    @objc func togglePlayPause() {
        if player.timeControlStatus == .paused {
            player.play()
            isPlaying = true
            replayButton.isHidden = true
            thumbnailImageView.isHidden = true
        } else {
            player.pause()
            isPlaying = false
            replayButton.isHidden = false
            thumbnailImageView.isHidden = false
        }
    }
    func willDisplay() {
        if !isPlaying {
            player.play()
            isPlaying = true
        }
    }
    
    func didEndDisplaying() {
        player.pause()
        isPlaying = false
    }
    
    func startDownload(asset: AVURLAsset) {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.yourapp.videodownload")
        downloadSession = AVAssetDownloadURLSession(configuration: configuration, assetDownloadDelegate: nil, delegateQueue: OperationQueue())
        let options = [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265_000]
        
        activeDownloadTask = downloadSession?.makeAssetDownloadTask(asset: asset, assetTitle: "Video", assetArtworkData: nil, options: options)
        activeDownloadTask?.resume()
        }
//    func startDownload(asset: AVURLAsset) {
//        let downloadTask = URLSession.shared.downloadTask(with: asset.url) { [weak self] location, response, error in
//            guard let self = self, let location = location else {
//                print("Download error: \(error?.localizedDescription ?? "unknown error")")
//                return
//            }
//            
//            let fileManager = FileManager.default
//            let localURL = CachingPlayerItem.localFileURL(for: asset.url)
//            do {
//                if fileManager.fileExists(atPath: localURL.path) {
//                    try fileManager.removeItem(at: localURL)
//                }
//                try fileManager.moveItem(at: location, to: localURL)
//            } catch {
//                print("File moving error: \(error)")
//                return
//            }
//            
//            DispatchQueue.main.async {
//                self.localVideoURL = localURL
//                self.configurePlayer()
//            }
//        }
//        downloadTask.resume()
//    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = videoView.bounds
        contentView.clipsToBounds = true
    }

    @objc func play() {
        player.play()
        replayButton.isHidden = true
        thumbnailImageView.isHidden = true
    }
    func setupObserversForPlayerItem(_ playerItem: AVPlayerItem, with player: AVPlayer) {
            NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        }
    @objc func videoDidEnd(notification: NSNotification) {
        replayButton.isHidden = false
        player.seek(to: .zero)
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        player.pause()
        isPlaying = false
        currentTime = player.currentTime()
        playerLayer = nil
        player.replaceCurrentItem(with: nil)
        thumbnailImageView.kf.cancelDownloadTask()
        thumbnailImageView.isHidden = true
    }

    deinit {
            NotificationCenter.default.removeObserver(self)
        }
}

//class CachingPlayerItem {
//    static func isDownloaded(for url: URL) -> Bool {
//        return FileManager.default.fileExists(atPath: localFileURL(for: url).path)
//    }
////    static func localFileURL(for url: URL) -> URL {
////        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
////        let fileName = url.lastPathComponent
////        print("localFileURL:\(documentsPath.appendingPathComponent(fileName))")
////        return documentsPath.appendingPathComponent(fileName)
////    }
//    static func localFileURL(for url: URL) -> URL {
//        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//        let fileName = "\(url.hashValue).mov"
//        return documentsPath.appendingPathComponent(fileName)
//    }
//
//}
class CachingPlayerItem {
    static func localFileURL(for url: URL) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = url.absoluteString.md5 + ".mov"
        return documentsPath.appendingPathComponent(fileName)
    }

    static func isDownloaded(for url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: localFileURL(for: url).path)
    }
}
