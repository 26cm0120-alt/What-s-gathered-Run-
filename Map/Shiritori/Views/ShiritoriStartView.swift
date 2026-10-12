//
//  ShiritoriStartView.swift
//  shiritori
//
//  プロローグ画面
//

import SwiftUI

// ゲーム開始前のプロローグ画面を担当する
struct ShiritoriStartView: View {

    /// プロローグが完了したときに統合アプリへ通知する。
    let onGameStart: () -> Void

    // プロローグで表示するメッセージ
    private let message = """
    でぐちの とびらを ひらくと
    もんばんが ２５まいの 
    カードを ならべて
    きみを まちうけていた ・・・
    """

    // 現在画面に表示されている文字
    @State private var displayedMessage = ""

    // 文字表示用タイマー
    @State private var typingTimer: Timer?

    // 全文表示後の待機用タイマー
    @State private var transitionTimer: Timer?

    // メッセージ全体を15秒かけて表示する
    private let typingDuration: TimeInterval = 15.0

    // 全文表示完了後、2秒待って統合アプリへゲーム開始を通知する
    private let transitionDelay: TimeInterval = 2.0

    var body: some View {
        ZStack {
            // プロローグ画面は真っ黒にする
            Color.black
                .ignoresSafeArea()

            // メッセージを画面中央に表示する
            Text(displayedMessage)
                .font(
                    .system(
                        size: 20,
                        weight: .regular,
                        design: .monospaced
                    )
                )
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .center
                )
                .padding(24)
        }
        .onAppear {
            // プロローグ画面が表示されたら開始する
            startPrologue()
        }
        .onDisappear {
            // 画面終了時にタイマーを停止する
            stopTimers()


        }
    }

    // プロローグを開始する
    private func startPrologue() {

        // 既存のタイマーがあれば停止する
        stopTimers()

        // 表示文字を初期化する
        displayedMessage = ""

        // プロローグBGMを1回だけ再生する
        SoundEffectManager.shared.startPrologueBGM()

        // メッセージを1文字ずつ扱えるようにする
        let characters = Array(message)

        guard !characters.isEmpty else {
            startGameTransition()
            return
        }

        // メッセージ全体を15秒で表示するための1文字あたりの時間
        let interval = typingDuration / Double(characters.count)

        var currentIndex = 0

        // 一定間隔で1文字ずつ表示する
        typingTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { timer in

            if currentIndex < characters.count {

                displayedMessage.append(
                    characters[currentIndex]
                )

                currentIndex += 1

            } else {

                // 全文表示が完了したのでタイマーを停止する
                timer.invalidate()
                typingTimer = nil

                // 全文表示後、2秒待って統合アプリへゲーム開始を通知する
                startGameTransition()
            }
        }
    }

    // 全文表示完了後、2秒待って統合アプリへゲーム開始を通知する
    private func startGameTransition() {

        transitionTimer?.invalidate()

        transitionTimer = Timer.scheduledTimer(
            withTimeInterval: transitionDelay,
            repeats: false
        ) { _ in

            transitionTimer = nil

            // プロローグBGMを停止する
            // BGMが15秒で終了していた場合は何も起こらない
            SoundEffectManager.shared.stopPrologueBGM()

            // 既存の表示時間を維持したまま、統合アプリへゲーム開始を通知する。
            onGameStart()
        }
    }

    // 使用中のタイマーを停止する
    private func stopTimers() {
        typingTimer?.invalidate()
        typingTimer = nil

        transitionTimer?.invalidate()
        transitionTimer = nil
    }
}

#Preview {
    ShiritoriStartView(onGameStart: {})
}
