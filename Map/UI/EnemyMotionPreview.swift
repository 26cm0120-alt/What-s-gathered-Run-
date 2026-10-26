import SwiftUI

#if DEBUG
/// Debug起動引数 --enemy-motion-preview で、新敵4体を同じ戦闘Viewで確認できる。
struct EnemyMotionPreview: View {
    @State private var phase = 0
    @State private var cycle = 0
    private let kinds: [EnemyKind] = [.imp, .ghost, .cyclops, .mimic]
    private let labels = ["待機・遭遇", "反撃", "被弾", "撃破"]

    var body: some View {
        VStack(spacing: 12) {
            Text("新しい敵のモーション")
                .font(DungeonTypography.maruMonica(size: 22))
            Text(labels[phase]).font(DungeonTypography.maruMonica(size: 16))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(kinds, id: \.self) { kind in
                    EnemyMotionPreviewCard(kind: kind, phase: phase)
                        .id("\(kind)-\(cycle)")
                }
            }
            Button("次のモーション") {
                if phase == 3 { cycle += 1 }
                phase = (phase + 1) % 4
            }
            .buttonStyle(.borderedProminent)
            Text("待機 → 反撃 → 被弾 → 撃破（自動再生）")
                .font(.caption)
        }
        .padding()
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DungeonBackground())
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard !Task.isCancelled else { return }
                if phase == 3 { cycle += 1 }
                phase = (phase + 1) % 4
            }
        }
    }
}

private struct EnemyMotionPreviewCard: View {
    let kind: EnemyKind
    let phase: Int
    @State private var hp = 20
    @State private var counterID = 0
    @State private var defeatID = 0

    var body: some View {
        VStack(spacing: 4) {
            Text(kind.name).font(DungeonTypography.maruMonica(size: 16))
            Text(phase == 3 ? kind.defeatDialogue : kind.encounterDialogue)
                .font(DungeonTypography.maruMonica(size: 10))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .frame(height: 54)
            EnemyBattleView(
                battle: EnemyBattle(kind: kind, enemyPosition: GridPos(x: 0, y: 0),
                                   retreatPosition: GridPos(x: 0, y: 1), enemyHP: hp),
                playerHP: 20, playerAttackAnimationID: 0,
                counterAttackAnimationID: counterID, defeatRecoilAnimationID: defeatID
            )
            .frame(height: IPadLayoutMetrics.isPad ? 240 : 175)
        }
        .padding(8)
        .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
        .onChangeCompat(of: phase) { _, next in
            if next == 1 { counterID += 1 }
            if next == 2 { hp -= 5 }
            if next == 3 { defeatID += 1 }
        }
    }
}

#Preview { EnemyMotionPreview() }
#endif
