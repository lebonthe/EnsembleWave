//
//  ProfileViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/27.
//

import UIKit
import FirebaseAuth
import CryptoKit
import AuthenticationServices

class ProfileViewController: UIViewController {
    var user = Auth.auth().currentUser
    var userInfo: User?
    let deleteAccountButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    @IBOutlet weak var profileView: ProfileView!
    fileprivate var currentNonce: String?
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")

        checkLoginStatus()
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("viewWillLayoutSubviews")
    }

    func setupLoginButton() {
        let loginButton = UIButton()
         loginButton.translatesAutoresizingMaskIntoConstraints = false
         loginButton.addTarget(self, action: #selector(presentLoginViewController), for: .touchUpInside)
         view.addSubview(loginButton)
        loginButton.setTitle("登入", for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
     NSLayoutConstraint.activate([
         loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
         loginButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
     ])
    }
    func setupSettingButton() {
        let settingButton = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(pushSettingViewController))
        navigationItem.rightBarButtonItem = settingButton
    }
    @objc func pushSettingViewController() {
        let settingViewController = SettingViewController()
        navigationController?.pushViewController(settingViewController, animated: true)
    }
    func checkLoginStatus() {
        if Auth.auth().currentUser == nil {
            for subview in view.subviews {
                subview.removeFromSuperview()
            }
            setupLoginButton()
            navigationItem.rightBarButtonItem = nil
        } else {
            user = Auth.auth().currentUser
            for subview in view.subviews {
                subview.removeFromSuperview()
            }
            setupSettingButton()
            if view.subviews.contains(where: { $0 is ProfileView }) == false {
                if let profileView = Bundle.main.loadNibNamed("ProfileView", owner: self, options: nil)?.first as? ProfileView {
                    profileView.frame = self.view.bounds
                    print("Adding profileView to the view hierarchy")
                    profileView.userID = user?.uid
                    self.view.addSubview(profileView)
                    if let userID = user?.uid {
                        profileView.configureWithUserID(userID: userID)
                    }
                    print("ProfileView added successfully")
                    
                } else {
                    print("無法加載 ProfileView")
                }
            }
            getUserInfo()
//                       let profileView = ProfileView()
//                       profileView.frame = view.bounds
//                       view.addSubview(profileView)
//                       profileView.userNameLabel.text = "Min"  // TODO: 回來改使用者名稱 user name
//                       profileView.likesCountLabel.text = "8" // TODO: 回來改
//                       profileView.ensembleCountLabel.text = "5" // TODO: 回來改
//                       profileView.userImageView.image = UIImage(named: "snoopy")
        }
    }
    @objc func presentLoginViewController() {
        let loginViewController = LoginViewController()
        loginViewController.delegate = self
//        loginViewController.modalPresentationStyle = .fullScreen
        present(loginViewController, animated: true)
    }
    func updateProfileView(with userInfo: User) {
        for subview in view.subviews {
            if let profileView = subview as? ProfileView {
                profileView.configure(with: userInfo)
                break
            }
        }
    }
//    func listenUserInfo() {
//        guard let user = user else {
//            print("無法取得 user")
//            return
//        }
//        FirebaseManager.shared.fetchUserDetails(userID: user.uid) { userData in
//            self.userInfo = userData
//        }
//    }
    func getUserInfo() {
        guard let user = user else {
            print("無法取得 user")
            return
        }
        print("Try to get user info of:\(user)")
        print("userUID:\(user.uid)")
        FirebaseManager.shared.fetchUserDetails(userID: user.uid) { userData in
            DispatchQueue.main.async {
                if let userData = userData {
                    self.userInfo = userData
                    print("取得 userData:\(userData)")
                    self.updateProfileView(with: userData)
                }
            }
        }
    }
}
extension ProfileViewController: LoginViewControllerDelegate {
    func didCompleteLogin() {
        checkLoginStatus()
    }
}
