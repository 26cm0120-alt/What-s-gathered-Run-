import Foundation

/// E: 敵マスに入るとターン制バトルを開始する。
struct EnemyEvent: TileEvent {
    func onEnter(state: inout GameState, from previousPosition: GridPos) {
        state.enemyBattle = EnemyBattle(
            enemyPosition: state.player.position,
            retreatPosition: previousPosition
        )
        state.message = ""
    }
}
