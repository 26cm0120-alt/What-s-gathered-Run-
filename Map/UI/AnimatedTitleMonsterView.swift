import SwiftUI

/// タイトルロゴ。両脇に青いPlayerドラゴンと紫のドラゴンを大きく向かい合わせ、待機ポーズで動かす。
/// iPhoneでは小さめ、iPadでは仮想キャンバス(幅700pt)に合わせて大きく表示する。
struct TitleLogoWithDragons: View {
    var compact = false

    private var isPad: Bool { IPadLayoutMetrics.isPad }
    private var dragonSize: CGFloat { isPad ? 150 : (compact ? 72 : 94) }

    private let gold = Color(red: 0.89, green: 0.78, blue: 0.49)

    var body: some View {
        VStack(spacing: compact ? 0 : 2) {
            Text("What's gathered?")
                .font(DungeonTypography.maruMonica(size: isPad ? 38 : (compact ? 26 : 30)))
                .minimumScaleFactor(0.82)
                .lineLimit(1)
                .foregroundStyle(gold)

            HStack(alignment: .center, spacing: 0) {
                // 左: 青いPlayerドラゴン(右=中央を向く)
                AnimatedTitleCharacter(
                    label: "青いPlayerドラゴン",
                    frames: [
                        ("PlayerIdle", 900_000_000),
                        ("PlayerBreath", 450_000_000),
                        ("PlayerIdle", 700_000_000),
                        ("PlayerBlink", 130_000_000)
                    ],
                    size: CGSize(width: dragonSize, height: dragonSize),
                    idlePhaseDelay: 0
                )

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
                AnimatedTitleCharacter(
                    label: "紫のドラゴン",
                    frames: [
                        ("MessageMonsterIdle", 1_100_000_000),
                        ("MessageMonsterMove1", 420_000_000),
                        ("MessageMonsterIdle", 800_000_000),
                        ("MessageMonsterMove1", 300_000_000)
                    ],
                    size: CGSize(width: dragonSize, height: dragonSize),
                    idlePhaseDelay: 280_000_000
                )
            }
            .frame(maxWidth: IPadLayoutMetrics.startContentWidth)
        }
    }
}

/// タイトルキャラクターの画像切り替えと、待機中の呼吸動作を行う。
struct AnimatedTitleCharacter: View {
    let label: String
    let frames: [(image: String, duration: UInt64)]
    let size: CGSize
    let idlePhaseDelay: UInt64

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var running: Bool { scenePhase == .active && !reduceMotion }

    @State private var currentImage: String

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
            .modifier(EnemyIdleMotion(kind: .dragon, intensity: 0.7,
                                      phaseOffset: Double(idlePhaseDelay) / 1_000_000_000))
            .accessibilityLabel("タイトルの\(label)キャラクター")
            .task(id: running) {
                guard running else {
                    if reduceMotion { currentImage = frames[0].image }
                    return
                }
                if idlePhaseDelay > 0 {
                    try? await Task.sleep(nanoseconds: idlePhaseDelay)
                }
                guard !Task.isCancelled else { return }
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
