//
//  OptionsCell.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/17.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
protocol OptionsCellDelegate: AnyObject {
    func updateLikeStatus(postId: String, hasLiked: Bool)
    
    func showReplyPage(from cell: UITableViewCell, cellIndex: Int, postID: String)
    
    func presentRecordingPage(postID: String/*, localVideoURL: URL*/)
    
    func viewControllerForPresentation() -> UIViewController?
    
    func presentLoginViewController()
    
    func getLocalVideoURL(postID: String) -> URL?
    
    func presentReportPage(postID: String, userID: String)
    
    func blockUser(postID: String, userID: String)
}

class OptionsCell: UITableViewCell {
    weak var delegate: OptionsCellDelegate?
    let db = Firestore.firestore()
    var postID: String = "" {
        didSet {
            print("postID did set: \(postID)")
        }
    }
    var heartButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    var goToReplyButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    var ensembleButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    var isUserLiked: Bool = false
    var cellIndex: IndexPath?
    var reportButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    func setupUI() {
        contentView.backgroundColor = .black
        contentView.addSubview(heartButton)
        if isUserLiked {
            heartButton.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .normal)
        } else {
            heartButton.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
        }
        heartButton.tintColor = .white
        heartButton.addTarget(self, action: #selector(tapLike), for: .touchUpInside)
        contentView.addSubview(goToReplyButton)
        goToReplyButton.setBackgroundImage(UIImage(systemName: "message"), for: .normal)
        goToReplyButton.tintColor = .white
        goToReplyButton.addTarget(self, action: #selector(reply), for: .touchUpInside)
        ensembleButton.tintColor = .white
        ensembleButton.setImage(UIImage(systemName: "music.mic"), for: .normal)
//        ensembleButton.setTitle("Co-Play", for: .normal)
        ensembleButton.setAttributedTitle(attributedTextForm(content: "Co-Play", size: 16, kern: 0, color: UIColor.white), for: .normal)
        ensembleButton.setTitleColor(.white, for: .normal)
        ensembleButton.addTarget(self, action: #selector(checkForEnsemble), for: .touchUpInside)
        ensembleButton.backgroundColor = CustomColor.red
        ensembleButton.layer.cornerRadius = 8
        contentView.addSubview(ensembleButton)
        reportButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
//        reportButton.backgroundColor = .red
        reportButton.tintColor = CustomColor.gray2
        reportButton.addTarget(self, action: #selector(showReportSheet), for: .touchUpInside)
        contentView.addSubview(reportButton)
        let buttonSize = 28.0
        NSLayoutConstraint.activate([
            heartButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            heartButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            heartButton.widthAnchor.constraint(equalToConstant: buttonSize),
            heartButton.heightAnchor.constraint(equalToConstant: buttonSize),
//            heartButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            goToReplyButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            goToReplyButton.leadingAnchor.constraint(equalTo: heartButton.trailingAnchor, constant: 16),
            goToReplyButton.widthAnchor.constraint(equalToConstant: buttonSize),
            goToReplyButton.heightAnchor.constraint(equalToConstant: buttonSize),
//            goToReplyButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            ensembleButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            ensembleButton.leadingAnchor.constraint(equalTo: goToReplyButton.trailingAnchor, constant: 16),
            ensembleButton.widthAnchor.constraint(equalToConstant: 150),
            ensembleButton.heightAnchor.constraint(equalToConstant: buttonSize),
//            ensembleButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
            reportButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            reportButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            reportButton.widthAnchor.constraint(equalToConstant: buttonSize),
            reportButton.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
    }
    
    @objc func reply() {
        guard Auth.auth().currentUser != nil else {
            delegate?.presentLoginViewController()
            return
            }
        guard let cellIndex = cellIndex else {
            print("no cellIndex")
            return
        }
        print("postID:\(postID)")
        delegate?.showReplyPage(from: self, cellIndex: cellIndex.section, postID: postID)
    }
    @objc func tapLike() {
        guard Auth.auth().currentUser != nil else {
            delegate?.presentLoginViewController()
            return
            }
        if isUserLiked {
            isUserLiked = false
            heartButton.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
            // 刪除資料
            deleteLike()
        } else {
            isUserLiked = true
            heartButton.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .normal)
            // 新增資料
            addLike()
        }
    }

    func addLike() {
        print("=== postID: \(postID)")
        
        guard let user = Auth.auth().currentUser else {
            return
        }
        print("=== UserUid: \(String(user.uid))")
        let userLikeRef = db.collection("Posts").document(postID).collection("whoLike").document("\(String(describing: user.uid))")
        userLikeRef.setData(["userID": "\(String(describing: user.uid))"]) { [weak self] error in
            if let error = error {
                print("Error adding like: \(error)")
            } else {
                self?.delegate?.updateLikeStatus(postId: self?.postID ?? "", hasLiked: true)
            }
        }
    }

    func deleteLike() {
        guard let user = Auth.auth().currentUser else {
            return
        }
        let userLikeRef = db.collection("Posts").document(postID).collection("whoLike").document("\(String(describing: user.uid))")
        userLikeRef.delete { [weak self] error in
            if let error = error {
                print("Error removing like: \(error)")
            } else {
                self?.delegate?.updateLikeStatus(postId: self?.postID ?? "", hasLiked: false)
            }
        }
    }
    @objc func checkForEnsemble() {
        guard Auth.auth().currentUser != nil else {
            delegate?.presentLoginViewController()
            return
            }
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
       
        let actionImport = UIAlertAction(title: "輸入創作", style: .default) {_ in
//            if let localVideoURL = self.delegate?.getLocalVideoURL(postID: self.postID) {
//                self.delegate?.presentRecordingPage(postID: self.postID, localVideoURL: localVideoURL)
//            } else {
//                print("Local video URL not available")
//            }
            self.delegate?.presentRecordingPage(postID: self.postID/*, localVideoURL: localVideoURL*/)
        }
        controller.addAction(actionImport)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        controller.addAction(cancelAction)
        // Check if the device is iPad to configure popover presentation
        if let popoverController = controller.popoverPresentationController {
            let sourceView = self.contentView
                popoverController.sourceView = sourceView
                popoverController.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.maxY, width: 0, height: 0)
                popoverController.permittedArrowDirections = [] 
            
        }
        if let vc = delegate?.viewControllerForPresentation() {
                vc.present(controller, animated: true, completion: nil)
            }
        // TODO: 回來調整 iPad 版型
//        if let vc = delegate?.viewControllerForPresentation() {
//               // Set the sourceView to the tableView of the viewController
//               if let popoverController = controller.popoverPresentationController {
//                   popoverController.sourceView = vc.tableView // Make sure your delegate can provide the tableView
//                   popoverController.sourceRect = CGRect(x: vc.tableView.bounds.midX, y: vc.tableView.bounds.maxY, width: 0, height: 0)
//                   popoverController.permittedArrowDirections = [] // No arrow needed
//               }
//               vc.present(controller, animated: true, completion: nil)
//           }
    }
    @objc func showReportSheet() {
        guard let user = Auth.auth().currentUser else {
            delegate?.presentLoginViewController()
            return
            }
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let reportAction = UIAlertAction(title: "回報問題", style: .default) {_ in
            self.delegate?.presentReportPage(postID: self.postID, userID: user.uid)
        }
        controller.addAction(reportAction)
        let blockAction = UIAlertAction(title: "封鎖此帳號發佈的內容", style: .default){_ in
            self.delegate?.blockUser(postID: self.postID, userID: user.uid)
        }
        controller.addAction(blockAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        controller.addAction(cancelAction)
        // Check if the device is iPad to configure popover presentation
        if let popoverController = controller.popoverPresentationController {
            let sourceView = self.contentView
                popoverController.sourceView = sourceView
                popoverController.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.maxY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
        }
        if let vc = delegate?.viewControllerForPresentation() {
                vc.present(controller, animated: true, completion: nil)
            }
    }
}
