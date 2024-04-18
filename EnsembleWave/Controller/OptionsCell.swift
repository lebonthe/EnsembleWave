//
//  OptionsCell.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/17.
//

import UIKit

class OptionsCell: UITableViewCell {

    var heartButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    var isUserLiked: Bool = false
    func setupUI() {
        contentView.addSubview(heartButton)
        heartButton.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
        heartButton.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .selected)
        NSLayoutConstraint.activate([
            heartButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            heartButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            heartButton.widthAnchor.constraint(equalToConstant: 36),
            heartButton.heightAnchor.constraint(equalToConstant: 36),
            heartButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])
    }
    
}
