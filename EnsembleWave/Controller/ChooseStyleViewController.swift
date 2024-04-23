//
//  ChooseStyleViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/9.
//

import UIKit

class ChooseStyleViewController: UIViewController {

    @IBOutlet weak var styleView00: UIView!
    @IBOutlet weak var styleView01: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarController?.tabBar.isHidden = true
    }
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        setupUI()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupLayoutUI()
    }
    func setupUI() {
        let screenBounds = view.window?.windowScene?.screen.bounds
        print("screenBounds: \(screenBounds!)")
        styleView00.translatesAutoresizingMaskIntoConstraints = false
        styleView01.translatesAutoresizingMaskIntoConstraints = false
        styleView00.backgroundColor = .white
        styleView01.backgroundColor = .white
        let line = UIView()
        line.backgroundColor = .black
        styleView01.addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            styleView00.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
//            styleView00.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            styleView00.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            styleView00.widthAnchor.constraint(equalToConstant: (screenBounds?.width ?? 198) / 2),
            styleView00.heightAnchor.constraint(equalTo: styleView00.widthAnchor),
            styleView01.topAnchor.constraint(equalTo: styleView00.bottomAnchor, constant: 32),
//            styleView01.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            styleView01.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            styleView01.widthAnchor.constraint(equalToConstant: (screenBounds?.width ?? 198) / 2),
            styleView01.heightAnchor.constraint(equalTo: styleView01.widthAnchor),
            line.topAnchor.constraint(equalTo: styleView01.topAnchor),
            line.bottomAnchor.constraint(equalTo: styleView01.bottomAnchor),
            line.centerXAnchor.constraint(equalTo: styleView01.centerXAnchor),
            line.widthAnchor.constraint(equalToConstant: 2)
        ])
    }
    func setupLayoutUI() {
        
        styleView00.layer.borderColor = UIColor.black.cgColor
        styleView00.layer.borderWidth = 2
        styleView01.layer.borderColor = UIColor.black.cgColor
        styleView01.layer.borderWidth = 2
        
      
       
    }
//     MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Style00" {
            if let destinationTVC = segue.destination as? ChooseLengthTableViewController {
                destinationTVC.style = 0
            }
        } else if segue.identifier == "Style01" {
            if let destinationTVC = segue.destination as? ChooseLengthTableViewController {
                destinationTVC.style = 1
            }
        }
        
    }
}
