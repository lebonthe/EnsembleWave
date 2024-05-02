//
//  ProfileView.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/2.
//

import UIKit

class ProfileView: UIView {
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var likesCountLabel: UILabel!
    @IBOutlet var ensembleCountLabel: UILabel!
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var instrumentImageView: UIImageView!
    @IBOutlet var aboutMeLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        configureImageView()
        collectionView.collectionViewLayout = configureCollectionViewLayout()
    }
    private func commonInit() {
        
        if let view = Bundle.main.loadNibNamed("ProfileView", owner: self, options: nil)?.first as? UIView {
            view.frame = self.bounds
            addSubview(view)
            
        }
    }
    private func configureImageView() {
        userImageView.layer.cornerRadius = userImageView.frame.height / 2
        userImageView.clipsToBounds = true
    }
    private func configureCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalWidth(0.5))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
        }

//    private func setupCollectionView() {
//        collectionView.dataSource = self
//        collectionView.delegate = self
//        collectionView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
//    }
}

