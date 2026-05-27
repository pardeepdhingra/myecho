import AVFoundation
import Foundation

@MainActor
final class SpeechService: ObservableObject {
    struct VoiceOption: Identifiable, Equatable {
        let id: String
        let name: String
        let language: String
        let quality: AVSpeechSynthesisVoiceQuality

        var displayName: String {
            if language.isEmpty {
                return name
            }
            return "\(name) · \(language)"
        }
    }

    private let synthesizer = AVSpeechSynthesizer()

    var voiceOptions: [VoiceOption] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { first, second in
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

    func speak(_ text: String, settings: AACSettings) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

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
        AVSpeechSynthesisVoice(language: "en-AU")
            ?? AVSpeechSynthesisVoice(language: "en-US")
            ?? AVSpeechSynthesisVoice(language: "en-GB")
    }
}
