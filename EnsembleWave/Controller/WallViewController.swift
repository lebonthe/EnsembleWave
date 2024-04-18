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
          .addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
              print("Error listening for post updates: \(error?.localizedDescription ?? "No error")")
                return
            }
              snapshot.documentChanges.forEach { change in
                  if change.type == .added {
                      let data = change.document.data()
                      let post = Post(dic: data)
                      print("New post: \(change.document.data())")
                      let whoLikeRef = self.db.collection("Posts").document(post.id).collection("whoLike")
                      whoLikeRef.getDocuments { (querySnapshot, error) in
                          guard let documents = querySnapshot?.documents else {
                              print("Error fetching whoLike documents: \(error?.localizedDescription ?? "No error")")
                              return
                          }
                          let userIDs = documents.compactMap { $0.documentID }
                          let isLiked = userIDs.contains("09876543") // TODO: 替換為當前用戶的 ID
                          self.postLikesStatus[post.id] = isLiked
                          print("Post ID: \(post.id), Liked: \(isLiked)")
                          self.posts.append(post)
                          self.fetchUserName(userID: post.userID)
                          DispatchQueue.main.async {
                              self.tableView.reloadData()
                          }
                      }
                  } else if change.type == .modified {
                      let data = change.document.data()
                      let post = Post(dic: data)
                      print("Updated post: \(change.document.data())")
                      if let index = self.posts.firstIndex(where: { $0.id == post.id }) {
                          self.posts[index] = post
                          DispatchQueue.main.async {
                              self.tableView.reloadData()
                          }
                      }
                  } else if change.type == .removed {
                      let data = change.document.data()
                      let post = Post(dic: data)
                      print("Removed post: \(change.document.data())")
                      self.posts.removeAll { $0.id == post.id }
                      DispatchQueue.main.async {
                          self.tableView.reloadData()
                      }
                  }
              }
          }
    }

    private func fetchUserName(userID: String) {
        let docRef = db.collection("Users").document(userID)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let userName = document.data()?["name"] as? String ?? "Unknown User"
                self.usersNames[userID] = userName
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } else {
                print("Document does not exist")
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
            cell.isUserLiked = self.postLikesStatus[post.id] ?? false
            cell.postID = post.id
            cell.setupUI()
            return cell
        case 2:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(LikesCountCell.self)", for: indexPath) as? LikesCountCell else {
                fatalError("error when building OptionsCell")
            }
            
            cell.likesCount = post.whoLike.count
            print("likesCount:\(post.whoLike.count)")
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
