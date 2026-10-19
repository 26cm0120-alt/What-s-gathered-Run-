import SwiftUI

/// タイトルロゴの左右に青いPlayerドラゴンと紫のドラゴンを表示する。
struct AnimatedTitleDragonTitleRow: View {
    var compact = false

    var body: some View {
        ZStack {
            Text("ワギャラン")
                .font(DungeonTypography.maruMonica(size: compact ? 15 : 20))
                .tracking(4)
                .foregroundStyle(Color(red: 0.89, green: 0.78, blue: 0.49))

            HStack {
                AnimatedTitleCharacter(
                    label: "青いPlayerドラゴン",
                    frames: [
                        ("PlayerIdle", 800_000_000),
                        ("PlayerMove1", 120_000_000),
                        ("PlayerMove2", 120_000_000),
                        ("PlayerMove3", 240_000_000),
                        ("PlayerBreath", 500_000_000)
                    ],
                    size: CGSize(width: compact ? 38 : 54, height: compact ? 42 : 66),
                    idlePhaseDelay: 0
                )
                Spacer(minLength: 8)
                AnimatedTitleCharacter(
                    label: "紫のドラゴン",
                    frames: [
                        ("MessageMonsterIdle", 850_000_000),
                        ("MessageMonsterMove1", 500_000_000),
                        ("MessageMonsterIdle", 350_000_000),
                        ("MessageMonsterMove1", 110_000_000),
                        ("MessageMonsterMove2", 110_000_000),
                        ("MessageMonsterMove3", 260_000_000)
                    ],
                    size: CGSize(width: compact ? 38 : 54, height: compact ? 42 : 66),
                    idlePhaseDelay: 280_000_000
                )
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: 360)
        .frame(height: compact ? 42 : 70)
    }
}

/// タイトル下に敵3種を横一列で表示する。
struct AnimatedTitleMonsterView: View {
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 8 : 12) {
            AnimatedTitleCharacter(
                label: "スライム",
                frames: [("DungeonSlime", 900_000_000)],
                size: CGSize(width: compact ? 34 : 48, height: compact ? 40 : 60),
                idlePhaseDelay: 120_000_000
            )
            AnimatedTitleCharacter(
                label: "スケルトン",
                frames: [("DungeonSkeleton", 900_000_000)],
                size: CGSize(width: compact ? 34 : 48, height: compact ? 40 : 60),
                idlePhaseDelay: 420_000_000
            )
            AnimatedTitleCharacter(
                label: "ガーゴイル",
                frames: [("DungeonGargoyle", 900_000_000)],
                size: CGSize(width: compact ? 34 : 48, height: compact ? 40 : 60),
                idlePhaseDelay: 720_000_000
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: compact ? 40 : 64)
    }
}

/// タイトルキャラクターの画像切り替えと、待機中の呼吸動作を行う。
private struct AnimatedTitleCharacter: View {
    let label: String
    let frames: [(image: String, duration: UInt64)]
    let size: CGSize
    let idlePhaseDelay: UInt64

    @State private var currentImage: String
    @State private var isIdleLifted = false

    init(
        label: String,
        frames: [(image: String, duration: UInt64)],
        size: CGSize,
        idlePhaseDelay: UInt64
    ) {
        self.label = label
        self.frames = frames
        self.size = size
        self.idlePhaseDelay = idlePhaseDelay
        _currentImage = State(initialValue: frames[0].image)
    }

    var body: some View {
        Image(currentImage)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
            .scaleEffect(isIdleLifted ? 1.035 : 1, anchor: .bottom)
            .offset(y: isIdleLifted ? -2 : 0)
            .accessibilityLabel("タイトルの\(label)キャラクター")
            .animation(.easeInOut(duration: 0.08), value: currentImage)
            .task {
                if idlePhaseDelay > 0 {
                    try? await Task.sleep(nanoseconds: idlePhaseDelay)
                }
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.72).repeatForever(autoreverses: true)) {
                    isIdleLifted = true
                }
                while !Task.isCancelled {
                    for frame in frames {
                        guard !Task.isCancelled else { return }
                        currentImage = frame.image
                        try? await Task.sleep(nanoseconds: frame.duration)
                    }
                }
            }
    }
}
