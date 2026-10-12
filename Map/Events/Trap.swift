import Foundation

/// 向きを180度反転する
struct TrapEvent: TileEvent {
    func onEnter(state: inout GameState) {
        state.player.direction = state.player.direction.reversed
        state.message = "トラップ! 向きが反転した"
        // テスト
    }
}
