import Foundation
import Combine

/// ゲーム進行の管理。UIはここを通してのみ状態を変更する(UI仕様書§8)
final class GameManager: ObservableObject {
    /// 現在の面(マップ、鍵の要否などの定義)
    let stage: Stage
    @Published private(set) var state: GameState
    @Published private(set) var isInputLocked = false
    @Published private(set) var wallCollisionID = 0
    @Published private(set) var surpriseReactionID = 0

    private var wallCollisionTask: Task<Void, Never>?
    private let soundEffects = SoundEffectController()

    /// 現在の面のマップ
    var map: MapData { stage.map }

    /// クリアしたときに呼ばれる(画面の切り替えに使う)
    var onCleared: (() -> Void)?
    /// HPが0になったときに呼ばれる(スタート画面へ戻る)
    var onGameOver: (() -> Void)?

    init(stage: Stage) {
        self.stage = stage
        self.state = GameState(
            start: stage.map.startPosition,
            direction: stage.map.initialDirection,
            requiresKey: stage.requiresKey,
            isStepByStepTutorial: stage.isStepByStepTutorial
        )
    }

    // MARK: 操作

    func turnLeft() {
        turn(to: state.player.direction.turnedLeft, tutorialAction: .turnLeft)
    }

    func turnRight() {
        turn(to: state.player.direction.turnedRight, tutorialAction: .turnRight)
    }

    func moveForward() {
        moveOneTile(
            in: state.player.direction,
            action: .moveForward,
            blockedMessage: "前方は壁です。左右に向きを変えて進路を探そう！"
        )
    }

    func turnAround() {
        turn(to: state.player.direction.reversed)
    }

    private func turn(to direction: Direction, tutorialAction: TutorialAction? = nil) {
        guard !state.isCleared, !state.isGameOver, state.enemyBattle == nil, !isInputLocked else { return }
        var newState = state
        newState.player.direction = direction
        newState.message = ""
        if let tutorialAction {
            newState.recordTutorialAction(tutorialAction)
        }
        state = newState
    }

    /// 指定した方向へ1マス進み、壁・イベント・探索済み状態をまとめて処理する。
    private func moveOneTile(in direction: Direction, action: TutorialAction, blockedMessage: String) {
        guard !state.isCleared, !state.isGameOver, state.enemyBattle == nil, !isInputLocked else { return }
        let next = state.player.position.moved(direction)
        let cell = map.cell(at: next)
        if cell.isWall {
            var newState = state
            newState.message = "\(blockedMessage) 2秒間動けません。"
            state = newState
            wallCollisionID += 1
            surpriseReactionID += 1
            soundEffects.play(named: "wall_hit")
            lockInputAfterWallCollision()
            return
        }

        // 敵を倒したマスへ戻った場合は、再戦せず通過できる。
        let event = cell == .enemy && state.defeatedEnemies.contains(next)
            ? nil
            : TileEvents.event(for: cell)
        if let reason = event?.blockReason(state: state) {
            var newState = state
            newState.message = reason
            state = newState
            return
        }

        var newState = state
        newState.player.position = next
        newState.explored.insert(next)
        newState.message = ""
        newState.recordTutorialAction(action)
        event?.onEnter(state: &newState, from: state.player.position)
        state = newState
        if cell == .trap || newState.enemyBattle != nil {
            surpriseReactionID += 1
        }

        // クリア状態になったら、画面を切り替えるために知らせる
        if newState.isCleared {
            onCleared?()
        }
    }

    /// プレイヤーの攻撃後、生存していれば敵が反撃する。
    func attackEnemy() {
        guard var battle = state.enemyBattle, !state.isCleared, !state.isGameOver else { return }

        let playerDamage = 5
        battle.enemyHP = max(0, battle.enemyHP - playerDamage)
        var newState = state

        if battle.enemyHP == 0 {
            newState.defeatedEnemies.insert(battle.enemyPosition)
            newState.enemyBattle = nil
            newState.message = "敵を倒した！探索を続けよう。"
            state = newState
            return
        }

        let enemyDamage = 4
        newState.playerHP = max(0, newState.playerHP - enemyDamage)
        if newState.playerHP == 0 {
            newState.enemyBattle = nil
            newState.isGameOver = true
            newState.message = "力尽きた……"
            state = newState
            onGameOver?()
            return
        }

        battle.message = "攻撃！敵に\(playerDamage)ダメージ。反撃で\(enemyDamage)ダメージを受けた。"
        newState.enemyBattle = battle
        state = newState
    }

    /// 逃走した場合は、敵マスへ入る直前の位置に戻る。敵はその場に残る。
    func fleeBattle() {
        guard let battle = state.enemyBattle else { return }
        var newState = state
        newState.player.position = battle.retreatPosition
        newState.enemyBattle = nil
        newState.message = "戦闘から逃げ出した。"
        state = newState
    }

    /// 壁にぶつかった後、移動と方向転換を2秒間受け付けない。
    private func lockInputAfterWallCollision() {
        wallCollisionTask?.cancel()
        isInputLocked = true
        wallCollisionTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled, let self else { return }
            self.isInputLocked = false

            var newState = self.state
            newState.message = ""
            self.state = newState
            self.wallCollisionTask = nil
        }
    }
}
