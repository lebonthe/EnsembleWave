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
        contentView.backgroundColor = .black
//        replyButton.setTitle("More Replies", for: .normal) // \(replyCount) // TODO: 回來調整同步留言數量
        replyButton.setAttributedTitle(attributedTextForm(content: "More Replies", size: 18, kern: 0, color: UIColor.white), for: .normal)
        replyButton.addTarget(self, action: #selector(reply), for: .touchUpInside)
        replyButton.setTitleColor(.white, for: .normal)
        replyButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        NSLayoutConstraint.activate([
            replyButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            replyButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            replyButton.widthAnchor.constraint(equalToConstant: 150),
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
