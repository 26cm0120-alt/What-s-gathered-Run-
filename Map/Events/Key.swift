import Foundation

/// K:鍵・宝箱(C担当)。取得すると hasKey が true になる
struct KeyEvent: TileEvent {
    func blockReason(state: GameState) -> String? {
        guard state.requiresSwordForKey, !state.hasSword else { return nil }
        return "宝箱は固く閉ざされている。鍵を取るには剣が必要だ。"
    }

    func onEnter(state: inout GameState, from previousPosition: GridPos) {
        let alreadyHadKey = state.hasKey
        state.hasKey = true
        if !alreadyHadKey && state.tutorialStep == .findKey {
            state.tutorialStep = .reachGoal
            state.message = "鍵を手に入れた！ゴールを探そう！"
        } else {
            state.message = alreadyHadKey ? "空の宝箱がある" : "鍵を手に入れた"
        }
    }
}

/// W:強化アイテムの剣。ランダムステージで取得すると攻撃力が上がる。
struct SwordEvent: TileEvent {
    func onEnter(state: inout GameState, from previousPosition: GridPos) {
        if state.hasSword {
            state.message = "剣を装備している。"
            return
        }
        state.hasSword = true
        state.message = "剣を手に入れた！攻撃力が上がった！"
    }
}

/// G:ゴール(C担当)。鍵が必要な面では、鍵がないと入れない
struct GoalEvent: TileEvent {
    func blockReason(state: GameState) -> String? {
        // 鍵が必要な面で、鍵を持っていないときだけ入れない
        if state.requiresKey && !state.hasKey {
            return "ゴールの扉には鍵が必要です。まず鍵を探しましょう。"
        }
        return nil
    }

    func onEnter(state: inout GameState, from previousPosition: GridPos) {
        state.isCleared = true      // クリア状態にする(仕様書§3・§11)
        state.message = "ゴール!"
    }
}
