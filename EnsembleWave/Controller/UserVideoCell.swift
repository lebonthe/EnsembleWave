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
    let videoPlayView = VideoPlayerView
    let customLabel = UILabel()
    override init(frame: CGRect) {
           super.init(frame: frame)
           setupViews()
       }
       
       required init?(coder aDecoder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
       }

    private func setupViews() {
            // 配置 customLabel
            customLabel.frame = CGRect(x: 10, y: 10, width: self.bounds.width - 20, height: 20)
            customLabel.textAlignment = .center
            contentView.addSubview(customLabel)

            // 配置 customImageView
            customImageView.frame = CGRect(x: 10, y: 40, width: self.bounds.width - 20, height: self.bounds.height - 50)
            customImageView.contentMode = .scaleAspectFit
            contentView.addSubview(customImageView)
        }
}
