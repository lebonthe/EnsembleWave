//
//  PostToWallViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/17.
//

import UIKit
import AVFoundation
import IQKeyboardManagerSwift
import Firebase
import FirebaseCore
import FirebaseFirestore

class PostToWallViewController: UIViewController {

    @IBOutlet weak var videoView: UIView!
    
    @IBOutlet weak var titleTextField: UITextField!
    
    @IBOutlet weak var contentTextView: UITextView!
    
    @IBOutlet weak var tagTextField: UITextField!
    
    @IBOutlet weak var ensembleUserLabel: UILabel!
    @IBOutlet weak var ensembleUserNameLabel: UILabel!
    var duration: Int?
    var url: URL?
    var imageURL: URL?
    var replayButton = UIButton()
    let player = AVPlayer()
    let db = Firestore.firestore()
    var ensembleUserID: String?
    var ensembleUserName: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        if let ensembleUserID = ensembleUserID {
            UserManager.shared.fetchUserName(userID: ensembleUserID) { userName, error in
                if let ensembleUserID = userName {
                    self.ensembleUserNameLabel.text = userName
                    self.ensembleUserLabel.isHidden = false
                    self.ensembleUserNameLabel.isHidden = false
                } else {
                    self.ensembleUserLabel.isHidden = true
                    self.ensembleUserNameLabel.isHidden = true
                }
            }
        }
            
        if let url = url {
            print("url:\(url) 傳入 PostToWallViewController")
            configure(url: url)
            setupReplayButton()
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    func configure(url: URL) {
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = videoView.bounds
        playerLayer.videoGravity = .resizeAspectFill
        videoView.layer.addSublayer(playerLayer)
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        setupObserversForPlayerItem(playerItem, with: player)
        player.play()
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 200
    }
    @IBAction func postButtonTapped(_ sender: UIButton) {
        if titleTextField.text == nil || contentTextView.text == nil || tagTextField.text == nil {
            let alertViewController = UIAlertController(title: "請完成所有欄位", message: "跟大家分享你的創作想法", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel)
            alertViewController.addAction(okAction)
            present(alertViewController, animated: true)
        } else {
            Task {
                let success = await postToWall()
                if success {
                    let alertViewController = UIAlertController(title: "影片已發布", message: "", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                        self.dismiss(animated: true) {
                            self.tabBarController?.selectedIndex = 1
                        }
                    }
                    alertViewController.addAction(okAction)
                    present(alertViewController, animated: true)
                } else {
                    let alertViewController = UIAlertController(title: "Oops!", message: "影片發布失敗", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default)
                    alertViewController.addAction(okAction)
                    present(alertViewController, animated: true)
                }
            }
        }
    }
    func postToWall() async -> Bool{
        guard let titleText = titleTextField.text,
              let contentText = contentTextView.text,
              let tagText = tagTextField.text,
              let url = url,
              let imageURL = imageURL,
              let duration = duration else {
            print("缺少發文內容")
            return false
        }
        var post: [String: Any] = [
            "videoURL": "\(url)",
            "imageURL": "\(imageURL)",
            "title": titleText,
            "createdTime": FieldValue.serverTimestamp(),
            "userID": "09876543",
            "content": contentText,
            "importMusic": "Music composed by AI",
            "duration": duration,
            "tag": tagText
        ]
        if let ensembleUserID = ensembleUserID {
            post["ensembleUserID"] = ensembleUserID
        }
        do {
            let ref = try await db.collection("Posts").addDocument(data: post)
            print("Document added with ID: \(ref.documentID)")
            let id = ref.documentID
            try await db.collection("Posts").document(id).updateData([
                "id": id
            ])
            return true
        } catch {
            print("Error adding document: \(error)")
            return false
        }
    }
    
    func setupObserversForPlayerItem(_ playerItem: AVPlayerItem, with player: AVPlayer) {
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    @objc func videoDidEnd(notification: NSNotification) {
        replayButton.isHidden = false
    }
    func setupReplayButton() {
        replayButton.setBackgroundImage(UIImage(systemName: "play.circle"), for: .normal)
        replayButton.addTarget(self, action: #selector(replayVideo), for: .touchUpInside)
        view.addSubview(replayButton)
        replayButton.isHidden = true
        replayButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            replayButton.centerXAnchor.constraint(equalTo: videoView.centerXAnchor),
            replayButton.centerYAnchor.constraint(equalTo: videoView.centerYAnchor),
            replayButton.widthAnchor.constraint(equalToConstant: 50),
            replayButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    @objc func replayVideo() {
        let startTime = CMTime(seconds: 0, preferredTimescale: 1)
        player.seek(to: startTime) { [weak self] completed in
            if completed {
                self?.player.play()
                self?.replayButton.isHidden = true
            }
        }
    }
    
}
