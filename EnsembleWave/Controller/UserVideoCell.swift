//
//  UserVideoCell.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/2.
//

import UIKit
import AVKit
import AVFoundation
class UserVideoCell: UITableViewCell {
    var videoPlayView: UserVideoPlayerView?
    var urlString: String?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
        if let urlString = urlString {
            videoPlayView = UserVideoPlayerView(frame: CGRect.zero, urlString: urlString)
        }
            if let videoPlayView = videoPlayView {
                contentView.addSubview(videoPlayView)
            }
            setupViews()
        }
           
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }


    private func setupViews() {
            videoPlayView?.frame = contentView.bounds
        }
    override func layoutSubviews() {
            super.layoutSubviews()
            videoPlayView?.frame = contentView.bounds
        }
}
