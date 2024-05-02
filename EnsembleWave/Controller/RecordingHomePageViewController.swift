//
//  RecordingHomePageViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/9.
//

import UIKit

class RecordingHomePageViewController: UIViewController {

    @IBOutlet weak var newRecordButton: CustomButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    func setupUI() {
        view.backgroundColor = CustomColor.mattBlack
        newRecordButton.tintColor = CustomColor.red
        
    }
}
