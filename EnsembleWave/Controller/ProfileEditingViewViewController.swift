//
//  ProfileEditingViewViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/3.
//

import UIKit
import Firebase
import FirebaseStorage
import Kingfisher
class ProfileEditingViewViewController: UIViewController {
    let db = Firestore.firestore()
    let user = Auth.auth().currentUser
    var userInfo: User?
    var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    let nameTextField = UITextField()
    var dataToSave = [String: Any] ()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Editing Your Account"
        getUserInfo()
    }
    func updateUI() {
        let saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveButtonTapped))
        let font = UIFont(name: "NotoSansTC-Regular", size: 18)!
        saveButton.setTitleTextAttributes([.font: font], for: .normal)
        self.navigationItem.rightBarButtonItem = saveButton
        view.addSubview(imageView)
        if let imageURLString =  userInfo?.photoURL,
           let imageURL = URL(string: imageURLString) {
            imageView.kf.setImage(
                with: imageURL
            )
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
        } else {
            imageView.image = UIImage(systemName: "photo")
        }
        let choosePhotoButton = UIButton()
        choosePhotoButton.translatesAutoresizingMaskIntoConstraints = false
//        choosePhotoButton.setTitle("從相簿選擇", for: .normal)
        choosePhotoButton.setAttributedTitle(attributedTextForm(content: "Select from album", size: 18, kern: 0, color: UIColor.white), for: .normal)
        choosePhotoButton.addTarget(self, action: #selector(selectPhoto), for: .touchUpInside)
        choosePhotoButton.setTitleColor(.white, for: .normal)
        view.addSubview(choosePhotoButton)
        let takePhotoButton = UIButton()
        takePhotoButton.translatesAutoresizingMaskIntoConstraints = false
//        takePhotoButton.setTitle("拍照", for: .normal)
        takePhotoButton.setAttributedTitle(attributedTextForm(content: "Take a photo", size: 18, kern: 0, color: UIColor.white), for: .normal)
        takePhotoButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        takePhotoButton.setTitleColor(.white, for: .normal)
        view.addSubview(takePhotoButton)
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = "Your Name"
        nameLabel.attributedText = attributedTextForm(content: "Your Name", size: 18, kern: 0, color: .white)
        nameLabel.textAlignment = .center
        nameLabel.textColor = .white
        view.addSubview(nameLabel)
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.backgroundColor = .white
        nameLabel.layer.cornerRadius = 10
        if let userInfo = userInfo {
            nameTextField.text = userInfo.name
        } else {
            nameTextField.placeholder = "Please type your name."
        }
        nameTextField.addTarget(self, action: #selector(changeNameToData), for: .editingChanged)
        view.addSubview(nameTextField)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 150),
            imageView.heightAnchor.constraint(equalToConstant: 150),
            choosePhotoButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            choosePhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            choosePhotoButton.widthAnchor.constraint(equalToConstant: 120),
            choosePhotoButton.heightAnchor.constraint(equalToConstant: 30),
            takePhotoButton.topAnchor.constraint(equalTo: choosePhotoButton.bottomAnchor, constant: 8),
            takePhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            takePhotoButton.widthAnchor.constraint(equalToConstant: 120),
            takePhotoButton.heightAnchor.constraint(equalToConstant: 30),
            nameLabel.topAnchor.constraint(equalTo: takePhotoButton.bottomAnchor, constant: 8),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameLabel.widthAnchor.constraint(equalToConstant: 200),
            nameLabel.heightAnchor.constraint(equalToConstant: 30),
            nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            nameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameTextField.widthAnchor.constraint(equalToConstant: 320),
            nameTextField.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    @objc func selectPhoto() {
            let controller = UIImagePickerController()
            controller.sourceType = .photoLibrary
            controller.delegate = self
            present(controller, animated: true)
        }
    @objc func takePhoto() {
            let controller = UIImagePickerController()
            controller.sourceType = .camera
            controller.delegate = self
            present(controller, animated: true)
        }
    @objc func changeNameToData() {
        dataToSave["name"] = nameTextField.text
    }
    func getUserInfo() {
        guard let user = user else {
            print("無法取得 user")
            return
        }
        FirebaseManager.shared.fetchUserDetails(userID: user.uid) { userData in
            DispatchQueue.main.async {
                self.userInfo = userData
                print("取得 userData:\(userData!)")
                self.updateUI()
            }
        }
    }

    @objc func saveButtonTapped() {
        Task {
            let success = await postToUser()
            if success {
                let alertViewController = UIAlertController(title: "Saved", message: "User info has been updated.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.navigationController?.popViewController(animated: true)
                }
                alertViewController.addAction(okAction)
                present(alertViewController, animated: true)
            } else {
                let alertViewController = UIAlertController(title: "Oops!", message: "Please confirm your network connection.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default)
                alertViewController.addAction(okAction)
                present(alertViewController, animated: true)
            }
        }
        
    }
    func postToUser() async -> Bool {
        guard let user = Auth.auth().currentUser else {
            print("尚未登入")
            return false
        }
        do {
            
            let ref = db.collection("Users").document("\(user.uid)")
            print("Document added with UID: \(ref.documentID)")
            try await ref.setData(dataToSave, merge: true)
            return true
        } catch {
            print("Error adding document: \(error)")
            return false
        }
    }
}
extension ProfileEditingViewViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let image = info[.originalImage] as? UIImage
        imageView.image = image
        if let image = image {
            saveImageToFirebase(image: image) { url in
                self.dataToSave["photoURL"] = "\(url!)"
            }
        }
        dismiss(animated: true)
    }

    func saveImageToFirebase(image: UIImage, completion: @escaping (URL?) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageData = image.jpegData(compressionQuality: 0.75)
        let imageRef = storageRef.child("images/\(UUID().uuidString).png")
        if let imageData = imageData {
            imageRef.putData(imageData) { _ in
                imageRef.downloadURL { url, error in
                    guard let url = url, error == nil else {
                        print("downloadURL error: \(error!.localizedDescription)")
                        completion(nil)
                        return
                    }
                    print("saveImageToFirebase - downloadURL: \(url)")
                    completion(url)
                }
            }
            
        }
    }
}
