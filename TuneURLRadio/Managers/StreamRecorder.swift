import AVFoundation

final class StreamRecorder {

    private let blockDuration: TimeInterval = 10 * 60   // 10 minutes
    private let inputGainCompensation: Float

    private let queue = DispatchQueue(label: "com.tuneurl.streamrecorder")
    private var recordingFormat: AVAudioFormat?
    private var converter: AVAudioConverter?
    private var currentFile: AVAudioFile?
    private var framesWrittenInCurrentFile: AVAudioFramePosition = 0
    private var currentStationName = "stream"

    private let recordingsFolderURL: URL

    init(gainCompensation: Float = 1000.0) {
        inputGainCompensation = gainCompensation
    
        let documents: URL
        #if targetEnvironment(simulator)
        if let simulatorHome = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] {
            documents = URL(fileURLWithPath: simulatorHome).appendingPathComponent("Documents", isDirectory: true)
        } else {
            documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        }
        #else
        documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        #endif
    
        recordingsFolderURL = documents.appendingPathComponent("streaming_recording", isDirectory: true)
        try? FileManager.default.createDirectory(at: recordingsFolderURL, withIntermediateDirectories: true)
    }

    func startNewSession(stationName: String) {
        queue.async {
            self.currentStationName = stationName.isEmpty ? "stream" : stationName
            self.closeCurrentFile()
        }
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        queue.async {
            if self.recordingFormat == nil {
                self.recordingFormat = AVAudioFormat(
                    commonFormat: .pcmFormatInt16,
                    sampleRate: buffer.format.sampleRate,
                    channels: buffer.format.channelCount,
                    interleaved: true
                )
            }
            guard let converted = self.convert(buffer) else { return }
            self.write(converted)
        }
    }

    func stopSession() {
        queue.async { self.closeCurrentFile() }
    }

    // MARK: - Private

    private func convert(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let recordingFormat else { return nil }

        if converter == nil || converter?.inputFormat != buffer.format {
            converter = AVAudioConverter(from: buffer.format, to: recordingFormat)
        }
        guard let converter else { return nil }

        // compensate for the decode-only player's 0.001 mute before quantizing to Int16
        if let floatData = buffer.floatChannelData {
            let frameCount = Int(buffer.frameLength)
            for channel in 0..<Int(buffer.format.channelCount) {
                let samples = floatData[channel]
                for i in 0..<frameCount { samples[i] *= inputGainCompensation }
            }
        }

        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat, frameCapacity: buffer.frameLength + 16) else {
            return nil
        }

        var error: NSError?
        var consumed = false
        converter.convert(to: outBuffer, error: &error) { _, outStatus in
            if consumed { outStatus.pointee = .noDataNow; return nil }
            consumed = true
            outStatus.pointee = .haveData
            return buffer
        }
        if let error {
            NSLog("StreamRecorder: conversion error \(error.localizedDescription)")
            return nil
        }
        return outBuffer.frameLength > 0 ? outBuffer : nil
    }

    private func write(_ buffer: AVAudioPCMBuffer) {
        guard let recordingFormat else { return }
        if currentFile == nil { openNewFile(format: recordingFormat) }
        guard let currentFile else { return }

        do {
            try currentFile.write(from: buffer)
            framesWrittenInCurrentFile += AVAudioFramePosition(buffer.frameLength)
            if Double(framesWrittenInCurrentFile) / recordingFormat.sampleRate >= blockDuration {
                closeCurrentFile()
            }
        } catch {
            NSLog("StreamRecorder: write error \(error.localizedDescription)")
            closeCurrentFile()
        }
    }

    private func openNewFile(format: AVAudioFormat) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "\(currentStationName)_\(formatter.string(from: Date())).wav"
        var fileURL = recordingsFolderURL.appendingPathComponent(filename)

        do {
            currentFile = try AVAudioFile(
                forWriting: fileURL,
                settings: format.settings,
                commonFormat: .pcmFormatInt16,
                interleaved: true
            )
            framesWrittenInCurrentFile = 0
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? fileURL.setResourceValues(values)
        } catch {
            NSLog("StreamRecorder: failed to open file \(error.localizedDescription)")
            currentFile = nil
        }
    }

    private func closeCurrentFile() {
        currentFile = nil   // AVAudioFile flushes on dealloc
        framesWrittenInCurrentFile = 0
    }
}
