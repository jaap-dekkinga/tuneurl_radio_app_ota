//
//  FRadioPlayer+Metadata.swift
//  FRadioPlayer
//
//  Created by TuneURL.
//  Copyright © 2025 TuneURL. All rights reserved.
//

import AVFoundation

public extension FRadioPlayer {
    struct Metadata {
        public let artistName: String?
        public let trackName: String?
        public let rawValue: String?
        public let groups: [AVTimedMetadataGroup]
                
        public var isEmpty: Bool {
            (artistName == nil) && (trackName == nil)
        }
        
        public init(artistName: String?, trackName: String?, rawValue: String?, groups: [AVTimedMetadataGroup]) {            
            self.artistName = artistName
            self.trackName = trackName
            self.rawValue = rawValue
            self.groups = groups
        }
    }
}
