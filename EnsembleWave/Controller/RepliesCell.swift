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
        guard let font = UIFont(name: "NotoSansTC-Regular", size: 16) else { return }
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .kern: 0,
            .foregroundColor: UIColor.white
        ]
        let attributedTitleString = NSAttributedString(string: "More Replies", attributes: titleAttributes)
//        replyButton.setTitle("More Replies", for: .normal) // \(replyCount) // TODO: 回來調整同步留言數量
        replyButton.addTarget(self, action: #selector(reply), for: .touchUpInside)
//        replyButton.setTitleColor(.white, for: .normal)
//        replyButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        replyButton.setAttributedTitle(attributedTitleString, for: .normal)
        NSLayoutConstraint.activate([
            replyButton.topAnchor.constraint(equalTo: contentView.topAnchor),
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
