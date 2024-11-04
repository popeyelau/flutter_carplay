//
//  FCPSpeechRecognizer.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 09/14/2021.
//

import AVFoundation
import Speech
import SwiftUI

/// A structure handling speech recognition functionality in the Flutter CarPlay plugin.
struct FCPSpeechRecognizer {
    /// A nested class responsible for managing the speech transcript.
    private class FCPSpeechTranscript {
        var transcript = ""

        func set(newValue: String) {
            SwiftFlutterCarplayPlugin.sendSpeechRecognitionTranscriptChangeEvent(transcript: newValue)
            transcript = newValue
        }

        func get() -> String {
            return transcript
        }
    }

    /// A nested class assisting in speech recognition tasks.
    private class FCPSpeechAssist {
        var audioEngine: AVAudioEngine?
        var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
        var recognitionTask: SFSpeechRecognitionTask?
        var speechRecognizer = SFSpeechRecognizer()

        /// Deinitializes the speech assist class and resets recognition components.
        deinit {
            reset()
        }

        /// Resets the speech recognition components.
        func reset() {
            recognitionTask?.cancel()
            audioEngine?.stop()
            audioEngine = nil
            recognitionRequest = nil
            recognitionTask = nil
        }

        /// Sets the locale for the speech recognizer.
        ///
        /// - Parameter locale: The locale identifier.
        func setLocale(locale: String?) {
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale ?? "zh-CN"))
        }
    }

    /// An instance of FCPSpeechTranscript managing the speech transcript.
    private let transcript = FCPSpeechTranscript()

    /// An instance of FCPSpeechAssist assisting in speech recognition tasks.
    private let assistant = FCPSpeechAssist()

    /// Initiates the speech recognition process.
    ///
    /// - Parameter locale: The locale identifier.
    func record(locale: String?) {

        assistant.setLocale(locale: locale)

        canAccess { authorized in
            guard authorized else {
                debugPrint("[FlutterCarPlay]: Access denied.")
                return
            }

            assistant.audioEngine = AVAudioEngine()
            guard let audioEngine = assistant.audioEngine else {
                fatalError("[FlutterCarPlay]: Unable to create audio engine.")
            }
            assistant.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = assistant.recognitionRequest else {
                fatalError("[FlutterCarPlay]: Unable to create recognition request.")
            }
            recognitionRequest.shouldReportPartialResults = true

            do {

                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                let inputNode = audioEngine.inputNode
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, _: AVAudioTime) in
                    recognitionRequest.append(buffer)
                }
                audioEngine.prepare()
                try audioEngine.start()
                assistant.recognitionTask = assistant.speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                    var isFinal = false
                    if let result = result {
                        relay(message: result.bestTranscription.formattedString)
                        isFinal = result.isFinal
                    }

                    if error != nil || isFinal {
                        audioEngine.stop()
                        inputNode.removeTap(onBus: 0)
                        self.assistant.recognitionRequest = nil
                    }
                }
            } catch {
                assistant.reset()
            }
        }
    }

    /// Stops the ongoing speech recognition.
    func stopRecording() {
        assistant.reset()
    }

    /// Checks if the app has access to speech recognition and audio recording.
    ///
    /// - Parameter handler: A closure indicating whether access is granted.
    private func canAccess(withHandler handler: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            if status == .authorized {
                AVAudioSession.sharedInstance().requestRecordPermission { authorized in
                    handler(authorized)
                }
            } else {
                handler(false)
            }
        }
    }

    /// Relays the speech recognition result to the transcript.
    ///
    /// - Parameter message: The recognized speech message.
    private func relay(message: String) {
        DispatchQueue.main.async {
            transcript.set(newValue: message)
        }
    }
}
