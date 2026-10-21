//
//  MessageWindowView.swift
//  shiritori
//
//  Phase20：メッセージ一文字ずつ表示・メッセージ効果音
//  CPUメッセージウィンドウ表示改善：4行対応・固定高維持
//

import SwiftUI

// 表示中のTextの実高さを測定し、折り返し行数が変わった時だけ配置を切り替える。
private struct MessageTextHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// CPUやPLAYERのメッセージを表示する
struct MessageWindowView: View {

    // 表示するメッセージ
    let message: String

    // 指定された秒数で全文を表示する。nilの場合は従来の文字間隔を使う
    var typingDuration: TimeInterval? = nil

    // trueの場合、文字単位にせず一度に全文を表示する
    var displayImmediately: Bool = false

    // 全文を一度に表示したあと、完了通知まで保持する秒数
    var holdDuration: TimeInterval? = nil

    // trueの場合、メッセージの各行を中央揃えで表示する
    var centerText: Bool = false

    // メッセージを最後まで表示し、保持時間が終わったときに呼び出す処理
    var onCompleted: ((String) -> Void)? = nil

    // 現在表示している文字列
    @State private var displayedMessage = ""

    // メッセージ表示用タイマー
    @State private var typingTimer: Timer?

    // 現在の表示文字列の実際の高さ。折り返し行数が変わった時だけ更新される。
    @State private var measuredTextHeight: CGFloat = 0

    // 1文字を表示する間隔
    private let typingInterval: TimeInterval = 0.06

    // 13ptフォントの1行分の高さを見積もる。行数の分類にだけ使用する。
    private let estimatedLineHeight: CGFloat = 16

    private var visibleLineCount: Int {
        guard measuredTextHeight > 0 else { return 1 }
        return min(4, max(1, Int(ceil(measuredTextHeight / estimatedLineHeight))))
    }

    // 行数が増えた場合だけ配置段階が切り替わる。
    // 1行は中央付近、2行は少し下寄り、3〜4行は上部に配置する。
    private var topInset: CGFloat {
        if centerText { return 0 }
        switch visibleLineCount {
        case 1: return 26
        case 2: return 16
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
                .font(DungeonTypography.maruMonica(size: 13))
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
        .frame(height: 72, alignment: centerText ? .center : .topLeading)
        .padding(.horizontal, 8)
        .background(Color.black)
        .overlay(
            Rectangle()
                .stroke(Color.white, lineWidth: 3)
        )
        .clipped()
        .onPreferenceChange(MessageTextHeightPreferenceKey.self) { newHeight in
            // 文字送り中のわずかな高さ変化で位置が揺れないよう、行の高さ単位でのみ更新する。
            let oldLineCount = visibleLineCount
            let newLineCount = min(4, max(1, Int(ceil(newHeight / estimatedLineHeight))))
            if newLineCount != oldLineCount || measuredTextHeight == 0 {
                measuredTextHeight = CGFloat(newLineCount) * estimatedLineHeight
            }
        }
        .onAppear {
            startTypingMessage()
        }
        .onChangeCompat(of: message) { _, _ in
            startTypingMessage()
        }
        .onDisappear {
            stopTypingMessage()
        }
    }

    // メッセージを一文字ずつ表示する処理を開始する
    private func startTypingMessage() {
        stopTypingMessage()
        displayedMessage = ""
        measuredTextHeight = 0

        guard !message.isEmpty else {
            return
        }

        // 指定された場合は、全文を一気に表示して指定時間だけ保持する
        if displayImmediately {
            displayedMessage = message
            scheduleCompletion(after: holdDuration, for: message)
            return
        }

        let characters = Array(message)
        var currentIndex = 0

        // 表示時間指定がある場合は、文字数で割って指定秒数で表示する。
        // 改行も1文字として数え、指定時間内に全文を表示する。
        let interval = typingDuration.map {
            $0 / Double(characters.count)
        } ?? typingInterval

        typingTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { timer in
            guard currentIndex < characters.count else {
                timer.invalidate()
                typingTimer = nil
                return
            }

            displayedMessage.append(characters[currentIndex])
            SoundEffectManager.shared.playMessageBeep()
            currentIndex += 1

            if currentIndex == characters.count {
                timer.invalidate()
                typingTimer = nil
                scheduleCompletion(after: holdDuration, for: message)
            }
        }
    }

    // 指定された保持時間のあとでメッセージ完了を通知する
    private func scheduleCompletion(
        after duration: TimeInterval?,
        for completedMessage: String
    ) {
        guard let duration, duration > 0 else {
            onCompleted?(completedMessage)
            return
        }

        typingTimer = Timer.scheduledTimer(
            withTimeInterval: duration,
            repeats: false
        ) { _ in
            typingTimer = nil
            onCompleted?(completedMessage)
        }
    }

    // メッセージ表示処理を停止する
    private func stopTypingMessage() {
        typingTimer?.invalidate()
        typingTimer = nil
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
