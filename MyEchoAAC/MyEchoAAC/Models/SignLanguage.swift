import Foundation

enum SignLanguage: String, Codable, CaseIterable, Identifiable {
    case auslan
    case asl

    var id: String { rawValue }

    var label: String {
        switch self {
        case .auslan: "Auslan"
        case .asl: "ASL"
        }
    }

    var fullName: String {
        switch self {
        case .auslan: "Australian Sign Language"
        case .asl: "American Sign Language"
        }
    }

    var attribution: String {
        switch self {
        case .auslan: "Videos: Auslan Signbank (CC BY-NC-ND 4.0)"
        case .asl: "Videos: signasl.org"
        }
    }
}
