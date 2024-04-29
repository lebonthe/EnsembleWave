//
//  ShareViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/11.
//

import UIKit
import Photos
import FirebaseStorage
import FirebaseAuth
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
        guard Auth.auth().currentUser != nil else {
            presentLoginViewController()
            return
            }
        saveVideoToFirebase() { url in
            self.saveImageToFirebase { imageURL in
                if let url = url,
                   let imageURL = imageURL,
                   let duration = self.duration {
                    print("Got the download URL: \(url)")
                    let controller = PostToWallViewController(nibName: "PostToWallViewController", bundle: nil)
                    controller.url = url
                    controller.imageURL = imageURL
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
    }
    func saveVideoToFirebase(completion: @escaping (URL?) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let videoRef = storageRef.child("videos/\(UUID().uuidString).mov")
        guard let url = url else {
            print("saveVideoToFirebase - 沒有 url")
            completion(nil)
            return
        }
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        let uploadTask = videoRef.putFile(from: url, metadata: nil) { metadata, error in
            guard error == nil else {
                print("saveVideoToFirebase - putFile error:\(error?.localizedDescription ?? "error")")
                dispatchGroup.leave()
                completion(nil)
                return
            }
            guard let metadata = metadata else {
                print("saveVideoToFirebase - metadata 錯誤")
                dispatchGroup.leave()
                completion(nil)
                return
            }
            print("saveVideoToFirebase - Uploaded Size: \(metadata.size) bytes")
            videoRef.downloadURL { url, error in
                defer { dispatchGroup.leave() }
                guard error == nil else {
                    print("saveVideoToFirebase - downloadURL error:\(error?.localizedDescription ?? "error")")
                    completion(nil)
                    return
                }
                guard let url = url else {
                    print("saveVideoToFirebase - downloadURL 失敗")
                    completion(nil)
                    return
                }
                print("saveVideoToFirebase - downloadURL:\(url)")
                completion(url)
            }
        }
    }
//    func saveImageToFirebase(completion: @escaping (URL?) -> Void) {
//        guard let url = url else {
//            print("saveVideoToFirebase - 沒有 url")
//            completion(nil)
//            return
//        }
//        let asset = AVURLAsset(url: url, options: nil)
//        var imageData: Data?
//        let dispatchGroup = DispatchGroup()
//        dispatchGroup.enter()
//        generateThumbnail(for: asset, at: CMTime(seconds: 0.5, preferredTimescale: 600)) { [weak self] image in
//            guard let image = image,
//                  let thumbnailData = image.jpegData(compressionQuality: 0.75) else {
//                print("Failed to convert UIImage to Data")
//                return
//            }
//            imageData = thumbnailData
//            print("imageData:\(imageData!)")
//            dispatchGroup.enter()
//            let storage = Storage.storage()
//            let storageRef = storage.reference()
//            let imageRef = storageRef.child("images/\(UUID().uuidString).png")
//            
//            guard let imageData = imageData else {
//                print("no imageData")
//                return
//            }
//            let uploadTask = imageRef.putData(imageData, metadata: nil) { metadata, error in
//                if let error = error {
//                    print("Error uploading image: \(error.localizedDescription)")
//                } else {
//                    print("Upload successful, metadata: \(String(describing: metadata))")
//                }
//            }
//            imageRef.downloadURL { url, error in
//                defer { dispatchGroup.leave() }
//                guard error == nil else {
//                    print("downloadURL error:\(error?.localizedDescription ?? "error")")
//                    completion(nil)
//                    return
//                }
//                guard let url = url else {
//                    print("saveImageToFirebase - downloadURL 失敗")
//                    completion(nil)
//                    return
//                }
//                print("saveImageToFirebase - downloadURL:\(url)")
//                completion(url)
//            }
//        }
//       
//        dispatchGroup.notify(queue: .main) {
//            
//        }
//    }
    func saveImageToFirebase(completion: @escaping (URL?) -> Void) {
        guard let videoUrl = self.url else {
            print("saveVideoToFirebase - 沒有 url")
            completion(nil)
            return
        }
        let asset = AVURLAsset(url: videoUrl, options: nil)
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageRef = storageRef.child("images/\(UUID().uuidString).png")

        generateThumbnail(for: asset, at: CMTime(seconds: 0.5, preferredTimescale: 600)) { image in
            guard let image = image, let imageData = image.jpegData(compressionQuality: 0.75) else {
                print("Failed to convert UIImage to Data")
                completion(nil)
                return
            }
            
            print("imageData ready: \(imageData.count) bytes")
            imageRef.putData(imageData, metadata: nil) { metadata, error in
                guard error == nil else {
                    print("Error uploading image: \(error!.localizedDescription)")
                    completion(nil)
                    return
                }
                print("Upload successful, metadata: \(String(describing: metadata))")
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

    func generateThumbnail(for asset: AVAsset, at time: CMTime, completion: @escaping (UIImage?) -> Void) {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, error in
            if let image = image, error == nil {
                let thumbnail = UIImage(cgImage: image)
                completion(thumbnail)
            } else {
                print("Error generating thumbnail: \(String(describing: error))")
                completion(nil)
            }
        }
    }
    func presentLoginViewController() {
        let loginViewController = LoginViewController()
        present(loginViewController, animated: true)
    }
}
