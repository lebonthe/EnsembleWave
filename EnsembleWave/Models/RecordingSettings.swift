//
//  RecordingSettings.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/16.
//

import Foundation
struct RecordingSettings {
    var style: Int = 0
    var length: Int = 15
    var currentRecordingIndex: Int = 0
    var isRecording: Bool = false
    var isPlaying: Bool = false
    
    mutating func reset() {
        self.currentRecordingIndex = 0
        self.isRecording = false
        self.isPlaying = false
    }
}
