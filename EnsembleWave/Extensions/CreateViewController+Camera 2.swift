//
//  CreateViewController+Camera.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/16.
//

import UIKit
import AVFoundation

extension CreateViewController {
    @objc func toggleCameraPosition(_ sender: UIBarButtonItem) {
        guard !recSettings.isRecording else {
            print("錄製中，無法切換鏡頭")
            return
        }
        print("切換鏡頭")
        if cameraViewModel.isFrontCamera == true {
            cameraViewModel.isFrontCamera = false
        } else {
            cameraViewModel.isFrontCamera = true
        }
        print("isFrontCamera? \(cameraViewModel.isFrontCamera)")
    }
}
