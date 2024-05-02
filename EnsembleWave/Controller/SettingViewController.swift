//
//  SettingViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/30.
//
import UIKit
import FirebaseAuth
import CryptoKit
import AuthenticationServices
class SettingViewController: UIViewController {

    let tableView = UITableView()
    fileprivate var currentNonce: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        tableView.reloadData()
    }
    func updateUI() {
        tableView.backgroundColor = .black
        self.title = "Settings"
        view.backgroundColor = .lightGray
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    func deleteCurrentUser() {
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
    
    func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            CustomFunc.customAlert(title: "已成功登出", message: "", vc: self) {
                print("sign out")
                self.navigationController?.popViewController(animated: true)
            }
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}
extension SettingViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.textProperties.color = .white
            content.text = "編輯使用者資料"
            cell.contentConfiguration = content
            cell.backgroundColor = .clear
            return cell
        case IndexPath(row: 1, section: 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.textProperties.color = .white
            content.text = "刪除帳號"
            cell.contentConfiguration = content
            cell.backgroundColor = .clear
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.textProperties.color = .white
            content.text = "登出"
            cell.contentConfiguration = content
            cell.backgroundColor = .clear
            return cell
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            let controller = ProfileEditingTableViewController()
            controller.tableView.backgroundColor = .black
            controller.tableView.tintColor = .white
            navigationController?.pushViewController(controller, animated: true)
        case IndexPath(row: 1, section: 0):
            let alert = UIAlertController(title: "確定要刪除帳號？", message: "刪除帳號包含帳號擁有的所有影片與發文", preferredStyle: .alert)
            let deleteAction = UIAlertAction(title: "確定刪除", style: .destructive) { _ in
                self.deleteCurrentUser()
            }
            let cancelAction = UIAlertAction(title: "算了", style: .cancel)
            alert.addAction(deleteAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true)
        default:
            signOut()
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
}
extension SettingViewController: ASAuthorizationControllerPresentationContextProviding {
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

extension SettingViewController: ASAuthorizationControllerDelegate {

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
                self.navigationController?.popViewController(animated: true)
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
