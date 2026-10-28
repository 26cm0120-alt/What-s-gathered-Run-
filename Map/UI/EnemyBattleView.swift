import SwiftUI

/// 戦闘中のダンジョン表示には敵だけを重ねる。
struct EnemyBattleView: View {
    let battle: EnemyBattle
    let playerHP: Int
    let playerAttackAnimationID: Int
    let counterAttackAnimationID: Int
    let defeatRecoilAnimationID: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDefeated = false
    @State private var isCountering = false
    @State private var isHit = false
    @State private var enemyOffset: CGFloat = 0
    /// 浮遊・跳躍・踏み込みなど、敵ごとの縦方向の動き(上がマイナス)。
    @State private var enemyLift: CGFloat = 0
    /// デビル・アイの目からのビーム。0=なし、1=溜め(目が光る)、2=発射。
    @State private var beamPhase = 0
    @State private var beamExtent: CGFloat = 0
    @State private var enemyHitTilt = 0.0
    @State private var damageLabel: String?
    @State private var damageLabelOffset: CGFloat = 12
    @State private var hitTask: Task<Void, Never>?
    @State private var counterTask: Task<Void, Never>?
    @State private var mageHitJumpOffset: CGFloat = 0
    @State private var mageHitTask: Task<Void, Never>?

    private var enemyImage: String {
        if isDefeated { return battle.kind.defeatedImageName }
        if isCountering { return battle.kind.attackImageName }
        if isHit { return battle.kind.hitImageName }
        return battle.kind.imageName
    }

    /// IMPの後方に配置するメイジの画像。ほかの敵では表示しない。
    private var mageImage: String {
        if isDefeated { return "MgDefeated" }
        if isCountering { return "MgAttack" }
        if isHit { return "MgHit" }
        return "DungeonMg"
    }

