//
//  RecordingTopView.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/16.
//

import UIKit

class RecordingTopView: UIView {
    let countdownLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 50, weight: .bold)
        label.textColor = .white
        return label
    }()
    let cameraPositionButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        button.tintColor = .white
        return button
    }()
    let cancelButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white
        return button
    }()
    let countdownButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.setBackgroundImage(UIImage(systemName: "clock.badge.checkmark"), for: .normal)
        button.setBackgroundImage(UIImage(systemName: "clock.badge.xmark"), for: .selected)
        return button
    }()
    let handPoseButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("🙅‍♀️", for: .normal)
        return button
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .black
        addSubview(countdownLabel)
        addSubview(cameraPositionButton)
        addSubview(cancelButton)
        addSubview(countdownButton)
        addSubview(handPoseButton)
        let buttonSize = 28.0
        NSLayoutConstraint.activate([
            countdownLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            countdownLabel.heightAnchor.constraint(equalToConstant: buttonSize),
            countdownButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            countdownButton.trailingAnchor.constraint(equalTo: cameraPositionButton.leadingAnchor, constant: -16),
            countdownButton.heightAnchor.constraint(equalToConstant: buttonSize),
            countdownButton.widthAnchor.constraint(equalToConstant: buttonSize),
            cameraPositionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            cameraPositionButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            cameraPositionButton.heightAnchor.constraint(equalToConstant: buttonSize),
            cameraPositionButton.widthAnchor.constraint(equalToConstant: buttonSize),
            cancelButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            cancelButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: buttonSize),
            cancelButton.widthAnchor.constraint(equalToConstant: buttonSize),
            handPoseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            handPoseButton.trailingAnchor.constraint(equalTo: countdownButton.leadingAnchor, constant: -16),
            handPoseButton.heightAnchor.constraint(equalToConstant: buttonSize),
            handPoseButton.widthAnchor.constraint(equalToConstant: buttonSize)
        ])
    }
    
    func updateCountdownLabel(_ time: Int) {
        countdownLabel.attributedText = attributedTextForm(content: timeFormatter(sec: time), size: 22, kern: 0, color: CustomColor.red ?? .red)
    }
}
