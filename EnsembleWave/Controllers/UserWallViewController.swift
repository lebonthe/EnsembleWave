//
//  UserWallViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/5.
//

import UIKit
import FirebaseAuth

class UserWallViewController: UIViewController {
    var userID: String?
    var userInfo: User?
    @IBOutlet weak var profileView: ProfileView!
    override func viewDidLoad() {
        super.viewDidLoad()
        getUserInfo()
        if view.subviews.contains(where: { $0 is ProfileView }) == false {
            if let profileView = Bundle.main.loadNibNamed("ProfileView", owner: self, options: nil)?.first as? ProfileView {
                profileView.frame = self.view.bounds
                profileView.userID = userID
                print("Adding profileView to the view hierarchy")
                self.view.addSubview(profileView)
                if let userID = userID {
                    profileView.configureWithUserID(userID: userID)
                }
                print("ProfileView added successfully")
                
            } else {
                print("無法加載 ProfileView")
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")

    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("viewWillLayoutSubviews")
    }

    func updateProfileView(with userInfo: User) {
        for subview in view.subviews {
            if let profileView = subview as? ProfileView {
                profileView.configure(with: userInfo)
                break
            }
        }
    }

    func getUserInfo() {
        guard let userID = userID else {
            print("無法取得 user")
            return
        }
        FirebaseManager.shared.fetchUserDetails(userID: userID) { userData in
            DispatchQueue.main.async {
                if let userData = userData {
                    self.userInfo = userData
                    print("取得 userData:\(userData)")
                    self.updateProfileView(with: userData)
                    self.title = userData.name
                }
            }
        }
    }
}
