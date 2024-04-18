//
//  ReplaysCell.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/17.
//

import UIKit

class ReplaysCell: UITableViewCell {

    var replayButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    var replayContent: [ReplayContent] = []
    func setupUI() {
        contentView.addSubview(replayButton)
        replayButton.setTitle("\(replayContent.count) 更多留言", for: .normal)
        replayButton.setTitleColor(.blue, for: .normal)
        NSLayoutConstraint.activate([
            replayButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            replayButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            replayButton.widthAnchor.constraint(equalToConstant: 100),
            replayButton.heightAnchor.constraint(equalToConstant: 22),
            replayButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])
    }

}
