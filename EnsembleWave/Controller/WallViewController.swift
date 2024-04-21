//
//  WallViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/17.
//

import UIKit
import FirebaseCore
import FirebaseFirestore

class WallViewController: UIViewController {
    
    let db = Firestore.firestore()
    var posts = [Post]()
    var userInfo: User?
    var usersNames: [String: String] = [:]
    var postLikesCount: [String: Int] = [:]
    var postLikesStatus: [String: Bool] = [:]
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listenToPosts()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(VideoCell.self, forCellReuseIdentifier: "\(VideoCell.self)")
        tableView.register(OptionsCell.self, forCellReuseIdentifier: "\(OptionsCell.self)")
        tableView.register(LikesCountCell.self, forCellReuseIdentifier: "\(LikesCountCell.self)")
        tableView.register(ContentCell.self, forCellReuseIdentifier: "\(ContentCell.self)")
        tableView.register(TagsCell.self, forCellReuseIdentifier: "\(TagsCell.self)")
        tableView.register(ReplysCell.self, forCellReuseIdentifier: "\(ReplysCell.self)")
    }

    private func listenToPosts() {
        db.collection("Posts")
          .addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self, let snapshot = querySnapshot else {
              print("Error listening for post updates: \(error?.localizedDescription ?? "No error")")
              return
            }

            snapshot.documentChanges.forEach { change in
                let postId = change.document.documentID
    
                switch change.type {
                case .added, .modified:
                    let data = change.document.data()
                    let post = Post(dic: data)
                    self.fetchUserName(userID: post.userID)
                    if change.type == .added {
                        self.posts.append(post)
                    } else if let index = self.posts.firstIndex(where: { $0.id == post.id }) {
                        self.posts[index] = post
                    }

                    // Set up or update the listener for the whoLike collection of this post
                    self.setupLikesListener(for: postId)

                case .removed:
                    self.posts.removeAll { $0.id == postId }
                    self.postLikesCount.removeValue(forKey: postId)
                    self.postLikesStatus.removeValue(forKey: postId)
                }
            }
            self.tableView.reloadData()
        }
    }

    private func fetchUserName(userID: String) {
        UserManager.shared.fetchUserName(userID: userID) { [weak self] userName, error in
                DispatchQueue.main.async {
                    if let userName = userName {
                        self?.usersNames[userID] = userName
                        self?.tableView.reloadData()
                    } else if let error = error {
                        print("Error fetching user name: \(error)")
                    }
                }
            }
    }
}
extension WallViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        print("posts.count:\(posts.count)")
        return posts.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        6
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.section]
        switch indexPath.row {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(VideoCell.self)", for: indexPath) as? VideoCell else {
                fatalError("error when building VideoCell")
            }
            print("====post.videoURL: \(post.videoURL)")
            cell.urlString = post.videoURL
            cell.setupUI()
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(OptionsCell.self)", for: indexPath) as? OptionsCell else {
                fatalError("error when building OptionsCell")
            }
            cell.delegate = self
            cell.isUserLiked = self.postLikesStatus[post.id] ?? false
            cell.postID = post.id
            cell.cellIndex = indexPath
            cell.setupUI()
            return cell
        case 2:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(LikesCountCell.self)", for: indexPath) as? LikesCountCell else {
                fatalError("error when building OptionsCell")
            }
            let postId = post.id
            cell.likesCount = postLikesCount[postId] ?? 0
            print("likesCount in cell 2: \(cell.likesCount)")
            cell.setupUI()
            return cell
        case 3:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(ContentCell.self)", for: indexPath) as? ContentCell else {
                fatalError("error when building OptionsCell")
            }
            cell.contentText = post.content
            cell.setupUI()
            return cell
        case 4:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(TagsCell.self)", for: indexPath) as? TagsCell else {
                fatalError("error when building OptionsCell")
            }
            cell.tagsText = post.tag
            cell.setupUI()
            return cell
        case 5:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(ReplysCell.self)", for: indexPath) as? ReplysCell else {
                fatalError("error when building OptionsCell")
            }
            cell.replyContent = post.reply
            cell.setupUI()
            return cell
        default:
            fatalError("Out of cell types")
        }
    }
}

extension WallViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let userID = posts[section].userID
        let title = posts[section].title
        print("usersNames:\(usersNames)")
        return (usersNames[userID] ?? "") + " 🎙️ \(title)"
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = indexPath.row
        if row == 0 {
            return view.window?.windowScene?.screen.bounds.width ?? 200
        } else {
            return UITableView.automaticDimension
        }
    }
}

extension WallViewController: OptionsCellDelegate {
    func showReplyPage(from cell: OptionsCell, cellIndex: Int, postID: String) {
        let controller = ReplyViewController()
//        controller.replies = posts[cellIndex].reply
        controller.postID = postID
        self.navigationController?.pushViewController(controller, animated: true)
    }
    func updateLikeStatus(postId: String, hasLiked: Bool) {
        let adjustment = hasLiked ? 1 : -1
        let currentCount = postLikesCount[postId] ?? 0
        postLikesCount[postId] = max(0, currentCount + adjustment)
        postLikesStatus[postId] = hasLiked

        if let index = posts.firstIndex(where: { $0.id == postId }) {
            DispatchQueue.main.async {
                let indexPath = IndexPath(row: 2, section: index) 
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
    private func setupLikesListener(for postId: String) {
        db.collection("Posts").document(postId).collection("whoLike")
          .addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error listening for likes updates: \(error)")
                return
            }

            let likesCount = querySnapshot?.documents.count ?? 0
            DispatchQueue.main.async {
                self.postLikesCount[postId] = likesCount
                if let index = self.posts.firstIndex(where: { $0.id == postId }) {
                    let indexPath = IndexPath(row: 2, section: index)
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        }
    }
}
