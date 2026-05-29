import AVFoundation
import CryptoKit
import Foundation
import os

@MainActor
final class NaturalSpeechService: NSObject, ObservableObject {
    struct ElevenVoice: Identifiable, Equatable {
        let id: String
        let name: String
        let category: String?
        let labels: [String: String]

        var displayName: String {
            if let accent = labels["accent"] {
                return "\(name) · \(accent)"
            }
            return name
        }
    }

    @Published private(set) var voices: [ElevenVoice] = ElevenVoice.curatedDefaults
    @Published private(set) var isLoadingVoices = false
    @Published private(set) var lastError: String?
    @Published private(set) var isAvailable: Bool

    private let logger = Logger(subsystem: "com.pardeepdhingra.vani", category: "NaturalSpeech")
    private var player: AVAudioPlayer?
    private let modelId = "eleven_flash_v2_5"

    override init() {
        let key = Secrets.elevenLabsAPIKey
        self.isAvailable = (key != nil && !(key?.isEmpty ?? true))
        super.init()
    }

    func refreshAvailability() {
        let key = Secrets.elevenLabsAPIKey
        isAvailable = (key != nil && !(key?.isEmpty ?? true))
    }

    func loadVoices() async {
        refreshAvailability()
        guard let key = Secrets.elevenLabsAPIKey, !key.isEmpty else { return }
        guard !isLoadingVoices else { return }
        isLoadingVoices = true
        defer { isLoadingVoices = false }

        var request = URLRequest(url: URL(string: "https://api.elevenlabs.io/v1/voices")!)
        request.setValue(key, forHTTPHeaderField: "xi-api-key")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                lastError = "ElevenLabs voices error: \((response as? HTTPURLResponse)?.statusCode ?? -1)"
                return
            }
            struct VoiceList: Decodable { let voices: [VoicePayload] }
            struct VoicePayload: Decodable {
                let voice_id: String
                let name: String
                let category: String?
                let labels: [String: String]?
            }
            let parsed = try JSONDecoder().decode(VoiceList.self, from: data)
            let fetched = parsed.voices.map {
                ElevenVoice(id: $0.voice_id, name: $0.name, category: $0.category, labels: $0.labels ?? [:])
            }
            if !fetched.isEmpty {
                voices = fetched
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            logger.error("Voices fetch failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func speak(_ text: String, voiceId: String) async -> Bool {
        guard let key = Secrets.elevenLabsAPIKey, !key.isEmpty else { return false }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        if let cached = cachedAudio(for: trimmed, voiceId: voiceId) {
            return play(data: cached)
        }

        guard let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)?output_format=mp3_44100_64") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "xi-api-key")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "text": trimmed,
            "model_id": modelId,
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75,
                "style": 0.0,
                "use_speaker_boost": true
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                let detail = parseErrorDetail(from: data)
                lastError = friendlyMessage(status: status, detail: detail)
                logger.error("TTS failed: status \(status, privacy: .public) detail \(detail ?? "<none>", privacy: .public)")
                return false
            }
            cacheAudio(data: data, for: trimmed, voiceId: voiceId)
            return play(data: data)
        } catch {
            lastError = error.localizedDescription
            logger.error("TTS request failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func parseErrorDetail(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return String(data: data, encoding: .utf8)
        }
        if let detail = object["detail"] as? [String: Any] {
            let status = detail["status"] as? String ?? ""
            let message = detail["message"] as? String ?? ""
            return [status, message].filter { !$0.isEmpty }.joined(separator: ": ")
        }
        if let detail = object["detail"] as? String {
            return detail
        }
        return nil
    }

    private func friendlyMessage(status: Int, detail: String?) -> String {
        switch status {
        case 401:
            return "Key rejected (401). Check the API key in Parent → Voice → ElevenLabs API key. \(detail ?? "")"
        case 402:
            return "Free tier can't use this voice (402). Open elevenlabs.io → Voice Library → Add the voice to your account, then paste its Voice ID here. Library voices require a paid plan to use via API. \(detail ?? "")"
        case 403:
            return "Key missing permission (403). Enable text_to_speech in the ElevenLabs dashboard. \(detail ?? "")"
        case 422:
            return "Bad request (422). \(detail ?? "")"
        case 429:
            return "Quota exceeded or rate-limited (429). \(detail ?? "")"
        default:
            return "ElevenLabs status \(status). \(detail ?? "")"
        }
    }

    private func play(data: Data) -> Bool {
        do {
            player = try AVAudioPlayer(data: data)
            player?.prepareToPlay()
            player?.play()
            return true
        } catch {
            lastError = error.localizedDescription
            logger.error("Audio playback failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    // MARK: - Cache

    private var cacheDir: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = base.appendingPathComponent("voice-cache", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    private func cacheKey(for text: String, voiceId: String) -> String {
        let raw = "\(voiceId)::\(text)"
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.map { String(format: "%02x", $0) }.joined() + ".mp3"
    }

    private func cachedAudio(for text: String, voiceId: String) -> Data? {
        let url = cacheDir.appendingPathComponent(cacheKey(for: text, voiceId: voiceId))
        return try? Data(contentsOf: url)
    }

    private func cacheAudio(data: Data, for text: String, voiceId: String) {
        let url = cacheDir.appendingPathComponent(cacheKey(for: text, voiceId: voiceId))
        try? data.write(to: url, options: .atomic)
    }

    func clearCache() {
        try? FileManager.default.removeItem(at: cacheDir)
    }
}

extension NaturalSpeechService.ElevenVoice {
    static let curatedDefaults: [NaturalSpeechService.ElevenVoice] = [
        .init(id: "EXAVITQu4vr4xnSDxMaL", name: "Bella", category: "premade", labels: ["accent": "American", "gender": "female"]),
        .init(id: "21m00Tcm4TlvDq8ikWAM", name: "Rachel", category: "premade", labels: ["accent": "American", "gender": "female"]),
        .init(id: "AZnzlk1XvdvUeBnXmlld", name: "Domi", category: "premade", labels: ["accent": "American", "gender": "female"]),
        .init(id: "MF3mGyEYCl7XYWbV9V6O", name: "Elli", category: "premade", labels: ["accent": "American", "gender": "female"]),
        .init(id: "TxGEqnHWrfWFTfGW9XjX", name: "Josh", category: "premade", labels: ["accent": "American", "gender": "male"]),
        .init(id: "VR6AewLTigWG4xSOukaG", name: "Arnold", category: "premade", labels: ["accent": "American", "gender": "male"]),
        .init(id: "pNInz6obpgDQGcFmaJgB", name: "Adam", category: "premade", labels: ["accent": "American", "gender": "male"]),
        .init(id: "yoZ06aMxZJJ28mfd3POQ", name: "Sam", category: "premade", labels: ["accent": "American", "gender": "male"]),
        .init(id: "ErXwobaYiN019PkySvjV", name: "Antoni", category: "premade", labels: ["accent": "American", "gender": "male"])
    ]
}
