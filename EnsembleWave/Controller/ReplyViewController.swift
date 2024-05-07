//
//  ReplyViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/21.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
class ReplyViewController: UIViewController {
    var replies: [ReplyContent] = []
    var postID: String?
    let tableView = UITableView()
    let textView = UIView()
    let textField = UITextField()
    let enterButton = UIButton()
    let db = Firestore.firestore()
    var usersNames: [String: String] = [:]
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        tableView.delegate = self
        tableView.dataSource = self
        print("replies:\(replies)")
        listenToReplies()
        tableView.register(ReplyDetailTableViewCell.self, forCellReuseIdentifier: "\(ReplyDetailTableViewCell.self)")
    }
    
    func setupUI() {
        view.backgroundColor = .black
        self.title = "留言"
        view.addSubview(tableView)
        textView.backgroundColor = .white
        view.addSubview(textView)
        textField.backgroundColor = CustomColor.black
        textField.textColor = .white
        textView.addSubview(textField)
        enterButton.backgroundColor = CustomColor.black
        enterButton.tintColor = CustomColor.red
        enterButton.setBackgroundImage(UIImage(systemName: "arrow.turn.down.left"), for: .normal)
        enterButton.addTarget(self, action: #selector(sendReply), for: .touchUpInside)
        textView.addSubview(enterButton)
        tableView.backgroundColor = .black
        tableView.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        enterButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            textView.heightAnchor.constraint(equalToConstant: 60),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: textView.topAnchor),
            enterButton.topAnchor.constraint(equalTo: textView.topAnchor, constant: 6),
            enterButton.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -6),
            enterButton.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: -6),
            enterButton.widthAnchor.constraint(equalToConstant: 60),
            textField.topAnchor.constraint(equalTo: textView.topAnchor, constant: 6),
            textField.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 6),
            textField.trailingAnchor.constraint(equalTo: enterButton.leadingAnchor, constant: -6),
            textField.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: -6)
        ])
    }
    
    @objc func sendReply() {
        guard let text = textField.text,
        let postID = postID,
        let user = Auth.auth().currentUser else {
            print("留言轉換失敗")
            return
        }
        Task {
            let success = await postReply(postID: postID, userID: "\(String(describing: user.uid))", replyContent: text)
            if success {
                textField.text = ""
            } else {
                print("請稍後再試")
            }
        }
    }
    func postReply(postID: String, userID: String, replyContent: String) async -> Bool {
        let replyData = [
            "userID": userID,
            "replayContent": replyContent,
            "replayTime": FieldValue.serverTimestamp()
        ] as [String: Any]

        do {
            let postRef = db.collection("Posts").document(postID)
            try await postRef.collection("replies").addDocument(data: replyData)
            print("Reply added to post \(postID)")
            return true
        } catch let error {
            print("Error adding reply to post \(postID): \(error)")
            return false
        }
    }
    private func listenToReplies() {
        guard let postID = postID else {
            print("Post ID is nil")
            return
        }

        let repliesRef = db.collection("Posts").document(postID).collection("replies")
        repliesRef.order(by: "replayTime").addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self, let snapshot = querySnapshot else {
                print("Error listening for replies: \(error?.localizedDescription ?? "No error")")
                return
            }

            self.replies = snapshot.documents.compactMap { docSnapshot -> ReplyContent? in
                var reply = ReplyContent(dic: docSnapshot.data())
                self.fetchUserName(userID: reply.userID)
                print("replies in reply.userID listenToReplies:\(self.replies)")
                return reply
            }

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private func fetchUserName(userID: String) {
        FirebaseManager.shared.fetchUserName(userID: userID) { [weak self] userName, error in
            DispatchQueue.main.async {
                if let userName = userName {
                    self?.usersNames[userID] = userName
                    self?.refreshTableViewForUserID(userID)
                } else if let error = error {
                    print("Error fetching user name: \(error)")
                }
            }
        }
    }
    private func refreshTableViewForUserID(_ userID: String) {
        let indexes = replies.enumerated().compactMap { index, reply -> IndexPath? in
            return reply.userID == userID ? IndexPath(row: index, section: 0) : nil
        }
        tableView.reloadRows(at: indexes, with: .none)
    }
}

extension ReplyViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        replies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(ReplyDetailTableViewCell.self)", for: indexPath) as? ReplyDetailTableViewCell else {
            fatalError("Fail to build ReplyDetailTableViewCell")
        }
        cell.contentView.backgroundColor = .black
        let reply = replies[indexPath.row]
//        cell.nameLabel.text = usersNames[reply.userID] ?? "Unknown"
//        cell.nameLabel.textColor = .white
        cell.nameLabel.attributedText = attributedTextForm(content: usersNames[reply.userID] ?? "Unknown", size: 16, kern: 0, color: .white)
//        cell.contentLabel.text = reply.replyContent
//        cell.contentLabel.textColor = .white
        cell.contentLabel.attributedText = attributedTextForm(content: reply.replyContent, size: 16, kern: 0, color: .white)
//        cell.timeLabel.text = /*formatDate(reply.replyTime)*/
//        cell.timeLabel.textColor = .white
        cell.timeLabel.attributedText = attributedTextForm(content: formatDate(reply.replyTime), size: 16, kern: 0, color: .white)
        cell.setupCell()
        return cell
    }
}

extension ReplyViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}

extension ReplyViewController {
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
