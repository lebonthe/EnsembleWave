//
//  BaseViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/12.
//

import UIKit

class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            return .portrait
        }
    
    override open var shouldAutorotate: Bool {
       return false
    }
}
