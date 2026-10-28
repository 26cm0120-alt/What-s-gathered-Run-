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
                    .modifier(EnemyIdleMotion(kind: battle.kind, enabled: !isHit && !isCountering && !isDefeated))
                    .offset(x: enemyOffset, y: isDefeated ? 30 : 0)
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
                        .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.93)
                        .accessibilityAddTraits(.updatesFrequently)
                }

                if let damageLabel {
                    Text(damageLabel)
                        .font(DungeonTypography.maruMonica(size: 26))
                        .foregroundStyle(Color(red: 1.0, green: 0.83, blue: 0.24))
                        .shadow(color: Color(red: 0.98, green: 0.12, blue: 0.08), radius: 7)
                        .shadow(color: .black, radius: 3, y: 2)
                        .offset(y: damageLabelOffset - 12)
                        .position(x: geometry.size.width * (battle.kind == .imp ? 0.40 : 0.5), y: geometry.size.height * (IPadLayoutMetrics.isPad ? 0.80 : 0.85))
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

    private func playCounterReaction() {
        counterTask?.cancel()
        counterTask = Task { @MainActor in
            isCountering = true
            withAnimation(.easeOut(duration: 0.18)) { enemyOffset = -8 }
            try? await Task.sleep(nanoseconds: EnemyCounterattackTiming.windupNanoseconds)
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: EnemyCounterattackTiming.travelDuration)) {
                enemyOffset = 12
            }
            try? await Task.sleep(nanoseconds: EnemyCounterattackTiming.travelNanoseconds)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.18)) { enemyOffset = 0 }
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
