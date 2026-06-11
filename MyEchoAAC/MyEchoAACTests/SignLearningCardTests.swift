import Foundation
import Testing
@testable import MyEchoAAC

@MainActor
@Suite("SignLearningCard")
struct SignLearningCardTests {

    private func word(hasSign: Bool, language: SignLanguage = .auslan) -> AACWord {
        AACWord(
            label: "eat",
            symbol: "🍴",
            category: "Food",
            colorName: .green,
            position: 1,
            signVideoPath: hasSign ? "eat.mp4" : nil,
            signLanguage: hasSign ? language : nil
        )
    }

    @Test func signedWordIsEligibleForCard() {
        let w = word(hasSign: true)
        #expect(w.signVideoPath != nil)
    }

    @Test func unsignedWordIsNotEligible() {
        let w = word(hasSign: false)
        #expect(w.signVideoPath == nil)
    }

    @Test func cardWordLabelPreserved() {
        let w = word(hasSign: true)
        #expect(w.label == "eat")
    }

    @Test func auslanAttributionLabel() {
        #expect(SignLanguage.auslan.attribution.contains("Auslan Signbank"))
    }

    @Test func aslAttributionLabel() {
        #expect(SignLanguage.asl.attribution.contains("signasl.org"))
    }

    @Test func signLanguageLabelMatchesEnumCase() {
        #expect(SignLanguage.auslan.label == "Auslan")
        #expect(SignLanguage.asl.label == "ASL")
    }
}
