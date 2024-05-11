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
import MJRefresh
class WallViewController: UIViewController {
    var listenerRegistration: ListenerRegistration?
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
        tableView.sectionIndexBackgroundColor = .black
        tableView.backgroundColor = .black
        refresh()
    }
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden = false
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        listenerRegistration?.remove()
    }
    func listenToPosts() {
        print("=========listenToPosts==========")
        if let currentUser = Auth.auth().currentUser {
            let userID = currentUser.uid
            FirebaseManager.shared.fetchUserBlackList(userID: userID) { [weak self] blackListIDs, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching user blacklist: \(error.localizedDescription)")
                    return
                }
                
                let filterIDs = blackListIDs ?? []
                print("BlackList: \(filterIDs)")
                self.setupPostListener(withBlackList: filterIDs)
            }
        } else {
            setupPostListener(withBlackList: [])
        }
    }
    func scrollToTop() {
        if !self.posts.isEmpty {
                let indexPath = IndexPath(row: 0, section: 0)
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
    }
    func refresh() {
        tableView.mj_header = MJRefreshNormalHeader {
            self.posts.removeAll()
            self.listenToPosts()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.tableView.mj_header?.endRefreshing()
            }
        }
    }
    private func setupPostListener(withBlackList blackListIDs: [String]) {
        var query = db.collection("Posts").order(by: "createdTime")
        if !blackListIDs.isEmpty {
            query = query.whereField("userID", notIn: blackListIDs)
        }

        listenerRegistration = query.addSnapshotListener { [weak self] querySnapshot, error in
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
                    
//                    if change.type == .added {
//                        self.posts.insert(post, at: 0)
//                    } else if let index = self.posts.firstIndex(where: { $0.id == post.id }) {
//                        self.posts[index] = post
//                    }
                    if change.type == .added {
                        if !self.posts.contains(where: { $0.id == post.id }) {
                            self.posts.insert(post, at: 0)
                        }
                    } else if let index = self.posts.firstIndex(where: { $0.id == post.id }) {
                        self.posts[index] = post
                    }

                    self.setupLikesListener(for: postId)
                    self.updateLikeAndReplyDetails(for: postId)
                case .removed:
                    self.posts.removeAll { $0.id == postId }
                    self.postLikesStatus.removeValue(forKey: postId)
                }
            }
            self.tableView.reloadData()
        }
    }

private func updateLikeAndReplyDetails(for postId: String) {
    let whoLikeRef = self.db.collection("Posts").document(postId).collection("whoLike")
    whoLikeRef.getDocuments { (querySnapshot, error) in
        DispatchQueue.main.async {
            guard let documents = querySnapshot?.documents else {
                print("Error fetching whoLike documents: \(error?.localizedDescription ?? "No error")")
                return
            }
            let userIDs = documents.compactMap { $0.documentID }
            if let user = Auth.auth().currentUser {
                let isLiked = userIDs.contains("\(String(describing: user.uid))")
                self.postLikesStatus[postId] = isLiked
            }
        }
    }
    let repliesRef = self.db.collection("Posts").document(postId).collection("replies")
    repliesRef.getDocuments { (querySnapshot, error) in
        DispatchQueue.main.async {
            guard let documents = querySnapshot?.documents else {
                print("Error fetching replies documents: \(error?.localizedDescription ?? "No error")")
                return
            }
            let count = documents.count
            self.postReplies[postId] = count
        }
    }
}

