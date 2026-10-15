import SwiftUI

/// 状況メッセージの横にPlayerを表示し、HPを常時確認できるようにする。
struct MonsterMessageView: View {
    let message: String
    let reactionID: Int
    let surpriseReactionID: Int
    let isTrapReactionActive: Bool
    let trapAnimationFrame: String
    let trapAnimationOffset: CGFloat
    let trapAnimationTilt: Double
    let wallCollisionID: Int
    let playerAttackAnimationID: Int
    let battle: EnemyBattle?
    let playerHP: Int
    let isTutorial: Bool

    @State private var isBreathing = false
    @State private var actionFrame: String?
    @State private var reactionTask: Task<Void, Never>?
    @State private var collisionShakeOffset: CGFloat = 0
    @State private var collisionTilt: Double = 0
    @State private var isSurprised = false
    @State private var isCrying = false
    @State private var attackOffset: CGFloat = 0

    private var imageName: String {
        if battle != nil {
            return "DungeonPlayer"
        }
        if isTrapReactionActive { return trapAnimationFrame }
        if isSurprised || isCrying { return "PlayerBlink" }
        return actionFrame ?? (isBreathing ? "PlayerBreath" : "PlayerIdle")
    }

    private var currentMessage: String {
        battle?.message ?? message
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 5) {
                Text(currentMessage)
                    .font(.system(size: battle == nil ? 15 : 13, weight: .medium, design: battle == nil ? .default : .monospaced))
                    .foregroundStyle(.white)
                    .lineLimit(isTutorial && battle == nil ? 3 : 2)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 9) {
                    hpBar(name: battle == nil ? "HP" : "YOU", current: playerHP, maximum: GameState.playerMaxHP, color: Color(red: 0.28, green: 0.82, blue: 0.48))
                    if let battle {
                        hpBar(name: battle.kind.name, current: battle.enemyHP, maximum: battle.kind.maxHP, color: Color(red: 0.95, green: 0.31, blue: 0.24))
                    }
                }
            }

            ZStack(alignment: .topTrailing) {
                Image(imageName)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 76)
                    .offset(x: isTrapReactionActive ? trapAnimationOffset : collisionShakeOffset + attackOffset)
                    .scaleEffect(battle != nil ? (attackOffset == 0 ? (isBreathing ? 1.04 : 1) : 1.12) : 1)
                    .rotationEffect(.degrees(isTrapReactionActive ? trapAnimationTilt : collisionTilt))
                    .accessibilityHidden(true)
                    .animation(.easeInOut(duration: 0.08), value: imageName)

                if isTrapReactionActive {
                    Text("！？")
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.24))
                        .shadow(color: .black, radius: 2, y: 1)
                        .offset(x: -1, y: 0)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityHidden(true)
                } else if battle != nil {
                    Text("!")
                        .font(.system(size: 23, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.79, blue: 0.22))
                        .shadow(color: .black, radius: 2, y: 1)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityHidden(true)
                } else if isSurprised {
                    Text("!")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.24))
                        .shadow(color: .black, radius: 2, y: 1)
                        .offset(x: -3, y: 1)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityHidden(true)
                }
                if isCrying {
                    HStack(spacing: 22) {
                        tearDrop.rotationEffect(.degrees(18)).offset(y: 3)
                        tearDrop.rotationEffect(.degrees(-18)).offset(y: 1)
                    }
                    .offset(x: -18, y: 44)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityHidden(true)
                }
                if isTrapReactionActive {
                    HStack(spacing: 26) {
                        tearDrop.rotationEffect(.degrees(18)).offset(y: 7)
                        tearDrop.rotationEffect(.degrees(-18)).offset(y: 2)
                    }
                    .offset(x: -18, y: 43)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityHidden(true)
                }
            }
            .frame(width: 70, height: 78)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(Color(red: 0.075, green: 0.07, blue: 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.42, green: 0.39, blue: 0.32), lineWidth: 1)
        }
        .onChange(of: reactionID) { _, _ in
            playMovementAnimation()
        }
        .onChange(of: surpriseReactionID) { _, _ in
            playSurpriseAnimation()
        }
        .onChange(of: playerAttackAnimationID) { _, _ in
            playBattleAttackAnimation()
        }
        .onChange(of: wallCollisionID) { _, _ in
            playWallCollisionReaction()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 750_000_000)
                guard !Task.isCancelled else { break }
                isBreathing.toggle()
            }
        }
        .onDisappear {
            reactionTask?.cancel()
        }
    }

    private var tearDrop: some View {
        Image(systemName: "drop.fill")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Color(red: 0.35, green: 0.78, blue: 1.0))
            .shadow(color: .black.opacity(0.8), radius: 2, y: 1)
    }

    private func hpBar(name: String?, current: Int, maximum: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                if let name {
                    Text(name).lineLimit(1).minimumScaleFactor(0.65)
                }
                Spacer(minLength: 1)
                Text("\(current)/\(maximum)").monospacedDigit()
            }
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.92))
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.white.opacity(0.18))
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(max(0, current)) / CGFloat(maximum))
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
    }

    private func playMovementAnimation() {
        guard !isTrapReactionActive else { return }
        reactionTask?.cancel()
        isSurprised = false
        isCrying = false
        collisionShakeOffset = 0
        collisionTilt = 0
        reactionTask = Task { @MainActor in
            for frame in ["PlayerMove1", "PlayerMove2", "PlayerMove3"] {
                guard !Task.isCancelled else { return }
                actionFrame = frame
                try? await Task.sleep(nanoseconds: 110_000_000)
            }
            guard !Task.isCancelled else { return }
            actionFrame = nil
        }
    }

    private func playSurpriseAnimation() {
        reactionTask?.cancel()
        isCrying = false
        reactionTask = Task { @MainActor in
            isSurprised = true
            let reactions: [(CGFloat, Double, String)] = [
                (-6, -11, "PlayerBlink"),
                (7, 9, "PlayerIdle"),
                (-4, -6, "PlayerBlink"),
                (2, 3, "PlayerIdle"),
                (0, 0, "PlayerBlink")
            ]

            for (offset, tilt, frame) in reactions {
                guard !Task.isCancelled else { return }
                actionFrame = frame
                withAnimation(.spring(response: 0.075, dampingFraction: 0.48)) {
                    collisionShakeOffset = offset
                    collisionTilt = tilt
                }
                try? await Task.sleep(nanoseconds: 85_000_000)
            }

            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.18, dampingFraction: 0.62)) {
                collisionShakeOffset = 0
                collisionTilt = 0
                isSurprised = false
            }
            actionFrame = nil
        }
    }

    private func playBattleAttackAnimation() {
        guard battle != nil else { return }
        reactionTask?.cancel()
        reactionTask = Task { @MainActor in
            withAnimation(.spring(response: 0.12, dampingFraction: 0.48)) {
                attackOffset = -19
            }
            try? await Task.sleep(nanoseconds: 345_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.17, dampingFraction: 0.58)) { attackOffset = 0 }
            reactionTask = nil
        }
    }

    private func playWallCollisionReaction() {
        reactionTask?.cancel()
        reactionTask = Task { @MainActor in
            isCrying = true
            isSurprised = false
            actionFrame = "PlayerBlink"
            for offset in [CGFloat(-5), 5, -3, 0] {
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.08, dampingFraction: 0.5)) {
                    collisionShakeOffset = offset
                    collisionTilt = offset == 0 ? 0 : Double(offset) * 1.4
                }
                try? await Task.sleep(nanoseconds: 90_000_000)
            }
            guard !Task.isCancelled else { return }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.18)) {
                isCrying = false
                collisionShakeOffset = 0
                collisionTilt = 0
            }
            actionFrame = nil
        }
    }
}
