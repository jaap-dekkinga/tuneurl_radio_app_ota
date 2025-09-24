import Foundation
import Speech
import AsyncAlgorithms
import TuneURL

private let log = Log(label: "VoiceCommandManager")

@MainActor
@Observable
class VoiceCommandManager {
    
    static let shared = VoiceCommandManager()
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    
    private var recordingAudioEngine: AVAudioEngine?
    
    let recognitions = AsyncChannel<String>()
    
    private init() { }
    
    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            log.write("Speech recognition authorization status: \(status.rawValue)")
        }
    }
    
    func startRecognition() {
#if targetEnvironment(simulator)
        return
#endif
        
        guard SettingsStore.shared.voiceCommands else {
            log.write("Voice commands disabled in settings", level: .info)
            return
        }
        
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            log.write("Speech recognition not authorized", level: .warning)
            return
        }
        
        guard speechRecognizer == nil, recognitionTask == nil else {
            log.write("Already listening", level: .warning)
            return
        }
        
        // setup the speech recognizer
        guard let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
            log.write("Error creating speech recognizer", level: .warning)
            return
        }
        guard speechRecognizer.isAvailable else {
            log.write("Speech recognizer not available", level: .warning)
            return
        }
        self.speechRecognizer = speechRecognizer
        
        // setup the speech recognition request
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true
        self.recognitionRequest = recognitionRequest
    
        // setup the speech recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let error {
                log.write("Speech recognition error: \(error.localizedDescription)", level: .error)
                self?.stopRecognition()
                return
            }
            
            guard let result else { return }
            log.write("Speech recognition result: \(result.bestTranscription.formattedString)")
            self?.handleRecognitionResult(result.bestTranscription.formattedString)
            
            if result.isFinal {
                self?.stopRecognition()
            }
        }
        
        // start receiving audio buffers
        if StateManager.shared.isListening {
            StateManager.shared.listeningBuffer { buffer in
                self.recognitionRequest?.append(buffer)
            }
        } else {
            startRecordingSpeech()
        }
    }
    
    func stopRecognition() {
        // stop receiving audio buffers
        StateManager.shared.listeningBuffer(nil)
        
        // stop recording speech if we were recording
        stopRecordingSpeech()
        
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        speechRecognizer = nil
    }
    
    // MARK: - Private funcs
    private func handleRecognitionResult(_ text: String) {
        Task {
            await recognitions.send(text)
        }
    }
    
    // MARK: - Recording speech when radio playing
    private func startRecordingSpeech() {
        do {
            let audioEngine = AVAudioEngine()
            // Configure the audio session for recording and playback.
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            
            // Configure the microphone.
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            // The buffer size tells us how much data should the microphone record before dumping it into the recognition request.
            guard recordingFormat.sampleRate > 0 else {
                log.write("Invalid recording format sample rate", level: .error)
                return
            }
            
            inputNode.installTap(
                onBus: 0,
                bufferSize: 1024,
                format: recordingFormat
            ) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            recordingAudioEngine = audioEngine
        } catch {
            log.write("Failed to start recording speech: \(error)", level: .error)
        }
    }
    
    private func stopRecordingSpeech() {
        recordingAudioEngine?.stop()
        recordingAudioEngine?.inputNode.removeTap(onBus: 0)
        recordingAudioEngine = nil
        
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: []
            )
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.1)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            log.write("Failed to reset audio session stop recording speech: \(error)", level: .error)
        }
    }
}
