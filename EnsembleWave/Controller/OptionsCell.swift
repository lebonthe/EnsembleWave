//
//  OptionsCell.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/17.
//

import UIKit
import FirebaseCore
import FirebaseFirestore

protocol OptionsCellDelegate: AnyObject {
    func updateLikeStatus(postId: String, hasLiked: Bool)
    
    func showReplyPage(from cell: UITableViewCell, cellIndex: Int, postID: String)
}

class OptionsCell: UITableViewCell {
    weak var delegate: OptionsCellDelegate?
    let db = Firestore.firestore()
    var postID: String = ""
    var heartButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    var goToReplyButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    var isUserLiked: Bool = false
    var cellIndex: IndexPath?
    func setupUI() {
        contentView.addSubview(heartButton)
        if isUserLiked {
            heartButton.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .normal)
        } else {
            heartButton.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
        }
        heartButton.tintColor = .red
        heartButton.addTarget(self, action: #selector(tapLike), for: .touchUpInside)
        contentView.addSubview(goToReplyButton)
        goToReplyButton.setBackgroundImage(UIImage(systemName: "message"), for: .normal)
        goToReplyButton.tintColor = .black
        goToReplyButton.addTarget(self, action: #selector(reply), for: .touchUpInside)
        NSLayoutConstraint.activate([
            heartButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            heartButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            heartButton.widthAnchor.constraint(equalToConstant: 36),
            heartButton.heightAnchor.constraint(equalToConstant: 36),
            heartButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            goToReplyButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            goToReplyButton.leadingAnchor.constraint(equalTo: heartButton.trailingAnchor, constant: 16),
            goToReplyButton.widthAnchor.constraint(equalToConstant: 36),
            goToReplyButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)

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
    @objc func tapLike() {
        if isUserLiked {
            isUserLiked = false
            heartButton.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
            // 刪除資料
            deleteLike()
        } else {
            isUserLiked = true
            heartButton.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .normal)
            // 新增資料
            addLike()
        }
    }

    func addLike() {
        let userLikeRef = db.collection("Posts").document(postID).collection("whoLike").document("09876543")// TODO: 回來改使用者 ID
        userLikeRef.setData(["userID": "09876543"]) { [weak self] error in
            if let error = error {
                print("Error adding like: \(error)")
            } else {
                self?.delegate?.updateLikeStatus(postId: self?.postID ?? "", hasLiked: true)
            }
        }
    }

    func deleteLike() {
        let userLikeRef = db.collection("Posts").document(postID).collection("whoLike").document("09876543") // TODO: 回來改使用者 ID
        userLikeRef.delete { [weak self] error in
            if let error = error {
                print("Error removing like: \(error)")
            } else {
                self?.delegate?.updateLikeStatus(postId: self?.postID ?? "", hasLiked: false)
            }
        }
    }

}
