//
//  TitleCell.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/13.
//

import UIKit

class TitleCell: UITableViewCell {
    var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var title: String = "Title"
   
    func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.backgroundColor = .black
        let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "NotoSansTC-Bold", size: 20) ?? UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.white,
                .kern: 1.5
            ]
        let titleAttributedString = NSAttributedString(string: title + " ", attributes: titleAttributes)
        titleLabel.attributedText = titleAttributedString
        titleLabel.numberOfLines = 0
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}
