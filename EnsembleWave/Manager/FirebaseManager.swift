//
//  FirebaseManager.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/3.
//

import Foundation
import Firebase
class FirebaseManager {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
//    var posts = [Post]() {
//        didSet {
//            onPostsUpdated?(posts)
//        }
//    }
//    var onPostsUpdated: (([Post]) -> Void)?
//    private var postLikesStatus = [String: Bool]()
//    private var postReplies = [String: Int]()
    
    private init() {}

    func fetchUserName(userID: String, completion: @escaping (String?, Error?) -> Void) {
        let docRef = db.collection("Users").document(userID)
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                let userName = document.data()?["name"] as? String ?? "Unknown User"
                completion(userName, nil)
            } else {
                completion(nil, error)
            }
        }
    }

    func fetchUserDetails(userID: String, completion: @escaping (User?) -> Void) {
        let userRef = db.collection("Users").document(userID)
        userRef.getDocument { document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    let userData = document.data() ?? [:]
                    let user = User(dic: userData)
                    completion(user)
                } else {
                    print("fetchUserDetails - Error fetching user details: \(error?.localizedDescription ?? "No error")")
                    completion(nil)
                }
            }
        }
    }
    
    func listenToUser(userId: String, completion: @escaping (User) -> Void) {
        db.collection("Users").document(userId)
            .addSnapshotListener { documentSnapshot, error in
                guard let snapshot = documentSnapshot else {
                    print("listenToUser - Error fetching user details: \(error?.localizedDescription ?? "No error")")
                    return
                }
                let user = User(dic: snapshot.data() ?? [:])
                completion(user)
            }
    }
    func listenToPosts(userID: String, posts: [Post], completion: @escaping ([Post]) -> Void) {
        var posts = posts
        db.collection("Posts")
            .whereField("userID", isEqualTo: userID).order(by: "createdTime", descending: false)
          .addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self, let snapshot = querySnapshot else {
              print("Error listening for post updates: \(error?.localizedDescription ?? "No error")")
              return
            }
              print("snapshot:\(snapshot)")
            snapshot.documentChanges.forEach { change in
                print("change:\(change)")
                let postId = change.document.documentID
//                var posts: [Post] = []
                switch change.type {
                case .added, .modified:
                    let data = change.document.data()
                    var post = Post(dic: data)
                    print("post:\(post)")
                    if change.type == .added {
                        posts.insert(post, at: 0)
                    } else if let index = posts.firstIndex(where: { $0.id == post.id }) {
                        posts[index] = post
                    }

                case .removed:
                    posts.removeAll { $0.id == postId }
                    
                }
                completion(posts)
            }
        }
    }
    func addReportToPost(postID: String, reportType: ReportType, completion: @escaping (Bool, Error?) -> Void) {
           let postRef = db.collection("Posts").document(postID)
           postRef.updateData([
               "report": FieldValue.arrayUnion([reportType.rawValue])
           ]) { error in
               if let error = error {
                   print("Error updating report: \(error.localizedDescription)")
                   completion(false, error)
               } else {
                   print("Report updated successfully.")
                   completion(true, nil)
               }
           }
       }
}

