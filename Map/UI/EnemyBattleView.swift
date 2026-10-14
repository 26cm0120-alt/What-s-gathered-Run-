import SwiftUI

/// 敵マスへ入ったときに表示するターン制バトル画面。
struct EnemyBattleView: View {
    let battle: EnemyBattle
    let playerHP: Int
    let onAttack: () -> Void
    let onFlee: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.86).ignoresSafeArea()

            VStack(spacing: 16) {
                Text("ENCOUNTER")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .tracking(3)
                    .foregroundStyle(Color(red: 0.95, green: 0.72, blue: 0.35))

                HStack(alignment: .center, spacing: 24) {
                    combatant(image: "PlayerIdle", name: "あなた")
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                    combatant(image: "MessageMonsterIdle", name: "モンスター")
                }

                VStack(spacing: 12) {
                    hpBar(name: "あなた", current: playerHP, maximum: GameState.playerMaxHP, color: .green)
                    hpBar(name: "敵", current: battle.enemyHP, maximum: EnemyBattle.enemyMaxHP, color: .red)
                }

                Text(battle.message)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .padding(.horizontal, 8)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 12) {
                    Button(action: onAttack) {
                        Label("攻撃", systemImage: "bolt.fill")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(DungeonPressButtonStyle())

                    Button(action: onFlee) {
                        Label("逃げる", systemImage: "figure.run")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(DungeonPressButtonStyle())
                }
            }
            .padding(22)
            .frame(maxWidth: 360)
            .background(Color(red: 0.055, green: 0.045, blue: 0.065))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 0.76, green: 0.62, blue: 0.35), lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.65), radius: 22, y: 8)
            .padding(20)
        }
        .accessibilityAddTraits(.isModal)
    }

    private func combatant(image: String, name: String) -> some View {
        VStack(spacing: 6) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 94, height: 92)
            Text(name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.86))
        }
        .frame(maxWidth: .infinity)
    }

    private func hpBar(name: String, current: Int, maximum: Int, color: Color) -> some View {
        VStack(spacing: 5) {
            HStack {
                Text("\(name) HP")
                Spacer()
                Text("\(current) / \(maximum)").monospacedDigit()
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white.opacity(0.9))

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(color.gradient)
                        .frame(width: geometry.size.width * CGFloat(max(0, current)) / CGFloat(maximum))
                }
            }
            .frame(height: 11)
        }
    }
}
