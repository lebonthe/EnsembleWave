//
//  TrimView.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/13.
//

import UIKit
import AVFoundation
import VideoTrim
class TrimView: UIView {
    
    private var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let trimContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
    
    var videoTrim: VideoTrim = {
        let videoTrim = VideoTrim()
        videoTrim.translatesAutoresizingMaskIntoConstraints = false
        videoTrim.topMargin = 4
        videoTrim.bottomMargin = 8
        return videoTrim
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        setupUI()
    }
    
    private func setupUI() {
        self.backgroundColor = CustomColor.red
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(scrollView)
        scrollView.addSubview(trimContainerView)
        trimContainerView.addSubview(videoTrim)
        videoTrim.backgroundColor = .black
        scrollView.backgroundColor = .blue
        applyConstraints()
    }
    
    private func applyConstraints() {
        self.addConstraints([
            NSLayoutConstraint(item: scrollView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scrollView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scrollView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scrollView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        ])
        let containerViewHeightConstraint = NSLayoutConstraint(item: self.trimContainerView, attribute: .height, relatedBy: .equal, toItem: scrollView, attribute: .height, multiplier: 1, constant: 0)
        containerViewHeightConstraint.priority = UILayoutPriority(rawValue: 1)
        scrollView.addConstraints([
            NSLayoutConstraint(item: self.trimContainerView, attribute: .leading, relatedBy: .equal, toItem: scrollView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimContainerView, attribute: .trailing, relatedBy: .equal, toItem: scrollView, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimContainerView, attribute: .top, relatedBy: .equal, toItem: scrollView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimContainerView, attribute: .bottom, relatedBy: .equal, toItem: scrollView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimContainerView, attribute: .width, relatedBy: .equal, toItem: scrollView, attribute: .width, multiplier: 1, constant: 0),
            containerViewHeightConstraint
        ])
        self.trimContainerView.addConstraints([
            NSLayoutConstraint(item: self.videoTrim, attribute: .top, relatedBy: .equal, toItem: self.trimContainerView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.videoTrim, attribute: .leading, relatedBy: .equal, toItem: self.trimContainerView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.videoTrim, attribute: .trailing, relatedBy: .equal, toItem: self.trimContainerView, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.videoTrim, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100)
        ])
    }
    
    func configure(with asset: AVAsset) {
        DispatchQueue.main.async {
            self.videoTrim.asset = asset
        }
    }
}
