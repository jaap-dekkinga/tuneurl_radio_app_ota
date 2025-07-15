//
//  FRadioArtworkAPI.swift
//  FRadioPlayer
//
//  Created by TuneURL.
//  Copyright © 2025 TuneURL. All rights reserved.
//

import Foundation

public protocol FRadioArtworkAPI {
    func getArtwork(for metadata: FRadioPlayer.Metadata, _ completion: @escaping (_ artworkURL: URL?) -> Void)
}
