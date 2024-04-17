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
       
        listenToPosts()
        
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
                print("New post: \(change.document.data())")
              } else if change.type == .modified {
                print("Updated post: \(change.document.data())")
              } else if change.type == .removed {
                print("Removed post: \(change.document.data())")
              }
            }
          }
    }


}
