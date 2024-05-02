//
//  UserManager.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/21.
//

import Firebase

class UserManager {
    static let shared = UserManager()
    private let db = Firestore.firestore()

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
}
