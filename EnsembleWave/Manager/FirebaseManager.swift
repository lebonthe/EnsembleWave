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
