//
//  CreateViewController+Audio.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/16.
//

import AVFoundation
import MediaPlayer

extension CreateViewController {
    func bookEarphoneState() {
        headphoneAlertLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headphoneAlertLabel.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 20),
            headphoneAlertLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            headphoneAlertLabel.heightAnchor.constraint(equalToConstant: 80),
            headphoneAlertLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor)
        ])
        let route = AVAudioSession.sharedInstance().currentRoute
        for output in route.outputs {
            if output.portType == .headphones || output.portType == .bluetoothA2DP || output.portType == .airPlay || output.portType == .usbAudio || output.portType == .HDMI {
                headphoneAlertLabel.isHidden = true
                isHeadphoneConnected = true
                if previousVolume == 0 {
                    previousVolume = 0.5
                    MPVolumeView.setVolume(previousVolume)
                }
                break
            } else {
                isHeadphoneConnected = false
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    @objc func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        switch reason {
        case .newDeviceAvailable:
            let session = AVAudioSession.sharedInstance()
            let currentRoute = session.currentRoute
            for output in currentRoute.outputs {
                if output.portType == .headphones {
                    print("耳機已連接：\(output.portType.rawValue)")
                } else if output.portType == .bluetoothA2DP {
                    print("藍牙耳機已連接：\(output.portType.rawValue)")
                } else if output.portType == .airPlay {
                    print("AirPlay 已連接：\(output.portType.rawValue)")
                } else if output.portType == .usbAudio {
                    print("USB 已連接：\(output.portType.rawValue)")
                } else if output.portType == .HDMI {
                    print("HDMI 已連接：\(output.portType.rawValue)")
                }
            }
            headphoneAlertLabel.isHidden = true
            isHeadphoneConnected = true
        case .oldDeviceUnavailable:
            if let previousRoute = userInfo[AVAudioSessionRouteChangeReasonKey] as? AVAudioSessionRouteDescription {
                let wasUsingHeadPhones = previousRoute.outputs.contains {
                    $0.portType == .headphones
                }
                let wasUsingBlueToothEarPhones = previousRoute.outputs.contains {
                    $0.portType == .bluetoothA2DP
                }
                if wasUsingHeadPhones || wasUsingBlueToothEarPhones {
                    print("耳機已移除")
                    isHeadphoneConnected = false
                    headphoneAlertLabel.isHidden = false
                }
            }
            print("無耳機")
            headphoneAlertLabel.isHidden = false
            isHeadphoneConnected = false
            if recSettings.isRecording {
                adjustVolume(isHeadphonesConnected: false)
            }
        default: break
        }
    }
    // 在錄音狀態改變系統音量
    private func adjustVolume(isHeadphonesConnected: Bool) {
        for player in players {
            if isHeadphonesConnected {
                player.volume = playerVolume
                print("Headphones connected. Restoring volume.")
            } else {
                player.volume = 0
                print("Headphones disconnected. Muting audio.")
            }
        }
    }
    func adjustVolumeForRecording() {
        if isHeadphoneConnected == false {
            previousVolume = playerVolume
            print("previousVolume:\(previousVolume)")
            MPVolumeView.setVolume(0.0)
            print("isRecording Volume:\(0.0)")
        } else {
            MPVolumeView.setVolume(previousVolume)
            print("set playerVolume:\(previousVolume)")
        }
    }
    func getCurrentSystemVolume() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
        } catch {
            print("Unable to activate audio session")
        }
        playerVolume = audioSession.outputVolume
        print("Current system volume: \(playerVolume)")
        observeVolumeChanges()
    }
}
