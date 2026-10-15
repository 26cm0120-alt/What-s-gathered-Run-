import Foundation

/// E: 敵マスに入るとターン制バトルを開始する。
struct EnemyEvent: TileEvent {
    let kind: EnemyKind

    func blockReason(state: GameState) -> String? {
        // 敵マスへの進入は制限しない。剣がないガーゴイル戦では攻撃が通らず、
        // 反撃でHPが尽きると通常のゲームオーバーになる。
        nil
    }

    func onEnter(state: inout GameState, from previousPosition: GridPos) {
        state.enemyBattle = EnemyBattle(
            kind: kind,
            enemyPosition: state.player.position,
            retreatPosition: previousPosition
        )
        state.message = ""
    }
}
