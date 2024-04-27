//
//  ProfileViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/27.
//

import UIKit
import FirebaseAuth
class ProfileViewController: UIViewController {

    @IBOutlet weak var signOutButton: UIBarButtonItem!
    
    @IBOutlet weak var signInButton: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkLoginStatus()
        print("viewWillAppear")
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("viewWillLayoutSubviews")
    }
    @IBAction func signOut(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
            print("sign out")
            if #available(iOS 16.0, *) {
                signOutButton.isHidden = true
                signInButton.isHidden = false
            } else {
                self.navigationItem.rightBarButtonItem = signInButton
            }
            
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
    }
    func checkLoginStatus() {
        if Auth.auth().currentUser == nil {
            if #available(iOS 16.0, *) {
                signOutButton.isHidden = true
                signInButton.isHidden = false
            } else {
                self.navigationItem.rightBarButtonItem = signInButton
            }
            presentLoginViewController()
        } else {
            // 已登入，顯示主界面
            if #available(iOS 16.0, *) {
                signOutButton.isHidden = false
                signInButton.isHidden = true
            } else {
                self.navigationItem.rightBarButtonItem = signOutButton
            }
//            showMainAppInterface()
            print("=========Already Login")
        }
    }
    @IBAction func presentLoginViewController() {
        let loginViewController = LoginViewController()
        loginViewController.delegate = self
        loginViewController.modalPresentationStyle = .fullScreen
        present(loginViewController, animated: true)
    }

}
extension ProfileViewController: LoginViewControllerDelegate {
    func didCompleteLogin() {
        checkLoginStatus()
    }
}
