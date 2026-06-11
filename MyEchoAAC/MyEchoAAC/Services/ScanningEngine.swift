import Foundation
import SwiftUI

/// Manages row/column scanning for switch-access users.
///
/// Scanning works in two phases:
/// 1. **Row phase** — the cursor cycles through rows; the user advances with a switch press or tap.
///    All cells in the highlighted row are visually outlined. Calling `selectCurrentRow()` confirms
///    the row and enters the cell phase.
/// 2. **Cell phase** — the cursor cycles through columns within the selected row. Calling
///    `activate()` fires `onActivate` with the highlighted cell's (row, col) and returns to the
///    row phase.
///
/// Auto-scan fires `advance()` on a timer when `autoScan` is true. Manual scanning calls `advance()`
/// in response to a full-screen tap or external switch event.
@MainActor
final class ScanningEngine: ObservableObject {
    enum Phase: Equatable {
        case idle
        case row(Int)
        case cell(row: Int, col: Int)
    }

    @Published private(set) var phase: Phase = .idle

    /// Timer-driven auto-advance. Set false for manual / switch tap mode.
    var autoScan: Bool = true
    var scanInterval: TimeInterval = 2.0
    var onActivate: ((_ row: Int, _ col: Int) -> Void)?

    private(set) var rows: Int = 0
    private(set) var cols: Int = 0
    private var autoScanTask: Task<Void, Never>?

    func configure(rows: Int, cols: Int) {
        self.rows = rows
        self.cols = cols
    }

    func startAutoScan() {
        guard autoScan, autoScanTask == nil else { return }
        autoScanTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64((self?.scanInterval ?? 2.0) * 1_000_000_000))
                guard !Task.isCancelled else { break }
                self?.advance()
            }
        }
    }

    func stop() {
        autoScanTask?.cancel()
        autoScanTask = nil
        phase = .idle
    }

    /// Advance the scan cursor one step forward.
    func advance() {
        guard rows > 0, cols > 0 else { return }
        switch phase {
        case .idle:
            phase = .row(0)
        case .row(let r):
            let next = (r + 1) % rows
            phase = .row(next)
        case .cell(let r, let c):
            let nextCol = c + 1
            if nextCol >= cols {
                let nextRow = (r + 1) % rows
                phase = .row(nextRow)
            } else {
                phase = .cell(row: r, col: nextCol)
            }
        }
    }

    /// Confirm the currently highlighted row and enter cell scanning within it.
    func selectCurrentRow() {
        if case .row(let r) = phase {
            phase = .cell(row: r, col: 0)
        }
    }

    /// Activate the currently highlighted cell. Fires `onActivate` and returns to row scanning.
    func activate() {
        if case .cell(let r, let c) = phase {
            onActivate?(r, c)
            phase = .row(r)
        }
    }

    /// Flat indices (row * cols + col) of the currently highlighted cells.
    var highlightedIndices: Set<Int> {
        switch phase {
        case .idle:
            return []
        case .row(let r):
            guard cols > 0 else { return [] }
            return Set((0 ..< cols).map { r * cols + $0 })
        case .cell(let r, let c):
            return [r * cols + c]
        }
    }
}
