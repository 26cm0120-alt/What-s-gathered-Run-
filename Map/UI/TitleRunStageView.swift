import SwiftUI

/// タイトル画面の「走る青ドラゴン」の演出。
///
/// 左右の端に雑魚敵を1体ずつ置き、その間を青いPlayerドラゴンが往復して走る。
/// 端の敵に触れると、その敵がやられモーション→点滅→消滅し、別の雑魚敵に入れ替わる。
/// ドラゴンはそのまま反対側へ向かって走り、これを繰り返す。
struct TitleRunStageView: View {
    var compact = false

    private enum Side { case left, right }

    private struct Opponent {
        var kind: EnemyKind
        var image: String
        var opacity: Double = 1
        var isIdle = true

        init(kind: EnemyKind) {
            self.kind = kind
            self.image = kind.imageName
        }
    }

    private static let pool: [EnemyKind] = [.slime, .skeleton, .gargoyle, .imp, .ghost, .cyclops, .mimic]
    private static let runFrames = ["PlayerMove1", "PlayerMove2"]

    @State private var left = Opponent(kind: .slime)
    @State private var right = Opponent(kind: .skeleton)
    /// 0=左の敵に触れる位置、1=右の敵に触れる位置
    @State private var progress: CGFloat = 0
    @State private var facingRight = true
    @State private var playerImage = "PlayerIdle"
    @State private var isStepUp = false

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var running: Bool { scenePhase == .active && !reduceMotion }

    private var isPad: Bool { IPadLayoutMetrics.isPad }
    private var enemySize: CGFloat { isPad ? 88 : (compact ? 40 : 56) }
    private var playerSize: CGFloat { enemySize * 1.05 }
    /// 触れたときに少し重なる量
    private var overlap: CGFloat { enemySize * 0.2 }
    private var stageHeight: CGFloat { enemySize + (isPad ? 14 : 8) }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let groundY = geometry.size.height
            let minX = enemySize + playerSize / 2 - overlap
            let maxX = width - enemySize - playerSize / 2 + overlap
            let playerX = minX + (maxX - minX) * progress

            ZStack(alignment: .topLeading) {
                opponentView(left, phase: 0)
                    .position(x: enemySize / 2, y: groundY - enemySize / 2)

                opponentView(right, phase: 1.6)
                    .position(x: width - enemySize / 2, y: groundY - enemySize / 2)

                Image(playerImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: playerSize, height: playerSize)
                    // 左へ走るときは左向きに反転する
                    .scaleEffect(x: facingRight ? 1 : -1, y: 1)
                    .offset(y: isStepUp ? -3 : 0)
                    .position(x: playerX, y: groundY - playerSize / 2)
            }
        }
        .frame(maxWidth: IPadLayoutMetrics.startContentWidth)
        .frame(height: stageHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("青いドラゴンが左右のモンスターを倒して走る演出")
        .task(id: running) {
            resetStage()
            guard running else { return }
            await loop()
        }
    }

    private func opponentView(_ opponent: Opponent, phase: Double) -> some View {
        Image(opponent.image)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: enemySize, height: enemySize, alignment: .bottom)
            .modifier(EnemyIdleMotion(kind: opponent.kind, enabled: opponent.isIdle,
                                      intensity: 0.65, phaseOffset: phase))
            .opacity(opponent.opacity)
    }

    // MARK: - 演出の進行

    /// 左端から右へ走り、端の敵に触れたら反対へ走る。敵のやられ演出は次の走りと並行して行う。
    private func loop() async {
        var goingRight = true
        var pendingDefeat: Side?
        while !Task.isCancelled {
            let defeatSide = pendingDefeat
            async let defeating: Void = defeat(defeatSide)
            await run(toRight: goingRight)
            await defeating
            guard !Task.isCancelled else { return }
            await touch()
            pendingDefeat = goingRight ? .right : .left
            goingRight.toggle()
        }
    }

    /// 状態を初期位置(左の敵の前・待機)へ戻す。
    private func resetStage() {
        var noAnimation = Transaction()
        noAnimation.disablesAnimations = true
        withTransaction(noAnimation) {
            progress = 0
            facingRight = true
            playerImage = "PlayerIdle"
            isStepUp = false
            left.image = left.kind.imageName
            left.opacity = 1
            left.isIdle = true
            right.image = right.kind.imageName
            right.opacity = 1
            right.isIdle = true
        }
    }

    private func run(toRight: Bool) async {
        let duration = 2.0
        let stepInterval: UInt64 = 130
        facingRight = toRight
        withAnimation(.linear(duration: duration)) { progress = toRight ? 1 : 0 }
        var index = 0
        var elapsed = 0.0
        while elapsed < duration && !Task.isCancelled {
            playerImage = Self.runFrames[index % Self.runFrames.count]
            isStepUp = index.isMultiple(of: 2)
            await pause(stepInterval)
            elapsed += Double(stepInterval) / 1000
            index += 1
        }
    }

    /// 敵に触れた瞬間のポーズ。
    private func touch() async {
        playerImage = "PlayerMove3"
        isStepUp = false
        await pause(260)
    }

    /// 被弾→やられ→点滅→消滅し、別の雑魚敵に入れ替わる。
    private func defeat(_ side: Side?) async {
        guard let side else { return }
        let kind = opponent(side).kind

        update(side) {
            $0.image = kind.hitImageName
            $0.isIdle = false
        }
        await pause(140)
        update(side) { $0.image = kind.defeatedImageName }
        await pause(320)

        for _ in 0..<3 {
            update(side) { $0.opacity = 0.15 }
            await pause(90)
            update(side) { $0.opacity = 1 }
            await pause(90)
        }
        update(side) { $0.opacity = 0 }
        await pause(150)
        guard !Task.isCancelled else { return }

        // 場に出ていない別の雑魚敵に入れ替えて、ふわっと登場させる
        let used = [left.kind, right.kind]
        let next = Self.pool.filter { !used.contains($0) }.randomElement() ?? kind
        update(side) {
            $0.kind = next
            $0.image = next.imageName
            $0.isIdle = true
            $0.opacity = 0
        }
        withAnimation(.easeIn(duration: 0.35)) {
            update(side) { $0.opacity = 1 }
        }
    }

    private func opponent(_ side: Side) -> Opponent {
        side == .left ? left : right
    }

    private func update(_ side: Side, _ change: (inout Opponent) -> Void) {
        switch side {
        case .left: change(&left)
        case .right: change(&right)
        }
    }

    private func pause(_ milliseconds: UInt64) async {
        try? await Task.sleep(nanoseconds: milliseconds * 1_000_000)
    }
}
