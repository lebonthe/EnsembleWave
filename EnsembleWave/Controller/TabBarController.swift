//
//  TabBarController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/26.
//
//
//import UIKit
//
//class TabBarController: UITabBarController {
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        self.delegate = self
//    }
//}
//extension TabBarController: UITabBarControllerDelegate {
//    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
//            if let viewControllers = tabBarController.viewControllers,
//                viewController == viewControllers[2] {
//                if let token = AccessToken.current,
//                   token.isExpired == false {
//                    return true
//                }
//                let fbLoginPageViewController = FBLoginPageViewController()
//
//                // 設置透明背景
//                fbLoginPageViewController.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
//                fbLoginPageViewController.modalPresentationStyle = .overCurrentContext
//                let currentViewController = viewControllers[tabBarController.selectedIndex]
//                fbLoginPageViewController.tabBarControllerReference = self
//
//                currentViewController.present(fbLoginPageViewController, animated: false, completion: nil)
//                tabBar.isHidden = true
//                return false
//            }
//            return true
//        }
//}
