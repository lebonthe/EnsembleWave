//
//  NavigationController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/12.
//

import UIKit

class NavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        topViewController?.supportedInterfaceOrientations ?? .portrait
        }
    
    override var shouldAutorotate: Bool {
            return topViewController?.shouldAutorotate ?? false
        }
}
