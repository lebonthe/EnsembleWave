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
    var title: String = "Title"
    func setupUI() {
        contentView.addSubview(contentLabel)
        contentView.backgroundColor = .black
        contentLabel.textColor = .white
        let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "NotoSansTC-Bold", size: 20) ?? UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.white,
                .kern: 1.5
            ]
        let titleAttributedString = NSAttributedString(string: title + " ", attributes: titleAttributes)
        let contentAttributedString = attributedTextForm(content: contentText, size: 18, kern: 0, color: .white, font: "NotoSansTC-Regular")
        let combinedAttributedString = NSMutableAttributedString()
            combinedAttributedString.append(titleAttributedString)
            combinedAttributedString.append(contentAttributedString)
        contentLabel.attributedText = combinedAttributedString
        contentLabel.numberOfLines = 0
        NSLayoutConstraint.activate([
            contentLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}
