//
//  FRadioMetadataExtractor.swift
//  FRadioPlayer
//
//  Created by TuneURL.
//  Copyright © 2025 TuneURL. All rights reserved.
//

import AVFoundation

public protocol FRadioMetadataExtractor {
    /// Async because `AVMetadataItem` values are loaded with `load(.value)` since iOS 16.
    /// An existing synchronous implementation still conforms.
    func extract(from groups: [AVTimedMetadataGroup]) async -> FRadioPlayer.Metadata?
}

// Default implementation
struct DefaultMetadataExtractor: FRadioMetadataExtractor {
    func extract(from groups: [AVTimedMetadataGroup]) async -> FRadioPlayer.Metadata? {
        guard !groups.isEmpty else { return nil }
        
        var rawValue: String?
        if let item = groups.first?.items.first {
            rawValue = (try? await item.load(.value)) as? String
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
