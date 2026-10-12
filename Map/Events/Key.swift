import Foundation

/// K:鍵・宝箱(C担当)。取得すると hasKey が true になる
struct KeyEvent: TileEvent {
    func onEnter(state: inout GameState) {
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

/// G:ゴール(C担当)。鍵が必要な面では、鍵がないと入れない
struct GoalEvent: TileEvent {
    func blockReason(state: GameState) -> String? {
        // 鍵が必要な面で、鍵を持っていないときだけ入れない
        if state.requiresKey && !state.hasKey {
            return "ゴールの扉には鍵が必要です。まず鍵を探しましょう。"
        }
        return nil
    }

    func onEnter(state: inout GameState) {
        state.isCleared = true      // クリア状態にする(仕様書§3・§11)
        state.message = "ゴール!"
    }
}
