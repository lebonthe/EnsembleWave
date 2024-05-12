//
//  TabBarController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/26.

import UIKit
import FirebaseAuth
class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.selectedIndex = 0
        self.delegate = self
    }
    func presentLoginViewController() {
        let loginViewController = LoginViewController()
        present(loginViewController, animated: true)
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let selectedViewController = selectedViewController {
            return .portrait /*selectedViewController.supportedInterfaceOrientations*/
        }
        return .portrait
    }
    override var shouldAutorotate: Bool {
        return selectedViewController?.shouldAutorotate ?? false
    }
}
extension TabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let viewControllers = tabBarController.viewControllers,
           viewController == viewControllers[2] {
            
            if Auth.auth().currentUser == nil {
                presentLoginViewController()
                return false
            } else {
                return true
            }
        }
        if let selectedVC = tabBarController.selectedViewController, selectedVC == viewController {
                if let navVC = viewController as? UINavigationController,
                   let wallVC = navVC.viewControllers.first as? WallViewController {
//                    wallVC.listenToPosts()
                    wallVC.scrollToTop()
                }
                return false
            }
        return true
    }
}
