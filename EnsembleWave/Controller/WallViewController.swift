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
        tableView.register(ReplaysCell.self, forCellReuseIdentifier: "\(ReplaysCell.self)")
    }
    private func listenToPosts() {
        db.collection("Posts")
          .addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
              print("Error listening for post updates: \(error?.localizedDescription ?? "No error")")
                return
            }
              snapshot.documentChanges.forEach { change in
                  var data = change.document.data()
                  let post = Post(dic: data)
                  if change.type == .added {
                      print("New post: \(change.document.data())")
//                      do {
                          self.posts.append(post)
                          DispatchQueue.main.async {
                              self.tableView.reloadData()
                          }
//                          var data = try JSONSerialization.data(withJSONObject: change.document.data(), options: .prettyPrinted)
                          
//                          if let timestamp = data["createdTime"] as? Timestamp {
//                                          data["createdTime"] = timestamp.dateValue().iso8601String
//                                      }
//                          do {
//                              let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
////                              let postAdded = try decoder.decode(Post.self, from: data)
//                              let post = try JSONDecoder().decode(Post.self, from: jsonData)
//                              self.posts.append(post)
//                              DispatchQueue.main.async {
//                                                  self.tableView.reloadData()
//                                              }
//                              print("self.posts:\(self.posts)")
//                          } catch {
//                              print("data 轉換失敗:\(error.localizedDescription)")
//                          }
//                      } catch {
//                          print("decode 失敗:\(error.localizedDescription)")
//                      }
                  } else if change.type == .modified {
                      print("Updated post: \(change.document.data())")
                      if let index = self.posts.firstIndex(where: { $0.id == post.id }) {
                          self.posts[index] = post
                          DispatchQueue.main.async {
                              self.tableView.reloadData()
                          }
                      }
                  } else if change.type == .removed {
                      print("Removed post: \(change.document.data())")
                      self.posts.removeAll { $0.id == post.id }
                      DispatchQueue.main.async {
                          self.tableView.reloadData()
                      }
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
        let row = indexPath.row
        switch row {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(VideoCell.self)", for: indexPath) as? VideoCell else {
                fatalError("error when building VideoCell")
            }
            cell.urlString = posts[row].videoURL
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(OptionsCell.self)", for: indexPath) as? OptionsCell else {
                fatalError("error when building OptionsCell")
            }

            return cell
        case 2:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(LikesCountCell.self)", for: indexPath) as? LikesCountCell else {
                fatalError("error when building OptionsCell")
            }

            return cell
        case 3:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(ContentCell.self)", for: indexPath) as? ContentCell else {
                fatalError("error when building OptionsCell")
            }

            return cell
        case 4:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(TagsCell.self)", for: indexPath) as? TagsCell else {
                fatalError("error when building OptionsCell")
            }

            return cell
        case 5:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(ReplaysCell.self)", for: indexPath) as? ReplaysCell else {
                fatalError("error when building OptionsCell")
            }

            return cell
        default:
            fatalError("Out of cell types")
        }
    }
}

extension WallViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        118 // TODO: 調整不同的行高
    }
}
