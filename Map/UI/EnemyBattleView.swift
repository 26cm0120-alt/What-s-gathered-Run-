import SwiftUI

/// 戦闘中のダンジョン表示には敵だけを重ねる。
struct EnemyBattleView: View {
    let battle: EnemyBattle
    let playerHP: Int

    @State private var isBreathing = false
    @State private var isCountering = false
    @State private var isHit = false
    @State private var enemyOffset: CGFloat = 0
    @State private var damageLabel: String?
    @State private var damageLabelOffset: CGFloat = 12
    @State private var hitTask: Task<Void, Never>?
    @State private var counterTask: Task<Void, Never>?

    private var enemyImage: String {
        if isCountering { return battle.kind == .dragon ? "MessageMonsterMove1" : battle.kind.imageName }
        if isHit { return battle.kind == .dragon ? "MessageMonsterMove2" : battle.kind.imageName }
        if battle.kind == .dragon && isBreathing { return "MessageMonsterBreath" }
        return battle.kind.imageName
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(enemyImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: min(geometry.size.width * 0.62, 190),
                        height: min(geometry.size.height * 0.76, 190)
                    )
                    .overlay {
                        Rectangle()
                            .fill(Color(red: 0.95, green: 0.16, blue: 0.12).opacity(isHit ? 0.62 : 0))
                            .animation(.easeOut(duration: 0.07), value: isHit)
                    }
                    .offset(x: enemyOffset, y: isBreathing && enemyOffset == 0 ? -3 : 0)
                    .scaleEffect(isHit ? 0.84 : (isBreathing && enemyOffset == 0 ? 1.035 : (isCountering ? 1.08 : 1)))
                    .rotationEffect(.degrees(isHit ? -8 : (enemyOffset == 0 ? 0 : 5)))
                    .shadow(
                        color: isHit ? Color.red.opacity(0.95) : .black.opacity(0.72),
                        radius: isHit ? 22 : 12,
                        y: 6
                    )
                    .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.57)
                    .accessibilityLabel(battle.kind.name)

                if let damageLabel {
                    Text(damageLabel)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.83, blue: 0.24))
                        .shadow(color: .red, radius: 8)
                        .shadow(color: .black, radius: 3, y: 2)
                        .offset(y: damageLabelOffset - 42)
                        .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.36)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 640_000_000)
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.5)) { isBreathing.toggle() }
            }
        }
        .onChange(of: battle.enemyHP) { oldHP, newHP in
            guard newHP < oldHP else { return }
            playHitReaction(damage: oldHP - newHP)
        }
        .onChange(of: playerHP) { oldHP, newHP in
            guard newHP < oldHP else { return }
            playCounterReaction()
        }
        .onDisappear {
            hitTask?.cancel()
            counterTask?.cancel()
        }
    }

    private func playHitReaction(damage: Int) {
        hitTask?.cancel()
        hitTask = Task { @MainActor in
            damageLabel = "−\(damage)"
            damageLabelOffset = 12
            isHit = true
            withAnimation(.spring(response: 0.09, dampingFraction: 0.38)) {
                enemyOffset = -14
                damageLabelOffset = -18
            }
            try? await Task.sleep(nanoseconds: 190_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.15)) { enemyOffset = 0 }
            isHit = false
            try? await Task.sleep(nanoseconds: 360_000_000)
            guard !Task.isCancelled else { return }
            damageLabel = nil
            hitTask = nil
        }
    }

    private func playCounterReaction() {
        counterTask?.cancel()
        counterTask = Task { @MainActor in
            // ダメージ表示と赤い被弾演出が終わってから、敵の反撃動作を続ける。
            try? await Task.sleep(nanoseconds: 560_000_000)
            guard !Task.isCancelled else { return }
            isCountering = true
            withAnimation(.easeOut(duration: 0.12)) { enemyOffset = 18 }
            try? await Task.sleep(nanoseconds: 170_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.16)) { enemyOffset = 0 }
            try? await Task.sleep(nanoseconds: 100_000_000)
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
                    .frame(width: 72, height: 72)
                    .shadow(color: .black.opacity(0.8), radius: 5, y: 3)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .allowsHitTesting(false)
    }
}

struct EnemyDefeatSpeechOverlay: View {
    let speech: EnemyDefeatSpeech

    var body: some View {
        VStack(spacing: -2) {
            EnemySpeechBubbleView(text: speech.message)
                .padding(.horizontal, 8)

            Image(speech.kind.imageName)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .rotationEffect(.degrees(90))
                .shadow(color: .black.opacity(0.8), radius: 5, y: 3)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 8)
        .transition(.scale.combined(with: .opacity))
        .allowsHitTesting(false)
    }
}

private struct EnemySpeechBubbleView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.94), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.78, green: 0.66, blue: 0.38), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.75), radius: 6, y: 3)
    }
}
