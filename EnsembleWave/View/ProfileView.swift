//
//  ProfileView.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/2.
//

import UIKit
import Kingfisher
import FirebaseAuth
class ProfileView: UIView {
    @IBOutlet weak var userNameLabel: UILabel!
//    @IBOutlet var likesCountLabel: UILabel!
//    @IBOutlet var ensembleCountLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
//    @IBOutlet var instrumentImageView: UIImageView!
//    @IBOutlet var aboutMeLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    lazy var posts = [Post]()
    var dataSource: UICollectionViewDiffableDataSource<Section, Post>!
    var userID: String?
    override init(frame: CGRect) {
        super.init(frame: frame)
//        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
//        commonInit()
    }
    override func awakeFromNib() {
        super.awakeFromNib()
//        updateUserPosts()
//        configureImageView()
//        collectionView.collectionViewLayout = configureCollectionViewLayout()
//        collectionView.register(UserVideoCell.self, forCellWithReuseIdentifier: "UserVideoCell")
//        configureDataSource()
//        collectionView.backgroundColor = CustomColor.black
    }
    func configureWithUserID(userID: String) {
          self.userID = userID
          updateUserPosts()
          configureImageView()
          collectionView.collectionViewLayout = configureCollectionViewLayout()
          collectionView.register(UserVideoCell.self, forCellWithReuseIdentifier: "UserVideoCell")
          configureDataSource()
          collectionView.backgroundColor = CustomColor.black
      }
    private func updateUserPosts() {
        guard let userID = userID else {
            print("查無此人")
            return
        }
        FirebaseManager.shared.listenToPosts(userID: userID, posts: posts) { /*[weak self]*/ newPosts in
            print("Closure is called with newPosts: \(newPosts)")
            print("New posts ready to assign: \(newPosts)")
            self.posts = newPosts
            print("strongSelf.posts:\(self.posts)")
            DispatchQueue.main.async {
                var snapshot = NSDiffableDataSourceSnapshot<Section, Post>()
                snapshot.appendSections([.main])
                snapshot.appendItems(self.posts)
                self.dataSource.apply(snapshot, animatingDifferences: true)
                print("apply snapshot:\(snapshot)")
            }
        }
    }
    private func commonInit() {
//        if let view = Bundle.main.loadNibNamed("ProfileView", owner: self, options: nil)?.first as? UIView {
//            view.frame = self.bounds
//            addSubview(view)
//            
//        }
    }
    func configure(with userInfo: User) {
        if userInfo.name == "" {
            userNameLabel.text = "Change name in settings."
        } else {
            userNameLabel.text = userInfo.name
        }
        print("userInfo.name:\(userInfo.name)")
        if let imageURLString =  userInfo.photoURL,
           let imageURL = URL(string: imageURLString) {
            userImageView.kf.setImage(
                with: imageURL
            )
        } else {
            userImageView.image = UIImage(named: "music_headphone_side_man")
        }
    }
    private func configureImageView() {
        userImageView.layer.cornerRadius = userImageView.frame.height / 2
        userImageView.contentMode = .scaleAspectFill
        userImageView.clipsToBounds = true
    }
    private func configureCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalWidth(0.5))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(0.5))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
        }
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Post>(collectionView: self.collectionView) { (collectionView, indexPath, post) -> UICollectionViewCell? in
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserVideoCell", for: indexPath) as? UserVideoCell else {
                fatalError("Cannot create new cell")
            }
            let item = indexPath.item
            cell.urlString = post.videoURL
            return cell
        }
        
        var initialSnapshot = NSDiffableDataSourceSnapshot<Section, Post>()
        initialSnapshot.appendSections([.main])
        initialSnapshot.appendItems(posts)
        dataSource.apply(initialSnapshot, animatingDifferences: false)
    }
}
