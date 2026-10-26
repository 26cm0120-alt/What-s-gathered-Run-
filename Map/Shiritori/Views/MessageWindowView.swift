//
//  MessageWindowView.swift
//  shiritori
//
//  Phase20：メッセージ一文字ずつ表示・メッセージ効果音
//  CPUメッセージウィンドウ表示改善：4行対応・固定高維持
//

import SwiftUI

private struct MessageTextHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct MessageWindowView: View {
    let message: String
    var typingDuration: TimeInterval? = nil
    var displayImmediately: Bool = false
    var holdDuration: TimeInterval? = nil
    var centerText: Bool = false
    var onCompleted: ((String) -> Void)? = nil
    /// 文字と枠の倍率(iPadで文字を読みやすく大きく表示するときに使う)
    var scale: CGFloat = 1

    @State private var displayedMessage = ""
    @State private var measuredTextHeight: CGFloat = 0

    private let typingInterval: TimeInterval = 0.06
    private var estimatedLineHeight: CGFloat { 16 * scale }

    private var visibleLineCount: Int {
        guard measuredTextHeight > 0 else { return 1 }
        return min(4, max(1, Int(ceil(measuredTextHeight / estimatedLineHeight))))
    }

    private var topInset: CGFloat {
        if centerText { return 0 }
        switch visibleLineCount {
        case 1: return 26 * scale
        case 2: return 16 * scale
        default: return 3
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if centerText {
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: topInset)
            }

            Text(displayedMessage)
                .font(DungeonTypography.maruMonica(size: 13 * scale))
                .foregroundStyle(.white)
                .multilineTextAlignment(centerText ? .center : .leading)
                .lineSpacing(1)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: centerText ? .center : .leading)
                .background {
                    GeometryReader { textGeometry in
                        Color.clear.preference(
                            key: MessageTextHeightPreferenceKey.self,
                            value: textGeometry.size.height
                        )
                    }
                }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72 * scale, alignment: centerText ? .center : .topLeading)
        .padding(.horizontal, 8)
        .background(Color.black)
        .overlay(
            Rectangle()
                .stroke(Color.white, lineWidth: 3)
        )
        .clipped()
        .onPreferenceChange(MessageTextHeightPreferenceKey.self) { newHeight in
            let oldLineCount = visibleLineCount
            let newLineCount = min(4, max(1, Int(ceil(newHeight / estimatedLineHeight))))
            if newLineCount != oldLineCount || measuredTextHeight == 0 {
                measuredTextHeight = CGFloat(newLineCount) * estimatedLineHeight
            }
        }
        // messageが変わるたびに最新の値で処理を開始し、旧タスクは自動キャンセルする。
        .task(id: message) {
            await runTyping(
                message: message,
                typingDuration: typingDuration,
                displayImmediately: displayImmediately,
                holdDuration: holdDuration
            )
        }
    }

    @MainActor
    private func runTyping(
        message: String,
        typingDuration: TimeInterval?,
        displayImmediately: Bool,
        holdDuration: TimeInterval?
    ) async {
        displayedMessage = ""
        measuredTextHeight = 0

        guard !Task.isCancelled, !message.isEmpty else { return }

        if displayImmediately {
            displayedMessage = message
            await notifyCompleted(message: message, holdDuration: holdDuration)
            return
        }

        let characters = Array(message)
        let interval = typingDuration.map {
            $0 / Double(characters.count)
        } ?? typingInterval

        for character in characters {
            do {
                try await Task.sleep(
                    nanoseconds: UInt64(max(0, interval) * 1_000_000_000)
                )
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            displayedMessage.append(character)
            SoundEffectManager.shared.playMessageBeep()
        }

        await notifyCompleted(message: message, holdDuration: holdDuration)
    }

    @MainActor
    private func notifyCompleted(
        message: String,
        holdDuration: TimeInterval?
    ) async {
        guard !Task.isCancelled else { return }

        if let holdDuration, holdDuration > 0 {
            do {
                try await Task.sleep(
                    nanoseconds: UInt64(holdDuration * 1_000_000_000)
                )
            } catch {
                return
            }
        }

        guard !Task.isCancelled else { return }
        onCompleted?(message)
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        MessageWindowView(
            message: "「さあ、始めるとしよう」"
        )
        .padding()
    }
}
