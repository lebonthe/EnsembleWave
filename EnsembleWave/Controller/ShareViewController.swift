//
//  ShareViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/11.
//

import UIKit
import Photos
import FirebaseStorage

class ShareViewController: UIViewController {
    var url: URL?
    private let saveToAlbumButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("存到相簿", for: .normal)
        button.setTitleColor(.black, for: .normal)
        return button
    }()
    private let shareToWallButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("分享到動態牆", for: .normal)
        button.setTitleColor(.black, for: .normal)
        return button
    }()
    var duration: Int?
    var ensembleUserID: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        print("duration sent to ShareViewController:\(duration)")
        view.backgroundColor = .white
        setupUI()
    }
    func setupUI() {
        view.addSubview(saveToAlbumButton)
        view.addSubview(shareToWallButton)
        NSLayoutConstraint.activate([
            saveToAlbumButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 200),
            saveToAlbumButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveToAlbumButton.heightAnchor.constraint(equalToConstant: 50),
            saveToAlbumButton.widthAnchor.constraint(equalToConstant: 100),
            shareToWallButton.topAnchor.constraint(equalTo: saveToAlbumButton.bottomAnchor, constant: 200),
            shareToWallButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shareToWallButton.heightAnchor.constraint(equalToConstant: 50),
            shareToWallButton.widthAnchor.constraint(equalToConstant: 200)
        ])
        saveToAlbumButton.addTarget(self, action: #selector(saveVideoToAlbum), for: .touchUpInside)
        shareToWallButton.addTarget(self, action: #selector(shareToWall), for: .touchUpInside)
    }
    @objc func saveVideoToAlbum() {
        guard let url = url else {
            print("no url")
            return
        }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { saved, error in
            DispatchQueue.main.async {
                
                if saved {
                    let alertController = UIAlertController(title: "影片已儲存", message: "可到相簿查看", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default)
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true)
                    print("影片已儲存到相簿")
                } else {
                    let alertController = UIAlertController(title: "影片儲存失敗", message: "花生了什麼事？", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default)
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true)
                    print("影片儲存失敗: \(String(describing: error))")
                }
            }
        }
    }
    @objc func shareToWall() {
        // TODO: 找出這些 comment 為何會害上傳失敗
        saveVideoToFirebase() { url in
            if let url = url,
               let duration = self.duration {
                print("Got the download URL: \(url)")
                let controller = PostToWallViewController(nibName: "PostToWallViewController", bundle: nil)
                controller.url = url
                controller.duration = duration
                if let ensembleUserID = self.ensembleUserID {
                    controller.ensembleUserID =  ensembleUserID
                    self.present(controller, animated: true)
                } else {
                    self.present(controller, animated: true)
                }
    
            } else {
                print("Failed to get the download URL")
            }
        }
    }
    func saveVideoToFirebase(completion: @escaping (URL?) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let videoRef = storageRef.child("videos/\(UUID().uuidString).mov")
        guard let url = url else {
            print("沒有 url")
            completion(nil)
            return
        }
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        let uploadTask = videoRef.putFile(from: url, metadata: nil) { metadata, error in
            guard error == nil else {
                print("putFile error:\(error?.localizedDescription ?? "error")")
                dispatchGroup.leave()
                completion(nil)
                return
            }
            guard let metadata = metadata else {
                print("metadata 錯誤")
                dispatchGroup.leave()
                completion(nil)
                return
            }
            print("Uploaded Size: \(metadata.size) bytes")
            videoRef.downloadURL { url, error in
                defer { dispatchGroup.leave() }
                guard error == nil else {
                    print("downloadURL error:\(error?.localizedDescription ?? "error")")
                    completion(nil)
                    return
                }
                guard let url = url else {
                    print("downloadURL 失敗")
                    completion(nil)
                    return
                }
                print("downloadURL:\(url)")
                completion(url)
            }
        }
    }
    private func fetchUserName(ensembleUserID: String, url: URL, duration: Int) {
        UserManager.shared.fetchUserName(userID: ensembleUserID) { [weak self] userName, error in
            let controller = PostToWallViewController()
                DispatchQueue.main.async {
                    if let userName = userName {
                        DispatchQueue.main.async {
                            controller.url = url
                            controller.duration = duration
                            controller.ensembleUserID = ensembleUserID
                            controller.ensembleUserName = userName
                            self?.present(controller, animated: true)
                        }
                    } else if let error = error {
                        print("Error fetching user name: \(error)")
                    }
                }
        }
    }
}
