//
//  OptionsCell.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/17.
//

import UIKit
import FirebaseCore
import FirebaseFirestore

class OptionsCell: UITableViewCell {
    let db = Firestore.firestore()
    var postID: String = ""
    var heartButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    var isUserLiked: Bool = false
    func setupUI() {
        contentView.addSubview(heartButton)
        if isUserLiked {
            heartButton.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .normal)
        } else {
            heartButton.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
        }
        heartButton.tintColor = .red
        heartButton.addTarget(self, action: #selector(tapLike), for: .touchUpInside)
        NSLayoutConstraint.activate([
            heartButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            heartButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            heartButton.widthAnchor.constraint(equalToConstant: 36),
//            heartButton.heightAnchor.constraint(equalToConstant: 36),
            heartButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])
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
        // TODO: 回來改 user id 使用者ID
        db.collection("Posts").document("\(postID)").collection("whoLike").document("09876543").setData(["userID":"09876543"])
    }
    func deleteLike() {
        guard !postID.isEmpty else {
            print("Error: postID is empty")
            return
        }

        let userId = "09876543" // TODO: 回來改使用者 ID
        let userLikeRef = db.collection("Posts").document(postID).collection("whoLike").document(userId)
        
        userLikeRef.delete() { error in
            if let error = error {
                print("Error removing like: \(error)")
            } else {
                print("Like successfully removed.")
            }
        }
    }
}
