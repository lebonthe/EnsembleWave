//
//  ContentCell.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/17.
//

import UIKit

class ContentCell: UITableViewCell {
    var contentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var contentText: String = "This is what they said..."
   
    func setupUI() {
        contentView.addSubview(contentLabel)
        contentView.backgroundColor = .black
        contentLabel.textColor = .white
        let contentAttributedString = attributedTextForm(content: contentText, size: 18, kern: 0, color: .white, font: "NotoSansTC-Light")
        contentLabel.attributedText = contentAttributedString
        contentLabel.numberOfLines = 0
        NSLayoutConstraint.activate([
            contentLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}