    /// 敵の表示サイズ。iPadでは動きが見やすいよう大きくする(下端の操作ボタンと重ならない範囲)。
    private func enemySize(in size: CGSize) -> CGSize {
        if IPadLayoutMetrics.isPad {
            return CGSize(width: min(size.width * 0.62, 340), height: min(size.height * 0.60, 340))
        }
        return CGSize(width: min(size.width * 0.62, 190), height: min(size.height * 0.76, 190))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(enemyImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: enemySize(in: geometry.size).width, height: enemySize(in: geometry.size).height)
                    .overlay {
                        Image(enemyImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: enemySize(in: geometry.size).width, height: enemySize(in: geometry.size).height)
                            .colorMultiply(Color(red: 1.0, green: 0.08, blue: 0.06))
                            .opacity(isHit ? 0.98 : 0)
                            .animation(.easeOut(duration: 0.06), value: isHit)
                    }
                    .overlay { eyeBeamOverlay(enemySize: enemySize(in: geometry.size)) }
                    .modifier(EnemyIdleMotion(kind: battle.kind, enabled: !isHit && !isCountering && !isDefeated))
                    .offset(x: enemyOffset, y: (isDefeated ? 30 : 0) + enemyLift)
                    .scaleEffect(isDefeated ? 0.85 : isHit ? 1.06 : (isCountering ? 1.08 : 1))
                    .rotationEffect(.degrees(isHit ? enemyHitTilt : (enemyOffset == 0 ? 0 : 5)))
                    .shadow(
                        color: isHit ? Color(red: 0.98, green: 0.12, blue: 0.08).opacity(0.95) : .black.opacity(0.72),
                        radius: isHit ? 17 : 12,
                        y: 6
                    )
                    .animation(.easeOut(duration: 0.08), value: isHit)
                    .position(
                        x: geometry.size.width * (battle.kind == .imp && !isDefeated ? 0.40 : 0.5),
                        y: geometry.size.height * (IPadLayoutMetrics.isPad ? 0.52 : 0.57)
                    )
                    .zIndex(battle.kind == .imp ? 1 : 0)
                    .accessibilityLabel(battle.kind.name)

                if battle.kind == .imp {
                    Image(mageImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: enemySize(in: geometry.size).width * 0.65,
                            height: enemySize(in: geometry.size).height * 0.65
                        )
                        .offset(y: isDefeated ? 0 : mageHitJumpOffset)
                        .position(
                            x: geometry.size.width * (isDefeated ? 0.82 : 0.79),
                            y: geometry.size.height * (IPadLayoutMetrics.isPad ? 0.43 : 0.47)
                        )
                        .animation(.easeOut(duration: 0.12), value: isDefeated)
                        .zIndex(0)
                        .accessibilityLabel("メイジ")
                }

                if isCountering {
                    Text("\(battle.kind.name)の\(battle.kind.counterattackName)！")
                        .font(DungeonTypography.maruMonica(size: 16))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.9), in: RoundedRectangle(cornerRadius: 6))
                        .frame(maxWidth: geometry.size.width - 12)
                        .position(x: geometry.size.width * 0.5, y: geometry.size.height * (battle.kind == .imp ? 0.93 : 0.18))
                        .accessibilityAddTraits(.updatesFrequently)
                }

                if let damageLabel {
                    Text(damageLabel)
                        .font(DungeonTypography.maruMonica(size: 26))
                        .foregroundStyle(Color(red: 1.0, green: 0.83, blue: 0.24))
                        .shadow(color: Color(red: 0.98, green: 0.12, blue: 0.08), radius: 7)
                        .shadow(color: .black, radius: 3, y: 2)
                        .offset(y: damageLabelOffset - 12)
                        .position(x: geometry.size.width * (battle.kind == .imp ? 0.40 : 0.5), y: geometry.size.height * (battle.kind == .imp ? (IPadLayoutMetrics.isPad ? 0.80 : 0.85) : (IPadLayoutMetrics.isPad ? 0.78 : 0.88)))
                        .zIndex(battle.kind == .imp ? 2 : 0)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
        .onChangeCompat(of: battle.enemyHP) { oldHP, newHP in
            guard newHP < oldHP else { return }
            playHitReaction(damage: oldHP - newHP)
        }
        .onChangeCompat(of: counterAttackAnimationID) { _, _ in
            playCounterReaction()
        }
        .onChangeCompat(of: defeatRecoilAnimationID) { _, _ in
            playDefeatRecoil()
        }
        .onDisappear {
            hitTask?.cancel()
            counterTask?.cancel()
            mageHitTask?.cancel()
            beamPhase = 0
            beamExtent = 0
        }
    }

    /// 目の位置(画像の中央やや上)から、画面手前(下)へ広がりながら伸びるビーム。
    @ViewBuilder
    private func eyeBeamOverlay(enemySize size: CGSize) -> some View {
        if battle.kind == .cyclops && beamPhase > 0 {
            let displayedHeight = min(size.height, size.width / 1.397)
            let eye = CGPoint(x: size.width * 0.5, y: size.height * 0.5 - displayedHeight * 0.19)
            let length = size.height * 1.5
            let glowRadius = size.width * (beamPhase == 1 ? 0.16 : 0.26)
            ZStack {
                if beamPhase == 2 {
                    EyeBeamShape(origin: eye, length: length, startWidth: size.width * 0.16,
                                 endWidth: size.width * 0.62, extent: beamExtent)
                        .fill(Color(red: 1.0, green: 0.12, blue: 0.05).opacity(0.85))
                        .blur(radius: 3)
                    EyeBeamShape(origin: eye, length: length, startWidth: size.width * 0.10,
                                 endWidth: size.width * 0.36, extent: beamExtent)
                        .fill(Color(red: 1.0, green: 0.82, blue: 0.2))
                    EyeBeamShape(origin: eye, length: length, startWidth: size.width * 0.04,
                                 endWidth: size.width * 0.14, extent: beamExtent)
                        .fill(.white)
                }
                Circle()
                    .fill(RadialGradient(
                        colors: [.white, Color(red: 1.0, green: 0.7, blue: 0.15), Color(red: 1.0, green: 0.2, blue: 0.05).opacity(0)],
                        center: .center, startRadius: 0, endRadius: glowRadius))
                    .frame(width: glowRadius * 2, height: glowRadius * 2)
                    .position(eye)
                    .animation(.easeOut(duration: 0.18), value: beamPhase)
            }
            .frame(width: size.width, height: size.height)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private func playHitReaction(damage: Int) {
        if battle.kind == .imp {
            mageHitTask?.cancel()
            mageHitTask = Task { @MainActor in
                withAnimation(.spring(response: 0.18, dampingFraction: 0.48)) {
                    mageHitJumpOffset = -28
                }
                try? await Task.sleep(nanoseconds: 220_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.24, dampingFraction: 0.7)) {
                    mageHitJumpOffset = 0
                }
                mageHitTask = nil
            }
        }
        hitTask?.cancel()
        hitTask = Task { @MainActor in
            damageLabel = "−\(damage)"
            damageLabelOffset = 12
            isHit = true
            withAnimation(.easeOut(duration: 0.12)) {
                damageLabelOffset = -18
            }
            await playImpactMotion(recoil: 18)
            guard !Task.isCancelled else { return }
            isHit = false
            try? await Task.sleep(nanoseconds: 360_000_000)
            guard !Task.isCancelled else { return }
            damageLabel = nil
            hitTask = nil
        }
    }

    /// 赤い閃光と短い左右の反動で、敵の被弾をレトロなヒット演出にする。
    @MainActor
    private func playImpactMotion(recoil: CGFloat) async {
        withAnimation(.easeOut(duration: 0.055)) {
            enemyOffset = -recoil
            enemyHitTilt = -5
            enemyLift = Self.hitLift(for: battle.kind)
        }
        try? await Task.sleep(nanoseconds: 55_000_000)
        guard !Task.isCancelled else { return }

        withAnimation(.linear(duration: 0.05)) {
            enemyOffset = recoil * 0.65
            enemyHitTilt = 4
        }
        try? await Task.sleep(nanoseconds: 50_000_000)
        guard !Task.isCancelled else { return }

        withAnimation(.linear(duration: 0.05)) {
            enemyOffset = -recoil * 0.3
            enemyHitTilt = -2
        }
        try? await Task.sleep(nanoseconds: 50_000_000)
        guard !Task.isCancelled else { return }

        withAnimation(.spring(response: 0.12, dampingFraction: 0.62)) {
            enemyOffset = 0
            enemyHitTilt = 0
            enemyLift = 0
        }
        try? await Task.sleep(nanoseconds: 120_000_000)
    }

    /// 撃破確定前に、赤い被弾表現を伴う最後ののけぞりを再生する。
    private func playDefeatRecoil() {
        hitTask?.cancel()
        hitTask = Task { @MainActor in
            isHit = true
            await playImpactMotion(recoil: 24)
            guard !Task.isCancelled else { return }
            isHit = false
            withAnimation(.easeOut(duration: 0.05)) { isDefeated = true }
            hitTask = nil
        }
    }

    /// 被弾でのけぞった時の縦の動き。ゴーストは浮き上がり、ミミックは跳ね、デビル・アイは重く動かない。
    private static func hitLift(for kind: EnemyKind) -> CGFloat {
        switch kind {
        case .ghost: -12
        case .mimic: -10
        default: 0
        }
    }

    /// 反撃の予備動作と攻撃の横・縦の動き。ゴーストは浮いて急降下、デビル・アイはその場で踏ん張り目からビーム、ミミックは跳びつく。
    private static func counterMotion(for kind: EnemyKind) -> (windupX: CGFloat, windupLift: CGFloat, strikeX: CGFloat, strikeLift: CGFloat) {
        switch kind {
        case .ghost: (-8, -18, 12, 12)
        case .cyclops: (0, -4, 0, 2)   // 踏ん張って目からビームを撃つので、体は動かさない
        case .mimic: (-8, -24, 12, 8)
        default: (-8, 0, 12, 0)
        }
    }

    private func playCounterReaction() {
        counterTask?.cancel()
        let motion = Self.counterMotion(for: battle.kind)
        counterTask = Task { @MainActor in
            isCountering = true
            if battle.kind == .cyclops {
                beamExtent = 0
                beamPhase = 1
            }
            withAnimation(.easeOut(duration: 0.18)) {
                enemyOffset = motion.windupX
                enemyLift = motion.windupLift
            }
            try? await Task.sleep(nanoseconds: EnemyCounterattackTiming.windupNanoseconds)
            guard !Task.isCancelled else { return }
            if battle.kind == .cyclops {
                beamPhase = 2
                withAnimation(.easeIn(duration: 0.14)) { beamExtent = 1 }
            }
            withAnimation(.easeIn(duration: EnemyCounterattackTiming.travelDuration)) {
                enemyOffset = motion.strikeX
                enemyLift = motion.strikeLift
            }
            try? await Task.sleep(nanoseconds: EnemyCounterattackTiming.travelNanoseconds)
            guard !Task.isCancelled else { return }
            beamPhase = 0
            beamExtent = 0
            withAnimation(.easeOut(duration: 0.18)) {
                enemyOffset = 0
                enemyLift = 0
            }
            try? await Task.sleep(nanoseconds: EnemyCounterattackTiming.recoveryNanoseconds)
            guard !Task.isCancelled else { return }
            isCountering = false
            counterTask = nil
        }
    }

}

