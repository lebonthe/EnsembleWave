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

        self.delegate = self
    }
    func presentLoginViewController() {
        let loginViewController = LoginViewController()
        present(loginViewController, animated: true)
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
        return true
    }
}
