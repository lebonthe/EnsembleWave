//
//  ChooseStyleViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/9.
//

import UIKit

class ChooseStyleViewController: UIViewController {

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tabBarController?.tabBar.isHidden = true
    }
    

//     MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Style00" {
            if let destinationTVC = segue.destination as? ChooseLengthTableViewController {
                destinationTVC.style = 0
            }
        }
    }
 

}
