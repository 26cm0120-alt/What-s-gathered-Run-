import AVFoundation
import SwiftUI

/// Kマスの宝箱を表示し、初回取得時は鍵の演出を再生する
struct KeyAcquisitionView: View {
    let hasKey: Bool
    let isAcquiringKey: Bool
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var chestIsOpen = false
    @State private var keyVisible = false
    @State private var keyRise: CGFloat = 0
    @State private var keyRotation = 10.0
    @State private var chestOpenAudioPlayer: AVAudioPlayer?
    @State private var itemFoundAudioPlayer: AVAudioPlayer?
    @State private var audioErrorDelegates: [AudioPlaybackErrorDelegate] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isAcquiringKey {
                    // 初回は閉じた宝箱から始め、鍵の演出中だけ背景を暗くする
                    Color.black.opacity(0.62)

                    ZStack {
                        Image("CloseBox")
                            .resizable()
                            .scaledToFit()
                            .opacity(chestIsOpen ? 0 : 1)

                        Image("OpenBox")
                            .resizable()
                            .scaledToFit()
                            .opacity(chestIsOpen ? 1 : 0)
                    }
                    .frame(
                        width: geometry.size.width * 0.48,
                        height: geometry.size.height * 0.42
                    )
                    .animation(.easeInOut(duration: 0.22), value: chestIsOpen)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height * 0.60
                    )

                    Image("key")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: geometry.size.width * 0.20,
                            height: geometry.size.height * 0.22
                        )
                        .scaleEffect(keyVisible ? 1 : 0.82)
                        .rotationEffect(.degrees(keyRotation))
                        .opacity(keyVisible ? 1 : 0)
                        .position(
                            x: geometry.size.width * 0.52,
                            y: geometry.size.height * 0.57 + keyRise
                        )
                } else {
                    Image(hasKey ? "OpenBox" : "CloseBox")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: geometry.size.width * 0.48,
                            height: geometry.size.height * 0.42
                        )
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height * 0.60
                        )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .task(id: isAcquiringKey) {
                guard isAcquiringKey else { return }

                // 初回の鍵取得時だけ、メッセージと同時に宝箱を開ける音を再生する
                chestOpenAudioPlayer?.stop()
                chestOpenAudioPlayer = playSound(named: "宝箱を開ける")

                // メッセージが表示されてから1秒待って、宝箱を開ける
                chestIsOpen = false
                keyVisible = false
                keyRise = 0
                keyRotation = 10
                try? await Task.sleep(for: .milliseconds(1000))
                guard !Task.isCancelled else { return }

                itemFoundAudioPlayer?.stop()
                itemFoundAudioPlayer = playSound(named: "アイテム発見")

                if reduceMotion {
                    withAnimation(.easeOut(duration: 0.15)) {
                        chestIsOpen = true
                        keyVisible = true
                        keyRotation = 0
                    }
                    try? await Task.sleep(for: .milliseconds(850))
                } else {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        chestIsOpen = true
                    }
                    withAnimation(.spring(response: 0.68, dampingFraction: 0.7)) {
                        keyVisible = true
                        keyRise = -geometry.size.height * 0.14
                        keyRotation = 0
                    }
                    try? await Task.sleep(for: .milliseconds(850))
                }

                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.18)) {
                    keyVisible = false
                }
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                onFinished()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isAcquiringKey ? "宝箱から鍵を手に入れた" : (hasKey ? "空の宝箱" : "鍵の入った閉じた宝箱"))
        .allowsHitTesting(false)
    }

    /// アプリに同梱した効果音を再生する
    private func playSound(named resourceName: String) -> AVAudioPlayer? {
        guard let player = AudioPlayback.makePlayer(named: resourceName) else { return nil }
        let errorDelegate = AudioPlaybackErrorDelegate(resourceName: resourceName)
        player.delegate = errorDelegate
        guard AudioPlayback.play(player, named: resourceName) else { return nil }
        audioErrorDelegates.append(errorDelegate)
        return player
    }
}
