//
//  FRadioMetadataExtractor.swift
//  FRadioPlayer
//
//  Created by TuneURL.
//  Copyright © 2025 TuneURL. All rights reserved.
//

import AVFoundation

public protocol FRadioMetadataExtractor {
    func extract(from groups: [AVTimedMetadataGroup]) -> FRadioPlayer.Metadata?
}

// Default implementation
struct DefaultMetadataExtractor: FRadioMetadataExtractor {
    func extract(from groups: [AVTimedMetadataGroup]) async -> FRadioPlayer.Metadata? {
        guard let firstGroup = groups.first,
              let firstItem = firstGroup.items.first else {
            return nil
        }

        // Modern async API for iOS 16+
        let rawValue: String?
        if #available(iOS 16.0, *) {
            do {
                rawValue = try await firstItem.load(.stringValue)
            } catch {
                print("Failed to load stringValue: \(error)")
                rawValue = nil
            }
        } else {
            rawValue = firstItem.stringValue
        }

        let rawValueCleaned = cleanRawMetadataIfNeeded(rawValue)
        let parts = rawValueCleaned?.components(separatedBy: " - ")

        return FRadioPlayer.Metadata(
            artistName: parts?.first,
            trackName: parts?.last,
            rawValue: rawValueCleaned,
            groups: groups
        )
    }

    private func cleanRawMetadataIfNeeded(_ rawValue: String?) -> String? {
        guard let rawValue = rawValue else { return nil }

        let pattern = #"(\(.*?\)\w*)|(\[.*?\]\w*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return rawValue }

        let rawCleaned = NSMutableString(string: rawValue)
        regex.replaceMatches(
            in: rawCleaned,
            options: [],
            range: NSRange(location: 0, length: rawCleaned.length),
            withTemplate: ""
        )
        return rawCleaned as String
    }
}
