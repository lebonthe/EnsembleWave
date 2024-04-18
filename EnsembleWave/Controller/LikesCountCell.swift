//
//  LikesCountCell.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/17.
//

import UIKit

class LikesCountCell: UITableViewCell {

    var likeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var likesCount = 0
    func setupUI() {
        contentView.addSubview(likeLabel)
        likeLabel.text = "\(likesCount) 讚"
        NSLayoutConstraint.activate([
            likeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            likeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            likeLabel.widthAnchor.constraint(equalToConstant: 100),
            likeLabel.heightAnchor.constraint(equalToConstant: 22),
            likeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])
    }
}
