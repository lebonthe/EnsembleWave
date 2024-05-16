//
//  UserVideoCell.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/2.
//

import UIKit
import AVKit
import AVFoundation
class UserVideoCell: UICollectionViewCell {
    var videoPlayView: UserVideoPlayerView?
    var urlString: String? {
        didSet {
            if let urlString = urlString, videoPlayView == nil {
                videoPlayView = UserVideoPlayerView(frame: CGRect.zero, urlString: urlString)
                setupViews()
            }
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupViews() {
        if let videoPlayView = videoPlayView {
            contentView.addSubview(videoPlayView)
        }
        videoPlayView?.frame = contentView.bounds
        videoPlayView?.layer.cornerRadius = 8
        videoPlayView?.clipsToBounds = true
    }
    override func layoutSubviews() {
            super.layoutSubviews()
            videoPlayView?.frame = contentView.bounds
        }
}
