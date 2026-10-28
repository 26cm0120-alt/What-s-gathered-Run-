import SwiftUI

/// タイトルロゴ。両脇にしりとりCPU2と紫のドラゴンを向かい合わせ、それぞれ4枚の差分を切り替える。
/// iPhoneでは小さめ、iPadでは仮想キャンバス(幅700pt)に合わせて大きく表示する。
struct TitleLogoWithDragons: View {
    var compact = false

    private var isPad: Bool { IPadLayoutMetrics.isPad }
    private var dragonSize: CGFloat { isPad ? 150 : (compact ? 72 : 94) }

    private static let cpu2Frames = ["TitleCPU2Idle", "character_cpu2_blink", "TitleCPU2Breath1", "TitleCPU2Breath2"]
    private static let purpleFrames = ["MessageMonsterIdle", "MessageMonsterMove1", "MessageMonsterMove2", "MessageMonsterMove3"]
    // 0.25秒単位。CPU2は2.5秒、右のドラゴンは1秒周期なので5秒で一巡する。
    @State private var animationTick = 0
    private var cpu2FrameIndex: Int {
        switch animationTick % 10 {
        case 0..<4: return 0 // 通常: 1秒
        case 4..<6: return 1 // 瞬き: 0.5秒
        case 6..<8: return 2 // 呼吸1: 0.5秒
        default: return 3   // 呼吸2: 0.5秒
        }
    }
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var running: Bool { scenePhase == .active && !reduceMotion }

    private let gold = Color(red: 0.89, green: 0.78, blue: 0.49)

    var body: some View {
        VStack(spacing: compact ? 0 : 2) {
            Text("What's gathered?")
                .font(DungeonTypography.maruMonica(size: isPad ? 38 : (compact ? 26 : 30)))
                .minimumScaleFactor(0.82)
                .lineLimit(1)
                .foregroundStyle(gold)

            HStack(alignment: .center, spacing: 0) {
                // 左: しりとりCPU2の通常待機アニメーション
                titleCharacter(image: Self.cpu2Frames[cpu2FrameIndex], label: "しりとりCPU2")

                Spacer(minLength: 4)

                VStack(spacing: -4) {
                    Text("Run!")
                        .font(DungeonTypography.maruMonica(size: isPad ? 70 : (compact ? 46 : 54)))
                    Text("ワギャラン")
                        .font(DungeonTypography.maruMonica(size: isPad ? 26 : (compact ? 15 : 20)))
                        .tracking(4)
                }
                .foregroundStyle(gold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityElement(children: .combine)

                Spacer(minLength: 4)

                // 右: 紫のドラゴン(左=中央を向く)
                titleCharacter(image: Self.purpleFrames[animationTick % Self.purpleFrames.count], label: "紫のドラゴン")
                    .scaleEffect(x: -1, y: 1)
            }
            .frame(maxWidth: IPadLayoutMetrics.startContentWidth)
        }
        .task(id: running) {
            guard running else {
                if reduceMotion { animationTick = 0 }
                return
            }
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 250_000_000)
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                animationTick = (animationTick + 1) % 20
            }
        }
    }

    private func titleCharacter(image: String, label: String) -> some View {
        Image(image)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: dragonSize, height: dragonSize)
            .accessibilityLabel("タイトルの\(label)キャラクター")
    }
}
