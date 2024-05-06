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
//        checkFonts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    func setupUI() {
        view.backgroundColor = CustomColor.mattBlack
        newRecordButton.tintColor = CustomColor.red
        newRecordButton.setAttributedTitle(attributedTextForm(content: "New Record", size: 18, kern: 0, color: UIColor.white), for: .normal)
    }
//    func checkFonts() {
//        
//        for family in UIFont.familyNames {
//            print("\(family)")
//            for name in UIFont.fontNames(forFamilyName: family) {
//                print("== \(name)")
//            }
//        }
//
//    }
}
