//
//  WallViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/17.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import Lottie
import AVFoundation
import FirebaseAuth
import Kingfisher
class WallViewController: UIViewController {
    
    let db = Firestore.firestore()
    var posts = [Post]()
    var userInfo: User?
    var usersNames: [String: String] = [:]
    var postLikesCount: [String: Int] = [:]
    var postLikesStatus: [String: Bool] = [:]
    var postReplies: [String: Int] = [:]
    var post: Post?
    @IBOutlet weak var tableView: UITableView!
    var animView: LottieAnimationView?
    var ensembleUsersNames: [String: String] = [:]
    override func viewDidLoad() {
        super.viewDidLoad()
        listenToPosts()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(VideoCell.self, forCellReuseIdentifier: "\(VideoCell.self)")
        tableView.register(OptionsCell.self, forCellReuseIdentifier: "\(OptionsCell.self)")
        tableView.register(LikesCountCell.self, forCellReuseIdentifier: "\(LikesCountCell.self)")
        tableView.register(ContentCell.self, forCellReuseIdentifier: "\(ContentCell.self)")
        tableView.register(TagsCell.self, forCellReuseIdentifier: "\(TagsCell.self)")
        tableView.register(RepliesCell.self, forCellReuseIdentifier: "\(RepliesCell.self)")
        tableView.sectionHeaderHeight = 25
        tableView.sectionIndexBackgroundColor = .clear
        tableView.backgroundColor = .black
    }
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden = false
    }
    private func listenToPosts() {
        db.collection("Posts").order(by: "createdTime")
          .addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self, let snapshot = querySnapshot else {
              print("Error listening for post updates: \(error?.localizedDescription ?? "No error")")
              return
            }

            snapshot.documentChanges.forEach { change in
                let postId = change.document.documentID
    
                switch change.type {
                case .added, .modified:
                    let data = change.document.data()
                    let post = Post(dic: data)
                    self.fetchUserName(userID: post.userID)
                    if let ensembleUserID = post.ensembleUserID {
                        self.fetchEnsembleUserName(userID: ensembleUserID)
                    }
                    
                    if change.type == .added {
                        self.posts.insert(post, at: 0)
                    } else if let index = self.posts.firstIndex(where: { $0.id == post.id }) {
                        self.posts[index] = post
                    }

                    // Set up or update the listener for the whoLike collection of this post
                    self.setupLikesListener(for: postId)
                    
                    let whoLikeRef = self.db.collection("Posts").document(postId).collection("whoLike")
                    whoLikeRef.getDocuments { (querySnapshot, error) in
                        DispatchQueue.main.async {
                            guard let documents = querySnapshot?.documents else {
                                print("Error fetching whoLike documents: \(error?.localizedDescription ?? "No error")")
                                return
                            }
                            let userIDs = documents.compactMap { $0.documentID }
                            let isLiked = userIDs.contains("\(String(describing: Auth.auth().currentUser?.uid))")
                            self.postLikesStatus[postId] = isLiked
                            print("Post ID: \(postId), Liked by current user: \(isLiked)")
                        }
                    }
                    let repiesRef = self.db.collection("Posts").document(postId).collection("replies")
                    repiesRef.getDocuments { (querySnapshot, error) in
                        DispatchQueue.main.async {
                            guard let documents = querySnapshot?.documents else {
                                print("Error fetching replies documents: \(error?.localizedDescription ?? "No error")")
                                return
                            }
                            let count = documents.count
                            print("replies documents.count: \(documents.count)")
                            self.postReplies[postId] = count
                        }
                    }
                case .removed:
                    self.posts.removeAll { $0.id == postId }
                    self.postLikesCount.removeValue(forKey: postId)
                    self.postLikesStatus.removeValue(forKey: postId)
                }
            }
            self.tableView.reloadData()
        }
    }

    private func fetchUserName(userID: String) {
        FirebaseManager.shared.fetchUserName(userID: userID) { [weak self] userName, error in
            DispatchQueue.main.async {
                if let userName = userName {
                    self?.usersNames[userID] = userName
                    self?.tableView.reloadData()
                } else if let error = error {
                    print("Error fetching user name: \(error)")
                }
            }
        }
    }
    private func fetchEnsembleUserName(userID: String) {
        FirebaseManager.shared.fetchUserName(userID: userID) { [weak self] userName, error in
                DispatchQueue.main.async {
                    if let userName = userName {
                        self?.ensembleUsersNames[userID] = userName
                        self?.tableView.reloadData()
                    } else if let error = error {
                        print("Error fetching user name: \(error)")
                    }
                }
            }
    }
    private func pushProfileViewForUser(userID: String) {
//        guard let profileView = Bundle.main.loadNibNamed("ProfileView", owner: self, options: nil)?.first as? ProfileView else {
//            print("無法加載 ProfileView")
//            return
//        }
//       
        let userWallViewController = UserWallViewController()
//        profileViewController.view.addSubview(profileView)
        userWallViewController.userID = userID
//        profileView.frame = profileViewController.view.bounds
        navigationController?.pushViewController(userWallViewController, animated: true)
    }
    @objc private func handleHeaderTap(_ gesture: UITapGestureRecognizer) {
        if let section = gesture.view?.tag {
            let userID = posts[section].userID
            pushProfileViewForUser(userID: userID)
        }
    }

}
extension WallViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        print("posts.count:\(posts.count)")
        return posts.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        6
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.section]
        switch indexPath.row {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(VideoCell.self)", for: indexPath) as? VideoCell else {
                fatalError("error when building VideoCell")
            }
            print("====post.videoURL: \(post.videoURL)")
            print("====post.imageURL: \(post.imageURL ?? "no")")
            cell.imageURLString = post.imageURL
            cell.urlString = post.videoURL
            cell.setupUI()
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(OptionsCell.self)", for: indexPath) as? OptionsCell else {
                fatalError("error when building OptionsCell")
            }
            cell.delegate = self
            cell.isUserLiked = self.postLikesStatus[post.id] ?? false
            cell.postID = post.id
            cell.cellIndex = indexPath
            cell.setupUI()
            return cell
        case 2:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(LikesCountCell.self)", for: indexPath) as? LikesCountCell else {
                fatalError("error when building OptionsCell")
            }
            let postId = post.id
            cell.likesCount = postLikesCount[postId] ?? 0
            print("likesCount in cell 2: \(cell.likesCount)")
            cell.setupUI()
            return cell
        case 3:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(ContentCell.self)", for: indexPath) as? ContentCell else {
                fatalError("error when building OptionsCell")
            }
            cell.contentText = post.content
            cell.setupUI()
            return cell
        case 4:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(TagsCell.self)", for: indexPath) as? TagsCell else {
                fatalError("error when building OptionsCell")
            }
            cell.tagsText = post.tag
            cell.setupUI()
            return cell
        case 5:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(RepliesCell.self)", for: indexPath) as? RepliesCell else {
                fatalError("error when building OptionsCell")
            }
            cell.delegate = self
            print("cell.replyCount: \(cell.replyCount)")
            cell.replyCount = postReplies[post.id] ?? 0
            cell.postID = post.id
            cell.cellIndex = indexPath
            cell.setupUI()
            return cell
        default:
            fatalError("Out of cell types")
        }
    }
    func importAnimation() {
        if animView == nil {
            animView = LottieAnimationView(name: "Animation00", bundle: .main)
            animView?.frame = CGRect(x: 200, y: 350, width: 300, height: 300)
            animView?.center = self.view.center
            animView?.loopMode = .loop
            animView?.animationSpeed = 2
            self.view.addSubview(animView!)
        }
        animView?.play()
    }
    func stopAnimation() {
            DispatchQueue.main.async { [weak self] in
                self?.animView?.stop()
                self?.animView?.removeFromSuperview()
            }
        }
    func getVideoAndUserID(postID: String) async -> (videoURL: String, userID: String, duration: Int)? {
        do {
            let document = try await db.collection("Posts").document(postID).getDocument()
            if document.exists, let data = document.data(),
               let videoURL = data["videoURL"] as? String,
               let userID = data["userID"] as? String,
               let duration = data["duration"] as? Int {
                return (videoURL, userID, duration)
            }
        } catch {
            print("Error getting document: \(error)")
        }
        return nil
    }
}

