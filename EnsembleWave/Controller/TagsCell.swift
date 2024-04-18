//
//  TagsCell.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/17.
//

import UIKit

class TagsCell: UITableViewCell {

    var tagsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var tagsText: String = "#EnsembleWave"
    func setupUI() {
        contentView.addSubview(tagsLabel)
        tagsLabel.text = tagsText
        NSLayoutConstraint.activate([
            tagsLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            tagsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tagsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            tagsLabel.heightAnchor.constraint(equalToConstant: 22),
            tagsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])
    }
}
