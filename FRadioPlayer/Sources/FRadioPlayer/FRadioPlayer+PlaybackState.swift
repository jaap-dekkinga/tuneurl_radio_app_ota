//
//  FRadioPlaybackState.swift
//  FRadioPlayer
//
//  Created by TuneURL.
//  Copyright © 2025 TuneURL. All rights reserved.
//

import Foundation


public extension FRadioPlayer {
    
    /**
     `FRadioPlayingState` is the Player playing state enum
     */
    enum PlaybackState: Int {
        
        /// Player is playing
        case playing
        
        /// Player is paused
        case paused
        
        /// Player is stopped
        case stopped
        
        /// Return a readable description
        public var description: String {
            switch self {
            case .playing: return "Player is playing"
            case .paused: return "Player is paused"
            case .stopped: return "Player is stopped"
            }
        }
    }
}
