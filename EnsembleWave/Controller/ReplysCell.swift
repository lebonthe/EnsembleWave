//
//  ReplysCell.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/17.
//

import UIKit

class ReplysCell: UITableViewCell {

    var replyButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    var replyContent: [ReplyContent] = []
    func setupUI() {
        contentView.addSubview(replyButton)
        replyButton.setTitle("\(replyContent.count) 更多留言", for: .normal)
        replyButton.setTitleColor(.blue, for: .normal)
        NSLayoutConstraint.activate([
            replyButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            replyButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            replyButton.widthAnchor.constraint(equalToConstant: 100),
//            replyButton.heightAnchor.constraint(equalToConstant: 22),
            replyButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])
    }

}
