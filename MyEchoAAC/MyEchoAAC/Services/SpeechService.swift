import AVFoundation
import Foundation
import os

@MainActor
final class SpeechService: ObservableObject {
    struct VoiceOption: Identifiable, Equatable {
        let id: String
        let name: String
        let language: String
        let quality: AVSpeechSynthesisVoiceQuality

        var displayName: String {
            let qualityBadge: String
            switch quality {
            case .premium: qualityBadge = " · Premium"
            case .enhanced: qualityBadge = " · Enhanced"
            default: qualityBadge = ""
            }
            if language.isEmpty {
                return name + qualityBadge
            }
            return "\(name) · \(language)" + qualityBadge
        }
    }

    private let synthesizer = AVSpeechSynthesizer()
    private let logger = Logger(subsystem: "com.pardeepdhingra.vani", category: "SpeechService")

    init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers]
            )
            try session.setActive(true, options: [])
        } catch {
            logger.error("Failed to configure audio session: \(error.localizedDescription, privacy: .public)")
        }
    }

    var voiceOptions: [VoiceOption] {
        voiceOptions(includeCompact: false)
    }

    func voiceOptions(includeCompact: Bool) -> [VoiceOption] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { includeCompact || $0.quality != .default }
            .sorted { first, second in
                if first.quality.rawValue != second.quality.rawValue {
                    return first.quality.rawValue > second.quality.rawValue
                }
                if first.language == second.language {
                    return first.name < second.name
                }
                return first.language < second.language
            }
            .map {
                VoiceOption(
                    id: $0.identifier,
                    name: $0.name,
                    language: $0.language,
                    quality: $0.quality
                )
            }
    }

    var hasAnyEnhancedOrPremiumVoice: Bool {
        AVSpeechSynthesisVoice.speechVoices().contains { $0.quality != .default }
    }

    func speak(_ text: String, settings: AACSettings) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        speakSystem(trimmed, settings: settings)
    }

    private func speakSystem(_ trimmed: String, settings: AACSettings) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.rate = settings.speechRate
        utterance.pitchMultiplier = settings.pitchMultiplier
        utterance.volume = 1.0

        if let voiceIdentifier = settings.voiceIdentifier {
            utterance.voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier)
        } else {
            utterance.voice = preferredDefaultVoice()
        }

        synthesizer.speak(utterance)
    }

    func previewVoice(settings: AACSettings) {
        speak("I am ready to talk.", settings: settings)
    }

    private func preferredDefaultVoice() -> AVSpeechSynthesisVoice? {
        let preferredLanguages = ["en-AU", "en-US", "en-GB"]
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        for language in preferredLanguages {
            let inLanguage = allVoices.filter { $0.language == language }
            if let premium = inLanguage.first(where: { $0.quality == .premium }) {
                return premium
            }
            if let enhanced = inLanguage.first(where: { $0.quality == .enhanced }) {
                return enhanced
            }
        }
        if let anyPremium = allVoices.first(where: { $0.language.hasPrefix("en") && $0.quality == .premium }) {
            return anyPremium
        }
        if let anyEnhanced = allVoices.first(where: { $0.language.hasPrefix("en") && $0.quality == .enhanced }) {
            return anyEnhanced
        }
        return AVSpeechSynthesisVoice(language: "en-AU")
            ?? AVSpeechSynthesisVoice(language: "en-US")
            ?? AVSpeechSynthesisVoice(language: "en-GB")
    }
}