//    private func listenToPosts() {
//        db.collection("Posts").order(by: "createdTime")
//          .addSnapshotListener { [weak self] querySnapshot, error in
//            guard let self = self, let snapshot = querySnapshot else {
//              print("Error listening for post updates: \(error?.localizedDescription ?? "No error")")
//              return
//            }
//
//            snapshot.documentChanges.forEach { change in
//                let postId = change.document.documentID
//    
//                switch change.type {
//                case .added, .modified:
//                    let data = change.document.data()
//                    let post = Post(dic: data)
//                    self.fetchUserName(userID: post.userID)
//                    if let ensembleUserID = post.ensembleUserID {
//                        self.fetchEnsembleUserName(userID: ensembleUserID)
//                    }
//                    
//                    if change.type == .added {
//                        self.posts.insert(post, at: 0)
//                    } else if let index = self.posts.firstIndex(where: { $0.id == post.id }) {
//                        self.posts[index] = post
//                    }
//
//                    // Set up or update the listener for the whoLike collection of this post
//                    self.setupLikesListener(for: postId)
//                    
//                    let whoLikeRef = self.db.collection("Posts").document(postId).collection("whoLike")
//                    whoLikeRef.getDocuments { (querySnapshot, error) in
//                        DispatchQueue.main.async {
//                            guard let documents = querySnapshot?.documents else {
//                                print("Error fetching whoLike documents: \(error?.localizedDescription ?? "No error")")
//                                return
//                            }
//                            let userIDs = documents.compactMap { $0.documentID }
//                            if let user = Auth.auth().currentUser {
//                                let isLiked = userIDs.contains("\(String(describing: user.uid))")
//                                self.postLikesStatus[postId] = isLiked
//                                print("Post ID: \(postId), Liked by current user: \(isLiked)")
//                            }
//                        }
//                    }
//                    let repiesRef = self.db.collection("Posts").document(postId).collection("replies")
//                    repiesRef.getDocuments { (querySnapshot, error) in
//                        DispatchQueue.main.async {
//                            guard let documents = querySnapshot?.documents else {
//                                print("Error fetching replies documents: \(error?.localizedDescription ?? "No error")")
//                                return
//                            }
//                            let count = documents.count
//                            print("replies documents.count: \(documents.count)")
//                            self.postReplies[postId] = count
//                        }
//                    }
//                case .removed:
//                    self.posts.removeAll { $0.id == postId }
//                    self.postLikesCount.removeValue(forKey: postId)
//                    self.postLikesStatus.removeValue(forKey: postId)
//                }
//            }
//            self.tableView.reloadData()
//        }
//    }

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
        print("post:\(post)")
        switch indexPath.row {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(VideoCell.self)", for: indexPath) as? VideoCell else {
                fatalError("error when building VideoCell")
            }
            print("====post.imageURL: \(post.imageURL ?? "no")")
            cell.imageURLString = post.imageURL
            print("====post.videoURL: \(post.videoURL)")
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
            print("post: \(post)")
            print("cell did sent cell.postID: \(cell.postID)")
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
            cell.title = post.title
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
    // 取得合奏模式的影片 url 影片長度與 userID
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
            return (usersNames[userID] ?? "") + " ➕ \(ensembleUsersNames[ensembleUserID] ?? "")" + " 🎙️ " // \(title)
        } else {
            return (usersNames[userID] ?? "") + " 🎙️ " //  \(title)
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
        headerView.backgroundColor = UIColor.black

        let headerLabel = UILabel(frame: CGRect(x: 16, y: 0, width: tableView.bounds.size.width, height: 30))
        headerLabel.textColor = UIColor.white
        if let text = self.tableView(tableView, titleForHeaderInSection: section) {
            headerLabel.attributedText = attributedTextForm(content: text, size: 18, kern: 0, color: .white)
        }
        headerView.addSubview(headerLabel)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleHeaderTap(_:)))
        headerView.addGestureRecognizer(tapGesture)
        headerView.tag = section
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        30
    }
}

extension WallViewController: OptionsCellDelegate {
    func presentReportPage(postID: String, userID: String) {
        let controller = ReportTableViewController()
        controller.view.backgroundColor = .black
        controller.postID = postID
        present(controller, animated: true)
    }
    
    func blockUser(postID: String, userID: String) {
        let alert = UIAlertController(title: "確定要封鎖該使用者？", message: "一經封鎖，之後您將看不到該使用者的影片與發文", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) {_ in
            guard let user = Auth.auth().currentUser else {
                print("未登入")
                return
            }
            FirebaseManager.shared.addToUserBlackList(currentUserID: user.uid, blockUserID: userID) { success, error in
                if error != nil {
                    print("addToUserBlackList error: \(error?.localizedDescription ?? "不明原因錯誤")")
                    return
                }
                DispatchQueue.main.async {
                    CustomFunc.customAlert(title: "已封鎖", message: "已封鎖該名使用者的全部貼文與回覆", vc: self) {
                        self.listenToPosts()
                    }
                }
            }
        }
        let cancelAction = UIAlertAction(title: "cancel", style: .cancel)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    func viewControllerForPresentation() -> UIViewController? {
            return self
        }
    func presentRecordingPage(postID: String/*, localVideoURL: URL*/) {
        animView = AnimationManager.shared.playAnimation(view: self.view, animationName: "Animation02", loopMode: .loop)
        
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
                    if let animView = self?.animView {
                        AnimationManager.shared.stopAnimation(animView: animView)
                    }
                    self?.tabBarController?.tabBar.isHidden = true
                    self?.navigationController?.pushViewController(controller, animated: true)
                }
            } else {
                if let animView = self.animView {
                    AnimationManager.shared.stopAnimation(animView: animView)
                }
                print("Required data not found or document does not exist.")
            }
        }
    }
    
    func showReplyPage(from cell: UITableViewCell, cellIndex: Int, postID: String) {
        
        let controller = ReplyViewController()
        controller.replies = posts[cellIndex].replies
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
