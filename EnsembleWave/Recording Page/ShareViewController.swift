//
//  ShareViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/11.
//

import UIKit
import Photos

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

}
