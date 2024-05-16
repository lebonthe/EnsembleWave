//
//  AVAsset+Extension.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/16.
//
import AVFoundation

extension AVAsset {
    func assetByTrimming(startTime: CMTime, endTime: CMTime) -> AVAssetExportSession {
        let exportSession = AVAssetExportSession(asset: self, presetName: AVAssetExportPresetHighestQuality)!
        exportSession.timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
        return exportSession
    }
}
