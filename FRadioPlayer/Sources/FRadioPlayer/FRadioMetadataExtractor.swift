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
    func extract(from groups: [AVTimedMetadataGroup]) -> FRadioPlayer.Metadata? {
        guard !groups.isEmpty else { return nil }
        
        // Modern async API for iOS 16+
        let rawValue: String?
        if #available(iOS 16.0, *) {
            do {
                rawValue = try await firstItem.load(.value)
            } catch {
                print("Failed to load value: \(error)")
                rawValue = nil
            }
        } else {
            rawValue = firstItem.stringValue
        }

        let rawValueCleaned = cleanRawMetadataIfNeeded(rawValue)
        let parts = rawValueCleaned?.components(separatedBy: " - ")
        
        return FRadioPlayer.Metadata(artistName: parts?.first, trackName: parts?.last, rawValue: rawValueCleaned, groups: groups)
    }
    
    private func cleanRawMetadataIfNeeded(_ rawValue: String?) -> String? {
        guard let rawValue = rawValue else { return nil }
        // Strip off trailing '[???]' characters left there by ShoutCast and Centova Streams
        // It will leave the string alone if the pattern is not there
        
        let pattern = #"(\(.*?\)\w*)|(\[.*?\]\w*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return rawValue }
        
        let rawCleaned = NSMutableString(string: rawValue)
        regex.replaceMatches(in: rawCleaned , options: .reportProgress, range: NSRange(location: 0, length: rawCleaned.length), withTemplate: "")
        
        return rawCleaned as String
    }
}
