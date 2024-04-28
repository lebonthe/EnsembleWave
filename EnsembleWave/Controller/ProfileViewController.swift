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

    @IBOutlet weak var signOutButton: UIBarButtonItem!
    
    @IBOutlet weak var signInButton: UIBarButtonItem!
    
    let deleteAccountButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    fileprivate var currentNonce: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        setupUI()
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
    func updateUI() {
        if Auth.auth().currentUser != nil {
            deleteAccountButton.setTitle("刪除帳號", for: .normal)
            //         deleteAccountButton.backgroundColor = .yellow
            view.addSubview(deleteAccountButton)
            deleteAccountButton.addTarget(self, action: #selector(deleteCurrentUser), for: .touchUpInside)
            NSLayoutConstraint.activate([
                deleteAccountButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                deleteAccountButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
                deleteAccountButton.widthAnchor.constraint(equalToConstant: 80),
                deleteAccountButton.heightAnchor.constraint(equalToConstant: 30)
            ])
        } else {
            
        }
    }
    // TODO: 繼續刪除流程，並把user資料串接，在 Profile 頁面顯示創作與名字
   
    @objc func deleteCurrentUser() {
        do {
            let nonce = try CryptoUtils.randomNonceString()
            currentNonce = nonce
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = CryptoUtils.sha256(nonce)
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        } catch {
            // In the unlikely case that nonce generation fails, show error view.
            displayError(error)
        }
    }
    
    @IBAction func signOut(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            CustomFunc.customAlert(title: "已成功登出", message: "", vc: self) {
                print("sign out")
                if #available(iOS 16.0, *) {
                    self.signOutButton.isHidden = true
                    self.signInButton.isHidden = false
                } else {
                    self.navigationItem.rightBarButtonItem = self.signInButton
                }
                self.checkLoginStatus()
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
            for subview in view.subviews {
                subview.removeFromSuperview()
            }
          
//            presentLoginViewController()
        } else {
            if #available(iOS 16.0, *) {
                signOutButton.isHidden = false
                signInButton.isHidden = true
            } else {
                self.navigationItem.rightBarButtonItem = signOutButton
            }
            updateUI()
            print("=========Already Login")
        }
    }
    @IBAction func presentLoginViewController() {
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

extension ProfileViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    func displayError(_ error: Error) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }

}

extension ProfileViewController: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
      guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential
      else {
        print("Unable to retrieve AppleIDCredential")
        return
      }

      guard let _ = currentNonce else {
        fatalError("Invalid state: A login callback was received, but no login request was sent.")
      }

      guard let appleAuthCode = appleIDCredential.authorizationCode else {
        print("Unable to fetch authorization code")
        return
      }

      guard let authCodeString = String(data: appleAuthCode, encoding: .utf8) else {
        print("Unable to serialize auth code string from data: \(appleAuthCode.debugDescription)")
        return
      }

      Task {
        do {
          try await Auth.auth().revokeToken(withAuthorizationCode: authCodeString)
            let user = Auth.auth().currentUser
          try await user?.delete()
            CustomFunc.customAlert(title: "使用者帳號已刪除", message: "", vc: self) {
                self.checkLoginStatus()
            }
          
        } catch {
          self.displayError(error)
        }
      }
    }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    // Handle error.
    print("Sign in with Apple errored: \(error)")
  }

}