extension WallViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let userID = posts[section].userID
        let title = posts[section].title
        print("usersNames:\(usersNames)")
        if let ensembleUserID = posts[section].ensembleUserID {
            return (usersNames[userID] ?? "") + " ➕ \(ensembleUsersNames[ensembleUserID] ?? "")" + " 🎙️ \(title)"
        } else {
            return (usersNames[userID] ?? "") + " 🎙️ \(title)"
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = indexPath.row
        if row == 0 {
            return view.window?.windowScene?.screen.bounds.width ?? 200
        } else {
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear

        let headerLabel = UILabel(frame: CGRect(x: 16, y: 0, width: tableView.bounds.size.width, height: 30))
        headerLabel.textColor = UIColor.white 
        headerLabel.text = self.tableView(tableView, titleForHeaderInSection: section)
        headerView.addSubview(headerLabel)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleHeaderTap(_:)))
        headerView.addGestureRecognizer(tapGesture)
        headerView.tag = section
        return headerView
    }
    
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        var urlsToPrefetch = [URL]()
//        for index in indexPath.section..<min(indexPath.section + 5, posts.count) {
//            if let imageURLString = posts[index].imageURL,
//                let url = URL(string: imageURLString) {
//                urlsToPrefetch.append(url)
//            }
//        }
//        let prefetcher = ImagePrefetcher(urls: urlsToPrefetch)
//        prefetcher.start()
//        print("===prefetcher.start()===")
//    }
}

