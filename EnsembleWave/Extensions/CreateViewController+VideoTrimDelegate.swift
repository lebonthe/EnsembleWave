//
//  CreateViewController+VideoTrimDelegate.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/16.
//

import AVFoundation
import UIKit
import VideoTrim
extension CreateViewController: VideoTrimDelegate {
    func videoTrimStartTrimChange(_ view: VideoTrim) {
        recSettings.isPlaying = false
        self.stopAllVideos()
    }
    
    func videoTrimEndTrimChange(_ view: VideoTrim) {
        let startTime = view.startTime
        let endTime = view.endTime
        updatePlayerRange(for: players[recSettings.currentRecordingIndex], withStartTime: startTime, endTime: endTime)
    }
    
    private func updateTrimTime() {
        for (index, player) in players.enumerated() {
            if let currentItem = player.currentItem {
                let startTime = trimView.videoTrim.startTime
                let endTime = trimView.videoTrim.endTime
                let timeRange = CMTimeRange(start: startTime, end: endTime)
                currentItem.seek(to: startTime, completionHandler: nil)
                print("更新第 \(index) 個播放器的播放範圍為 \(timeRange)")
            }
        }
    }
    
    func updatePlayerRange(for player: AVPlayer, withStartTime startTime: CMTime, endTime: CMTime) {
        guard let currentItem = player.currentItem else {
            return
        }
        let asset = currentItem.asset
        
        let duration = CMTimeSubtract(endTime, startTime)
        if CMTimeCompare(duration, .zero) <= 0 {
            print("結束時間必須大於開始時間")
            return
        }
        //        let newRange = CMTimeRange(start: startTime, duration: duration)
        let newPlayerItem = AVPlayerItem(asset: asset)
        newPlayerItem.forwardPlaybackEndTime = endTime
        player.replaceCurrentItem(with: newPlayerItem)
        player.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            player.play()
        }
    }
    
    func videoTrimPlayTimeChange(_ view: VideoTrim) {
        let newTime = CMTime(value: CMTimeValue(view.playTime.value + view.startTime.value), timescale: view.playTime.timescale)
        let player = players[recSettings.currentRecordingIndex]
        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func setupEndTimeObserver(for player: AVPlayer, startTime: CMTime, endTime: CMTime) {
        if let observer = endTimeObservers[player] {
            player.removeTimeObserver(observer)
            endTimeObservers[player] = nil
        }
        
        let observer = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .global()) { [weak self] time in
            if time >= endTime {
                DispatchQueue.main.async {
                    self?.stopAllVideos()
                    player.seek(to: startTime)
                }
            }
        }
        endTimeObservers[player] = observer
    }
}
