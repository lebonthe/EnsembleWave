//
//  PlayManager.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/5.
//

import Foundation
import AVFoundation

protocol PlayerManagerDelegate: AnyObject {
    func playerDidPause()
    
    func playerDidPlay()
}
class PlayerManager {
    static let shared = PlayerManager()
    private var players: [AVPlayer] = []
    private var delegates: [AVPlayer: PlayerManagerDelegate] = [:]
    
    func registerPlayer(_ player: AVPlayer, delegate: PlayerManagerDelegate) {
        if !players.contains(where: { $0 === player }) {
            players.append(player)
        }
        delegates[player] = delegate
    }

    func unregisterPlayer(_ player: AVPlayer) {
        players.removeAll { $0 === player }
    }

    func play(player: AVPlayer) {
        for somePlayer in players where somePlayer != player {
            somePlayer.pause()
            delegates[somePlayer]?.playerDidPause()
        }
        player.play()
        delegates[player]?.playerDidPlay()
    }
}
