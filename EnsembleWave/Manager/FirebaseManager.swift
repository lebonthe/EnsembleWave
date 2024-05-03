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
    var posts = [Post]() {
        didSet {
            onPostsUpdated?(posts)
        }
    }
    var onPostsUpdated: (([Post]) -> Void)?
    private var postLikesStatus = [String: Bool]()
    private var postReplies = [String: Int]()
    
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
                    print("Error fetching user details: \(error?.localizedDescription ?? "No error")")
                    completion(nil)
                }
            }
        }
    }
    func listenToPosts() {
        db.collection("Posts").order(by: "createdTime")
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
                        
                        // Fetch the user name asynchronously using fetchUserName method
                        self.fetchUserName(userID: post.userID) { userName, error in
                            if let userName = userName {
                                print("Fetched user name: \(userName)")
                            } else if let error = error {
                                print("Error fetching user name: \(error.localizedDescription)")
                            }
                        }
                        
                        if let ensembleUserID = post.ensembleUserID {
                            // Optionally fetch another user related to the post
                            self.fetchUserName(userID: ensembleUserID) { userName, error in
                                if let userName = userName {
                                    print("Fetched ensemble user name: \(userName)")
                                } else if let error = error {
                                    print("Error fetching ensemble user name: \(error.localizedDescription)")
                                }
                            }
                        }
                        
                    case .removed:
                        self.posts.removeAll { $0.id == postId }
                        self.postLikesStatus.removeValue(forKey: postId)
                        self.postReplies.removeValue(forKey: postId)
                    }
                }
            }
    }
    
    func listenToUser(userId: String, completion: @escaping (User) -> Void) {
        db.collection("Users").document(userId)
            .addSnapshotListener { documentSnapshot, error in
                guard let snapshot = documentSnapshot else {
                    print("Error fetching user details: \(error?.localizedDescription ?? "No error")")
                    return
                }
                let user = User(dic: snapshot.data() ?? [:])
                completion(user)
            }
    }
}
