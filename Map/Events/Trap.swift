import Foundation

/// 向きを右へ90度回転する
struct TrapEvent: TileEvent {
    func onEnter(state: inout GameState, from previousPosition: GridPos) {
        state.player.direction = state.player.direction.turnedRight
        state.message = "トラップ! 向きが右に90度変わった"
        // テスト
    }
}
