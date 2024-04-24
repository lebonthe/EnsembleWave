//
//  ViewController+Extension.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/23.
//

import UIKit
//
//extension UIViewController {
//    public func dchCheckDeallocation(afterDelay delay: TimeInterval = 2.0) {
//        let rootParentViewController = dchRootParentViewController
//
//        // We don’t check `isBeingDismissed` simply on this view controller because it’s common
//        // to wrap a view controller in another view controller (e.g. in UINavigationController)
//        // and present the wrapping view controller instead.
//        if isMovingFromParent || rootParentViewController.isBeingDismissed {
//            let type = type(of: self)
//            let disappearanceSource: String = isMovingFromParent ? "removed from its parent" : "dismissed"
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: { [weak self] in
//                assert(self == nil, "\(type) not deallocated after being \(disappearanceSource)")
//            })
//        }
//    }
//
//    private var dchRootParentViewController: UIViewController {
//        var root = self
//
//        while let parent = root.parent {
//            root = parent
//        }
//
//        return root
//    }
//}
