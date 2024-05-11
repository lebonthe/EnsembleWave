//
//  AnimationManager.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/10.
//

import UIKit
import Lottie
class AnimationManager {
    static let shared = AnimationManager()
    private init() {}

    func playAnimation(view: UIView, animationName: String, loopMode: LottieLoopMode = .playOnce) -> LottieAnimationView {
        let animView = LottieAnimationView(name: animationName)
        animView.frame = view.bounds
        animView.loopMode = loopMode
        animView.contentMode = .scaleAspectFit
        view.addSubview(animView)
        animView.play()
        return animView
    }

    func stopAnimation(animView: LottieAnimationView) {
        animView.stop()
        animView.removeFromSuperview()
    }
}

