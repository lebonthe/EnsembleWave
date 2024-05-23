//
//  CustomFunc.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/26.
//

import Foundation
import UIKit

class CustomFunc {
    /// - Parameters:
    class func customAlert(title: String, message: String, vc: UIViewController, actionHandler: (() -> Void)?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let closeAction = UIAlertAction(title: "關閉", style: .default) { action in
            actionHandler?()
        }
        alertController.addAction(closeAction)
        vc.present(alertController, animated: true)
    }
}
