//
//  ExportError.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/16.
//

import Foundation
enum ExportError: Error {
    case noVideoTrack
    case exportSessionCreationFailed
    case trackLoadingFailed
}
