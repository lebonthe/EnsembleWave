//
//  TimeFormatter.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/16.
//

import UIKit
class TimeFormatter {
    static func format(seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        let second: TimeInterval = Double(seconds)
        guard let remainingTime = formatter.string(from: second) else {
            fatalError("時間轉換失敗")
        }
        print("remainingTime: \(remainingTime)")
        return "- \(remainingTime)"
    }
}
