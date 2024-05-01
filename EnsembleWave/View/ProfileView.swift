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
}
