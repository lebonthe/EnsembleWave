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
    
    let deleteAccountButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
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

    // TODO: 繼續刪除流程，並把user資料串接，在 Profile 頁面顯示創作與名字
   
    
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
            for subview in view.subviews {
                subview.removeFromSuperview()
            }
            setupSettingButton()
            let profileView = ProfileView()
            profileView.frame = view.bounds
            view.addSubview(profileView)
            profileView.userNameLabel.text = "Min"  // TODO: 回來改使用者名稱 user name
            profileView.likesCountLabel.text = "8" // TODO: 回來改
            profileView.ensembleCountLabel.text = "5" // TODO: 回來改
            profileView.userImageView.image = UIImage(named: "snoopy")
            
            print("=========Already Login")
        }
    }
    @objc func presentLoginViewController() {
        let loginViewController = LoginViewController()
        loginViewController.delegate = self
//        loginViewController.modalPresentationStyle = .fullScreen
        present(loginViewController, animated: true)
    }
    
}
extension ProfileViewController: LoginViewControllerDelegate {
    func didCompleteLogin() {
        checkLoginStatus()
    }
}