extension WallViewController: OptionsCellDelegate {
    
    func viewControllerForPresentation() -> UIViewController? {
            return self
        }
    func presentRecordingPage(postID: String/*, localVideoURL: URL*/) {
        importAnimation()
        
        Task {
            if let (videoURL, userID, duration) = await getVideoAndUserID(postID: postID) {
                let length = duration
                DispatchQueue.main.async { [weak self] in
                    let storyboard = UIStoryboard(name: "Main", bundle: nil) 
                    guard let controller = storyboard.instantiateViewController(withIdentifier: "CreateViewController") as? CreateViewController else {
                        print("Unable to instantiate CreateViewController from storyboard.")
                        return
                    }
                    controller.ensembleVideoURL = videoURL//"\(localVideoURL)" // TODO: 回來改成本地檔案
                    controller.ensembleUserID = userID
                    controller.style = 1
                    controller.length = length
                    self?.stopAnimation()
                    self?.tabBarController?.tabBar.isHidden = true
                    self?.navigationController?.pushViewController(controller, animated: true)
                }
            } else {
                stopAnimation()
                print("Required data not found or document does not exist.")
            }
        }
    }
    
    func showReplyPage(from cell: UITableViewCell, cellIndex: Int, postID: String) {
        
        let controller = ReplyViewController()
//        controller.replies = posts[cellIndex].reply
        controller.postID = postID
        self.navigationController?.pushViewController(controller, animated: true)
    }
    func updateLikeStatus(postId: String, hasLiked: Bool) {
        let currentCount = postLikesCount[postId] ?? 0 // 這裡的 postLikesCount[postId] 是已經增加過的
        postLikesCount[postId] = max(0, currentCount /*+ adjustment*/)
        postLikesStatus[postId] = hasLiked

        if let index = posts.firstIndex(where: { $0.id == postId }) {
            DispatchQueue.main.async {
                let indexPath = IndexPath(row: 2, section: index) 
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
    private func setupLikesListener(for postId: String) {
        db.collection("Posts").document(postId).collection("whoLike")
          .addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error listening for likes updates: \(error)")
                return
            }

            let likesCount = querySnapshot?.documents.count ?? 0
            DispatchQueue.main.async {
                self.postLikesCount[postId] = likesCount
                if let index = self.posts.firstIndex(where: { $0.id == postId }) {
                    let indexPath = IndexPath(row: 2, section: index)
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        }
    }
 
    func presentLoginViewController() {
        let loginViewController = LoginViewController()
        present(loginViewController, animated: true)
    }
    
    func getLocalVideoURL(postID: String) -> URL? {
            if let index = posts.firstIndex(where: { $0.id == postID }),
               let cell = tableView.cellForRow(at: IndexPath(row: 0, section: index)) as? VideoCell {
                return cell.localVideoURL
            }
        return nil
    }
}
