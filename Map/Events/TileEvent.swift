import Foundation

/// マスに入るときの特殊処理の入口(A担当)。
/// B・C は、この入口に従って Trap.swift / Key.swift を実装する。
protocol TileEvent {
    /// このマスに入れない場合、その理由(画面に出すメッセージ)を返す。入れるなら nil
    func blockReason(state: GameState) -> String?

    /// このマスに入った直後の処理。ゲームの状態を変更してよい
    func onEnter(state: inout GameState)
}

extension TileEvent {
    func blockReason(state: GameState) -> String? { nil }
    func onEnter(state: inout GameState) {}
}

/// マスの種類と処理の対応表
enum TileEvents {
    static func event(for cell: MapCell) -> (any TileEvent)? {
        switch cell {
        case .trap: return TrapEvent()
        case .key:  return KeyEvent()
        case .goal: return GoalEvent()
        case .wall, .floor, .start: return nil
        }
    }
}
