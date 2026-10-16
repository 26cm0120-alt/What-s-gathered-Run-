//
//  MessageWindowView.swift
//  shiritori
//
//  Phase20：メッセージ一文字ずつ表示・メッセージ効果音
//

import SwiftUI

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

    // 1文字を表示する間隔
    private let typingInterval: TimeInterval = 0.06

    var body: some View {
        Text(displayedMessage)
            .font(DungeonTypography.maruMonica(size: 14))
            .foregroundStyle(.white)
            // 通常メッセージは左揃え、導入の最後のメッセージだけ中央揃えにする
            .multilineTextAlignment(centerText ? .center : .leading)
            .lineSpacing(3)
            .lineLimit(3)
            .frame(
                maxWidth: .infinity,
                alignment: centerText ? .center : .topLeading
            )
            .frame(
                height: 72,
                alignment: centerText ? .center : .topLeading
            )
            .padding(.horizontal, 8)
            .background(Color.black)
            .overlay(
                Rectangle()
                    .stroke(Color.white, lineWidth: 3)
            )
            .onAppear {
                // 画面表示時にメッセージを一文字ずつ表示する
                startTypingMessage()
            }
            .onChange(of: message) { _, _ in
                // メッセージが変わったら、現在の表示を停止して最初から表示する
                startTypingMessage()
            }
            .onDisappear {
                // 画面から消えた場合は表示処理を停止する
                stopTypingMessage()
            }
    }

    // メッセージを一文字ずつ表示する処理を開始する
    private func startTypingMessage() {
        // 前回の表示処理が残っていれば停止する
        stopTypingMessage()

        // 新しいメッセージは最初から表示する
        displayedMessage = ""

        // 表示する文字がない場合はそのまま終了する
        guard !message.isEmpty else {
            return
        }

        // 指定された場合は、全文を一気に表示して指定時間だけ保持する
        if displayImmediately {
            displayedMessage = message

            // 一括表示の場合も、指定された保持時間を終えてから完了を通知する
            scheduleCompletion(after: holdDuration, for: message)
            return
        }

        // メッセージを文字単位で扱う
        let characters = Array(message)

        // 現在表示する文字の位置
        var currentIndex = 0

        // 表示時間指定がある場合は、文字数で割って指定秒数で表示する。
        // 改行も1文字として数えるため、2行メッセージ全体を指定秒数で表示する。
        let interval = typingDuration.map {
            $0 / Double(characters.count)
        } ?? typingInterval

        // 一定間隔で1文字ずつ表示する
        typingTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { timer in
            guard currentIndex < characters.count else {
                timer.invalidate()
                typingTimer = nil
                return
            }

            // 1文字追加する
            displayedMessage.append(characters[currentIndex])

            // 文字が1文字表示されるたびにメッセージ効果音を鳴らす
            SoundEffectManager.shared.playMessageBeep()

            // 次の文字へ進む
            currentIndex += 1

            // 最後の文字まで表示したら文字送りを停止し、指定の保持時間を待つ
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
        // 保持時間が指定されていない通常メッセージは、そのまま完了を通知する
        guard let duration, duration > 0 else {
            onCompleted?(completedMessage)
            return
        }

        // 保持時間の計測中もタイマーを保持し、画面変更時には停止できるようにする
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