struct EnemyEncounterSpeechOverlay: View {
    let speech: EnemyEncounterSpeech
    let showEnemySprite: Bool

    var body: some View {
        VStack(spacing: 4) {
            EnemySpeechBubbleView(text: speech.message)
                .padding(.horizontal, 8)

            if showEnemySprite {
                Image(speech.kind.imageName)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: IPadLayoutMetrics.isPad ? 120 : 72, height: IPadLayoutMetrics.isPad ? 120 : 72)
                    .shadow(color: .black.opacity(0.8), radius: 5, y: 3)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, IPadLayoutMetrics.isPad ? 14 : 8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .allowsHitTesting(false)
    }
}

struct EnemyDefeatSpeechOverlay: View {
    let speech: EnemyDefeatSpeech

    var body: some View {
        VStack(spacing: 4) {
            EnemySpeechBubbleView(text: speech.message)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, IPadLayoutMetrics.isPad ? 14 : 8)
        .transition(.scale.combined(with: .opacity))
        .allowsHitTesting(false)
    }
}

private struct EnemySpeechBubbleView: View {
    let text: String

    /// iPadでは、ダンジョン画面が大きいぶん、セリフを読みやすく大きく表示する。
    private var isPad: Bool { IPadLayoutMetrics.isPad }

    var body: some View {
        Text(text)
            .font(DungeonTypography.maruMonica(size: isPad ? 22 : 14))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.82)
            .lineSpacing(isPad ? 4 : 2)
            .padding(.horizontal, isPad ? 18 : 10)
            .padding(.vertical, isPad ? 12 : 8)
            .background(Color.black.opacity(0.94), in: RoundedRectangle(cornerRadius: isPad ? 12 : 8))
            .overlay(RoundedRectangle(cornerRadius: isPad ? 12 : 8).stroke(Color(red: 0.78, green: 0.66, blue: 0.38), lineWidth: isPad ? 2 : 1.5))
            .shadow(color: .black.opacity(0.75), radius: 6, y: 3)
    }
}

/// デビル・アイの目から手前へ広がりながら伸びるビームの形。extent(0〜1)で長さと太さが変わる。
private struct EyeBeamShape: Shape {
    var origin: CGPoint
    var length: CGFloat
    var startWidth: CGFloat
    var endWidth: CGFloat
    var extent: CGFloat

    var animatableData: CGFloat {
        get { extent }
        set { extent = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let reach = length * extent
        let width = startWidth + (endWidth - startWidth) * extent
        path.move(to: CGPoint(x: origin.x - startWidth / 2, y: origin.y))
        path.addLine(to: CGPoint(x: origin.x + startWidth / 2, y: origin.y))
        path.addLine(to: CGPoint(x: origin.x + width / 2, y: origin.y + reach))
        path.addLine(to: CGPoint(x: origin.x - width / 2, y: origin.y + reach))
        path.closeSubpath()
        return path
    }
}
