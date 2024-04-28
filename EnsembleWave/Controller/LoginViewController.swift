//
//  LoginViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/26.
//

import UIKit
import FirebaseAuth
import AuthenticationServices
import CryptoKit

protocol LoginViewControllerDelegate: AnyObject {
    func didCompleteLogin()
}

class LoginViewController: UIViewController {
    weak var delegate: LoginViewControllerDelegate?
    
    fileprivate var currentNonce: String?
    var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setSignInWithAppleButtonAndLabel()
        
    }
    func setSignInWithAppleButtonAndLabel() {
        let signInWithAppleButton = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: chooseAppleButtonStyle())
        view.addSubview(signInWithAppleButton)
        signInWithAppleButton.cornerRadius = 25
        signInWithAppleButton.addTarget(self, action: #selector(signInWithApple), for: .touchUpInside)
        signInWithAppleButton.translatesAutoresizingMaskIntoConstraints = false
        
        label.text = "登入以使用 EnsembleWave 全部功能"
        label.textColor = .white
        view.addSubview(label)
        NSLayoutConstraint.activate([
            signInWithAppleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInWithAppleButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            signInWithAppleButton.heightAnchor.constraint(equalToConstant: 50),
            signInWithAppleButton.widthAnchor.constraint(equalToConstant: 280),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: signInWithAppleButton.topAnchor, constant: -100)
        ])
        print("登入按鈕設定完成")
    }

    func chooseAppleButtonStyle() -> ASAuthorizationAppleIDButton.Style {
        return .white
    }
    @objc func signInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while(remainingLength > 0) {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if (errorCode != errSecSuccess) {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if (remainingLength == 0) {
                    return
                }

                if (random < charset.count) {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        return hashString
    }
    // MARK: - 監聽目前的 Apple ID 的登入狀況
    // 主動監聽
    func checkAppleIDCredentialState(userID: String) {
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { credentialState, error in
            switch credentialState {
            case .authorized:
                CustomFunc.customAlert(title: "使用者已授權！", message: "", vc: self, actionHandler: nil)
            case .revoked:
                CustomFunc.customAlert(title: "使用者憑證已被註銷！", message: "請到\n「設定 → Apple ID → 密碼與安全性 → 使用 Apple ID 的 App」\n將此 App 停止使用 Apple ID\n並再次使用 Apple ID 登入本 App！", vc: self, actionHandler: nil)
            case .notFound:
                CustomFunc.customAlert(title: "", message: "使用者尚未使用過 Apple ID 登入！", vc: self, actionHandler: nil)
            case .transferred:
                CustomFunc.customAlert(title: "請與開發者團隊進行聯繫，以利進行使用者遷移！", message: "", vc: self, actionHandler: nil)
            default:
                break
            }
        }
    }
}

extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        // 登入成功
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                CustomFunc.customAlert(title: "", message: "Unable to fetch identity token", vc: self, actionHandler: nil)
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                CustomFunc.customAlert(title: "", message: "Unable to serialize token string from data\n\(appleIDToken.debugDescription)", vc: self, actionHandler: nil)
                return
            }
            // 產生 Apple ID 登入的 Credential
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: nonce, fullName: appleIDCredential.fullName)

                Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                    if let error = error {
                        // Error handling
                        print(error.localizedDescription)
                        return
                    }
                    // User is signed in to Firebase with Apple.
                    // Delegate callback
                    self?.dismiss(animated: true)
                    self?.delegate?.didCompleteLogin()
                    
                }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // 登入失敗，處理 Error
        switch error {
        case ASAuthorizationError.canceled:
            CustomFunc.customAlert(title: "使用者取消登入", message: "", vc: self, actionHandler: nil)
        case ASAuthorizationError.failed:
            CustomFunc.customAlert(title: "授權請求失敗", message: "", vc: self, actionHandler: nil)
        case ASAuthorizationError.invalidResponse:
            CustomFunc.customAlert(title: "授權請求無回應", message: "", vc: self, actionHandler: nil)
        case ASAuthorizationError.notHandled:
            CustomFunc.customAlert(title: "授權請求未處理", message: "", vc: self, actionHandler: nil)
        case ASAuthorizationError.unknown:
            CustomFunc.customAlert(title: "授權失敗，原因不知", message: "", vc: self, actionHandler: nil)
        default:
            break
        }
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
extension LoginViewController {
    // MARK: - 透過 Credential 與 Firebase Auth 串接
    func firebaseSignInWithApple(appleIDCredential: ASAuthorizationAppleIDCredential) {
        guard let nonce = currentNonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
        }
        guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetch identity token")
            return
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            return
        }

        let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: nonce, fullName: appleIDCredential.fullName)

        Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
            if let error = error {
                // Error handling
                print(error.localizedDescription)
                return
            }
            // User is signed in to Firebase with Apple.
            // Delegate callback or other actions
            self?.delegate?.didCompleteLogin()
        }
    }

    
    // MARK: - Firebase 取得登入使用者的資訊
    func getFirebaseUserInfo() {
        let currentUser = Auth.auth().currentUser
        guard let user = currentUser else {
            CustomFunc.customAlert(title: "無法取得使用者資料！", message: "", vc: self, actionHandler: nil)
            return
        }
        let uid = user.uid
        let email = user.email
        CustomFunc.customAlert(title: "使用者資訊", message: "UID：\(uid)\nEmail：\(email!)", vc: self) {
            self.dismiss(animated: true)
        }
        
    }
}
