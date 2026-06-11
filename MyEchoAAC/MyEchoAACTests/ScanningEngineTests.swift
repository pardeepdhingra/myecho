import Foundation
import Testing
@testable import MyEchoAAC

@MainActor
@Suite("ScanningEngine")
struct ScanningEngineTests {

    @Test func initiallyIdle() {
        let engine = ScanningEngine()
        #expect(engine.phase == .idle)
    }

    @Test func startMovesToFirstRow() {
        let engine = ScanningEngine()
        engine.configure(rows: 3, cols: 4)
        engine.advance()
        if case .row(let r) = engine.phase {
            #expect(r == 0)
        } else {
            Issue.record("Expected .row(0), got \(engine.phase)")
        }
    }

    @Test func advanceRowWraps() {
        let engine = ScanningEngine()
        engine.configure(rows: 2, cols: 4)
        engine.advance() // row 0
        engine.advance() // row 1
        engine.advance() // wraps back to row 0
        if case .row(let r) = engine.phase {
            #expect(r == 0)
        } else {
            Issue.record("Expected wrap to .row(0), got \(engine.phase)")
        }
    }

    @Test func selectRowMovesToCell() {
        let engine = ScanningEngine()
        engine.configure(rows: 3, cols: 4)
        engine.advance()            // → .row(0)
        engine.selectCurrentRow()   // → .cell(row: 0, col: 0)
        if case .cell(let r, let c) = engine.phase {
            #expect(r == 0)
            #expect(c == 0)
        } else {
            Issue.record("Expected .cell(0,0), got \(engine.phase)")
        }
    }

    @Test func advanceCellWithinRow() {
        let engine = ScanningEngine()
        engine.configure(rows: 3, cols: 3)
        engine.advance()            // → .row(0)
        engine.selectCurrentRow()   // → .cell(0, 0)
        engine.advance()            // → .cell(0, 1)
        if case .cell(let r, let c) = engine.phase {
            #expect(r == 0)
            #expect(c == 1)
        } else {
            Issue.record("Expected .cell(0,1), got \(engine.phase)")
        }
    }

    @Test func advancePastLastCellReturnsToRowPhase() {
        let engine = ScanningEngine()
        engine.configure(rows: 3, cols: 2)
        engine.advance()            // → .row(0)
        engine.selectCurrentRow()   // → .cell(0, 0)
        engine.advance()            // → .cell(0, 1)
        engine.advance()            // overflows → back to .row(1)
        if case .row(let r) = engine.phase {
            #expect(r == 1)
        } else {
            Issue.record("Expected .row(1), got \(engine.phase)")
        }
    }

    @Test func highlightedIndicesRowPhase() {
        let engine = ScanningEngine()
        engine.configure(rows: 2, cols: 3)
        engine.advance() // → .row(0)
        // Row 0 with 3 cols → indices 0,1,2 highlighted
        let indices = engine.highlightedIndices
        #expect(indices == [0, 1, 2])
    }

    @Test func highlightedIndicesCellPhase() {
        let engine = ScanningEngine()
        engine.configure(rows: 2, cols: 3)
        engine.advance()            // → .row(0)
        engine.selectCurrentRow()   // → .cell(0, 0)
        let indices = engine.highlightedIndices
        #expect(indices == [0])
    }

    @Test func stopResetsToIdle() {
        let engine = ScanningEngine()
        engine.configure(rows: 3, cols: 3)
        engine.advance()
        engine.stop()
        #expect(engine.phase == .idle)
    }

    @Test func scanningEnabledDefaultIsFalse() {
        #expect(AACSettings.default.scanningEnabled == false)
    }
}
