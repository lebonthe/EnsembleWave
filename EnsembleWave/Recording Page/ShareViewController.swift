//
//  ShareViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/11.
//

import UIKit
import Photos

class ShareViewController: UIViewController {
    var url: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        if let url = url {
            self.saveVideoToAlbum(url)
        }
    }
    func saveVideoToAlbum(_ videoURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }) { saved, error in
            DispatchQueue.main.async {
                
                if saved {
                    let alertController = UIAlertController(title: "影片已儲存", message: "可到相簿查看", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default)
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true)
                    print("影片已儲存到相簿")
                } else {
                    let alertController = UIAlertController(title: "影片儲存失敗", message: "花生了什麼事？", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default)
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true)
                    print("影片儲存失敗: \(String(describing: error))")
                }
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
