import AVFoundation
import SwiftUI

/// 初回の鍵取得時に、宝箱と鍵の演出を再生する
struct KeyAcquisitionView: View {
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
                // 初回は閉じた宝箱から始め、鍵の演出中だけ背景を暗くする
                Color.black.opacity(0.62)

                ZStack {
                    Image("ChestClosedFront")
                        .resizable()
                        .scaledToFit()
                        .opacity(chestIsOpen ? 0 : 1)

                    Image("ChestOpenFront")
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
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .task {
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
        .accessibilityLabel("宝箱から鍵を手に入れた")
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

/// 剣の取得時に、ダンジョン画面上でアイテムと発見演出を表示する。
struct SwordPickupView: View {
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRevealed = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioErrorDelegate: AudioPlaybackErrorDelegate?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.58)

                VStack(spacing: 8) {
                    Text("ITEM FOUND")
                        .font(DungeonTypography.maruMonica(size: 13))
                        .tracking(3)
                        .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.36))

                    SwordPickupGlyph()
                        .frame(width: geometry.size.width * 0.25, height: geometry.size.height * 0.44)
                        .scaleEffect(isRevealed ? 1 : 0.58)
                        .rotationEffect(.degrees(isRevealed ? -8 : 12))
                        .shadow(color: Color(red: 0.35, green: 0.72, blue: 1).opacity(isRevealed ? 0.8 : 0), radius: 24)

                    Text("剣を手に入れた！")
                        .font(DungeonTypography.maruMonica(size: 19))
                        .foregroundStyle(.white)
                    Text("攻撃力 UP")
                        .font(DungeonTypography.maruMonica(size: 13))
                        .foregroundStyle(Color(red: 0.74, green: 0.87, blue: 1.0))
                }
                .multilineTextAlignment(.center)
                .opacity(isRevealed ? 1 : 0)
                .scaleEffect(isRevealed ? 1 : 0.9)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .task {
                playItemFoundSound()
                if reduceMotion {
                    isRevealed = true
                    try? await Task.sleep(for: .milliseconds(1800))
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.68)) {
                        isRevealed = true
                    }
                    try? await Task.sleep(for: .milliseconds(1800))
                }
                guard !Task.isCancelled else { return }
                onFinished()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("剣を手に入れた。攻撃力が上がった")
    }

    private func playItemFoundSound() {
        guard let player = AudioPlayback.makePlayer(named: "アイテム発見") else { return }
        let delegate = AudioPlaybackErrorDelegate(resourceName: "アイテム発見")
        player.delegate = delegate
        guard AudioPlayback.play(player, named: "アイテム発見") else { return }
        audioPlayer = player
        audioErrorDelegate = delegate
    }
}

/// 発見演出に使う、光沢を付けた独自ベクター剣。
private struct SwordPickupGlyph: View {
    var body: some View {
        Canvas { context, size in
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: size.width * x, y: size.height * y)
            }

            var blade = Path()
            blade.move(to: point(0.28, 0.70))
            blade.addLine(to: point(0.68, 0.18))
            blade.addQuadCurve(to: point(0.77, 0.12), control: point(0.76, 0.17))
            blade.addLine(to: point(0.72, 0.30))
            blade.addLine(to: point(0.37, 0.76))
            blade.closeSubpath()
            context.fill(
                blade,
                with: .linearGradient(
                    Gradient(colors: [Color.white, Color(red: 0.52, green: 0.81, blue: 1.0), Color(red: 0.20, green: 0.42, blue: 0.67)]),
                    startPoint: point(0.68, 0.14),
                    endPoint: point(0.30, 0.76)
                )
            )
            context.stroke(blade, with: .color(Color.white.opacity(0.9)), lineWidth: 1.4)

            var fuller = Path()
            fuller.move(to: point(0.65, 0.25))
            fuller.addLine(to: point(0.37, 0.66))
            context.stroke(fuller, with: .color(Color(red: 0.13, green: 0.31, blue: 0.51)), lineWidth: 2)

            var guardPath = Path()
            guardPath.move(to: point(0.18, 0.60))
            guardPath.addQuadCurve(to: point(0.49, 0.83), control: point(0.31, 0.89))
            context.stroke(guardPath, with: .color(Color(red: 1.0, green: 0.78, blue: 0.25)), style: StrokeStyle(lineWidth: max(4, size.width * 0.065), lineCap: .round))

            var handle = Path()
            handle.move(to: point(0.31, 0.72))
            handle.addLine(to: point(0.16, 0.88))
            context.stroke(handle, with: .color(Color(red: 0.47, green: 0.23, blue: 0.10)), style: StrokeStyle(lineWidth: max(5, size.width * 0.08), lineCap: .round))
            context.fill(Path(ellipseIn: CGRect(x: size.width * 0.07, y: size.height * 0.84, width: size.width * 0.18, height: size.width * 0.18)), with: .color(Color(red: 1.0, green: 0.78, blue: 0.25)))
        }
        .accessibilityHidden(true)
    }
}
