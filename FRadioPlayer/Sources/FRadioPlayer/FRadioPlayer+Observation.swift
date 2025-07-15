//
//  FRadioPlayer+Observation.swift
//  FRadioPlayer
//
//  Created by TuneURL.
//  Copyright © 2025 TuneURL. All rights reserved.
//

import Foundation

extension FRadioPlayer {
    struct Observation {
        weak var observer: FRadioPlayerObserver?
    }
}

public extension FRadioPlayer {
    func addObserver(_ observer: FRadioPlayerObserver) {
        let id = ObjectIdentifier(observer)
        observations[id] = Observation(observer: observer)
    }

    func removeObserver(_ observer: FRadioPlayerObserver) {
        let id = ObjectIdentifier(observer)
        observations.removeValue(forKey: id)
    }
}
