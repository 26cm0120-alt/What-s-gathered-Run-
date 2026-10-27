import SwiftUI

#if DEBUG
/// 実際の床描画と大小マップで、全8体の撃破素材を同時に確認する。
struct EnemyRemainsPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("撃破後の床・通常マップ・拡大マップ")
                    .font(DungeonTypography.maruMonica(size: 18))
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(EnemyKind.allCases, id: \.self) { kind in
                        EnemyRemainsPreviewCard(kind: kind)
                    }
                }
            }
            .padding()
        }
        .foregroundStyle(.white)
        .background(DungeonBackground())
    }
}

private struct EnemyRemainsPreviewCard: View {
    let kind: EnemyKind
    private let enemy = GridPos(x: 1, y: 0)
    private var map: MapData {
        MapData(cells: [[.start, .enemy, .floor]], startPosition: GridPos(x: 0, y: 0),
                initialDirection: .east, enemyKinds: [enemy: kind])
    }
    private var player: Player { Player(position: GridPos(x: 0, y: 0), direction: .east) }
    private var explored: Set<GridPos> { Set((0..<3).map { GridPos(x: $0, y: 0) }) }

    var body: some View {
        VStack(spacing: 5) {
            Text(kind.name).font(DungeonTypography.maruMonica(size: 14))
            DungeonView(map: map, player: player, theme: nil, hasKey: false, isGoalReached: false,
                        defeatedEnemyKinds: [enemy: kind], largeDefeatGraphicPosition: nil, activatedTrapPositions: [])
                .frame(height: 90)
            mapView.frame(height: 22)
            mapView.frame(height: 40)
        }
        .padding(6)
        .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    private var mapView: some View {
        AutoMapView(map: map, explored: explored, player: player, defeatedEnemies: [enemy],
                    defeatedEnemyKinds: [enemy: kind], activatedTrapPositions: [])
    }
}
#endif
