//
//  RepliesCell.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/17.
//

import UIKit

class RepliesCell: UITableViewCell {

    var replyButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    var replyCount = 0
    weak var delegate: OptionsCellDelegate?
    var postID: String = ""
    var cellIndex: IndexPath?
    func setupUI() {
        contentView.addSubview(replyButton)
        replyButton.setTitle("\(replyCount) 更多留言", for: .normal)
        replyButton.addTarget(self, action: #selector(reply), for: .touchUpInside)
        replyButton.setTitleColor(.blue, for: .normal)
        NSLayoutConstraint.activate([
            replyButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            replyButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            replyButton.widthAnchor.constraint(equalToConstant: 100),
//            replyButton.heightAnchor.constraint(equalToConstant: 22),
            replyButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])
    }
    @objc func reply() {
        guard let cellIndex = cellIndex else {
            print("no cellIndex")
            return
        }
        print("postID:\(postID)")
        delegate?.showReplyPage(from: self, cellIndex: cellIndex.section, postID: postID)
    }
}