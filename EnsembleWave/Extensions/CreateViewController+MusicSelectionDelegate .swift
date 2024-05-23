//
//  CreateViewController+MusicSelectionDelegate .swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/16.
//

import UIKit
import AVKit
import MediaPlayer
extension CreateViewController: MusicSelectionDelegate {
    @IBAction func selectMusic(_ sender: Any) {
        recordingTopView.isHidden = true
        stopCountdownTimer()
        disableGestureRecognition()
        let controller = MusicViewController()
        controller.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        controller.modalPresentationStyle = .overCurrentContext
        controller.delegate = self
        present(controller, animated: true)
    }
    
    func musicViewController(_ controller: MusicViewController, didSelectMusic music: MusicType) {
        selectedMusic = music
    }
    
    func playMusic() {
        guard let selectedMusic = selectedMusic else {
            print("No music selected")
            return
        }
        
        switch selectedMusic {
        case .mp3(let url):
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer.play()
                self.audioPlayer = audioPlayer
            } catch {
                print("Failed to play music from file: \(error)")
            }
        case .appleMusic(let id):
            requestMediaLibraryAccess(id: id)
            print("Apple Music ID: \(id)")
        }
    }
    func requestMediaLibraryAccess(id: String) {
        MPMediaLibrary.requestAuthorization { status in
            if status == .authorized {
                if let id = UInt64(id) {
                    self.fetchMediaItem(usingPersistentID: id)
                }
                
            } else {
                print("Access denied by the user")
            }
        }
    }
    func fetchMediaItem(usingPersistentID persistentID: UInt64) {
        let query = MPMediaQuery()
        let predicate = MPMediaPropertyPredicate(value: persistentID, forProperty: MPMediaItemPropertyPersistentID)
        query.addFilterPredicate(predicate)
        
        if let items = query.items, let item = items.first {
            let collection = MPMediaItemCollection(items: [item])
            playMediaItemCollection(collection)
        } else {
            print("No items found")
        }
    }
    func playMediaItemCollection(_ collection: MPMediaItemCollection) {
        musicPlayer = MPMusicPlayerController.systemMusicPlayer // .applicationMusicPlayer
        musicPlayer?.setQueue(with: collection)
        musicPlayer?.play()
    }
}
