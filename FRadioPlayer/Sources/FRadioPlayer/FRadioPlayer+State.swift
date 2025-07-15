//
//  FRadioPlayerState.swift
//  FRadioPlayer
//
//  Created by TuneURL.
//  Copyright © 2025 TuneURL. All rights reserved.
//

import Foundation


public extension FRadioPlayer {
    
    /**
     `State` is the Player status enum
     */
    enum State: Int {
       
       /// URL not set
       case urlNotSet
       
       /// Player is ready to play
       case readyToPlay
       
       /// Player is loading
       case loading
       
       /// The loading has finished
       case loadingFinished
       
       /// Error with playing
       case error
       
       /// Return a readable description
       public var description: String {
           switch self {
           case .urlNotSet: return "URL is not set"
           case .readyToPlay: return "Ready to play"
           case .loading: return "Loading"
           case .loadingFinished: return "Loading finished"
           case .error: return "Error"
           }
       }
   }
}
