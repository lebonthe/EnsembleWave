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
    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            await getAllPosts()
        }
    }
    private func getAllPosts() async {
        do {
            let querySnapshot = try await db.collection("Posts").getDocuments()
            for document in querySnapshot.documents {
                print("\(document.documentID) => \(document.data())")
            }
        } catch {
            print("Error getting documents: \(error)")
        }
    }

}
