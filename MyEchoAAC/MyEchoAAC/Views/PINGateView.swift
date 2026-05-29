import SwiftUI

struct PINGateView: View {
    @Environment(\.dismiss) private var dismiss
    let onUnlock: () -> Void

    private enum Mode {
        case enterExisting
        case createFirst
        case confirmCreate(firstPIN: String)
    }

    @State private var mode: Mode
    @State private var entry: String = ""
    @State private var errorMessage: String?
    @State private var shake: Bool = false
    @State private var showResetConfirm = false

    private let pinLength = 4

    init(onUnlock: @escaping () -> Void) {
        self.onUnlock = onUnlock
        _mode = State(initialValue: PINStore.isSet ? .enterExisting : .createFirst)
    }

    var body: some View {
        VStack(spacing: 20) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 56)
                .accessibilityHidden(true)

            Text(title)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.85))

            Text(subtitle)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            pinDots
                .modifier(ShakeEffect(animatableData: shake ? 1 : 0))

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red)
            }

            keypad

            if case .enterExisting = mode {
                Button("Forgot PIN?") {
                    showResetConfirm = true
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            }

            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.98, green: 0.99, blue: 1.0).ignoresSafeArea())
        .alert("Reset parent PIN?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                PINStore.clear()
                mode = .createFirst
                entry = ""
                errorMessage = nil
            }
        } message: {
            Text("This clears the saved PIN so you can set a new one. Your board and settings are not changed.")
        }
    }

    private var title: String {
        switch mode {
        case .enterExisting: "Parent PIN"
        case .createFirst: "Create a Parent PIN"
        case .confirmCreate: "Confirm PIN"
        }
    }

    private var subtitle: String {
        switch mode {
        case .enterExisting: "Enter your 4-digit PIN to open parent settings."
        case .createFirst: "Choose a 4-digit PIN to protect parent settings."
        case .confirmCreate: "Enter the same 4 digits again to confirm."
        }
    }

    private var pinDots: some View {
        HStack(spacing: 16) {
            ForEach(0..<pinLength, id: \.self) { index in
                Circle()
                    .fill(index < entry.count ? Color.accentColor : Color.gray.opacity(0.25))
                    .frame(width: 18, height: 18)
            }
        }
        .padding(.vertical, 8)
    }

    private var keypad: some View {
        VStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 14) {
                    ForEach(1...3, id: \.self) { col in
                        let digit = row * 3 + col
                        digitButton("\(digit)")
                    }
                }
            }
            HStack(spacing: 14) {
                Color.clear.frame(width: 72, height: 72)
                digitButton("0")
                deleteButton
            }
        }
    }

    private func digitButton(_ digit: String) -> some View {
        Button {
            handleDigit(digit)
        } label: {
            Text(digit)
                .font(.system(.title, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.85))
                .frame(width: 72, height: 72)
                .background(Color.white)
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(digit)
    }

    private var deleteButton: some View {
        Button {
            if !entry.isEmpty { entry.removeLast() }
            errorMessage = nil
        } label: {
            Image(systemName: "delete.left")
                .font(.system(.title2, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.7))
                .frame(width: 72, height: 72)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Delete")
    }

    private func handleDigit(_ digit: String) {
        guard entry.count < pinLength else { return }
        entry.append(digit)
        errorMessage = nil

        if entry.count == pinLength {
            submit()
        }
    }

    private func submit() {
        switch mode {
        case .enterExisting:
            if PINStore.verify(entry) {
                onUnlock()
                dismiss()
            } else {
                fail("Wrong PIN")
            }
        case .createFirst:
            mode = .confirmCreate(firstPIN: entry)
            entry = ""
        case .confirmCreate(let firstPIN):
            if entry == firstPIN {
                PINStore.save(entry)
                onUnlock()
                dismiss()
            } else {
                mode = .createFirst
                fail("Digits don't match. Start again.")
            }
        }
    }

    private func fail(_ message: String) {
        errorMessage = message
        entry = ""
        withAnimation(.default) {
            shake.toggle()
        }
    }
}

private struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = 10 * sin(animatableData * .pi * 4)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}
