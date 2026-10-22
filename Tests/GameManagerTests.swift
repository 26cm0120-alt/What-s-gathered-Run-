import Foundation

/// 音声出力だけをスタブにし、移動・罠・取得ロックは実際のGameManagerで検証する。
@MainActor
enum GameManagerTests {
    private static var count = 0

    static func run() async throws -> Int {
        try testPoison()
        try testSlow()
        try await testWallDuringTraps()
        try testItemLocks()
        try testDropLocks()
        print("PASS: GameManagerの毒・遅行・壁・取得ロック (\(count) assertions)")
        return count
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        count += 1
        if !condition() { throw Failure(message: message) }
    }

    private struct Failure: Error, CustomStringConvertible {
        let message: String
        var description: String { "GameManagerテスト失敗: \(message)" }
    }

    private static func game(_ row: String) -> GameManager {
        let cells = row.map { MapCell($0) }
        let start = cells.firstIndex(of: .start)!
        let enemies = Dictionary(uniqueKeysWithValues: cells.indices.filter { cells[$0] == .enemy }.map {
            (GridPos(x: $0, y: 0), EnemyKind.skeleton)
        })
        let map = MapData(cells: [cells], startPosition: GridPos(x: start, y: 0), initialDirection: .east, enemyKinds: enemies)
        let stage = Stage(title: "テスト", map: map, requiresKey: false, isStepByStepTutorial: false,
                          seed: nil, shiritoriStageKind: .standard, dungeonTheme: nil, requiresSwordForKey: false)
        return GameManager(stage: stage, wallCollisionDamageEnabled: false)
    }

    private static func testPoison() throws {
        let g = game("SH......")
        for step in 1...5 {
            g.moveForward()
            try expect(g.state.playerHP == 20 - step, "毒は罠への進入を含む5歩で各1ダメージ")
            try expect(g.state.hpDrainTrapStepsRemaining == 5 - step, "毒の残り歩数")
            try expect(g.state.hpDrainTrapActive == (step < 5), "毒の解除境界")
        }
        g.moveForward()
        try expect(g.state.playerHP == 15, "毒解除後は減らない")

        let repeated = game("SH....")
        repeated.moveForward()
        repeated.moveForward()
        repeated.turnAround()
        repeated.moveForward()
        try expect(repeated.state.playerHP == 17 && repeated.state.hpDrainTrapStepsRemaining == 4, "再踏破は5歩へ再設定し進入分を1回消費")
        repeated.turnLeft()
        try expect(repeated.state.playerHP == 17 && repeated.state.hpDrainTrapStepsRemaining == 4, "旋回は毒を消費しない")

        let blocked = game("SHG")
        // ゴールのHP0時の優先順位も、実際の移動で再現する。
        var lost = 0
        var cleared = 0
        blocked.onGameOver = { lost += 1 }
        blocked.onCleared = { cleared += 1 }
        for _ in 0..<9 {
            blocked.moveForward()
            blocked.turnAround()
            blocked.moveForward()
            blocked.turnAround()
        }
        blocked.moveForward()
        try expect(blocked.state.playerHP == 1, "ゴール直前まで毒でHPを減らす")
        blocked.moveForward()
        try expect(blocked.state.playerHP == 0 && blocked.state.isGameOver && !blocked.state.isCleared, "毒によるHP0はゴールより敗北が優先")
        try expect(lost == 1 && cleared == 0, "敗北だけを一度通知")
        blocked.moveForward()
        try expect(lost == 1, "敗北後の入力で再通知しない")
    }

    private static func testSlow() throws {
        let g = game("SF.......")
        g.moveForward()
        try expect(g.state.doubleFlickTrapMovesRemaining == 5, "遅行を踏んだ移動では回数を減らさない")
        for move in 1...5 {
            let before = g.state.player.position
            g.moveForward()
            try expect(g.state.player.position == before && g.state.slowForwardFlickProgress == 1, "1フリックでは進まない")
            g.moveForward()
            try expect(g.state.player.position.x == before.x + 1, "2フリックで1マス")
            try expect(g.state.doubleFlickTrapMovesRemaining == 5 - move, "成功した移動だけを数える")
            try expect(g.state.doubleFlickTrapActive == (move < 5), "5マスで遅行解除")
        }
        g.moveForward()
        try expect(g.state.player.position.x == 7, "解除後は1フリックで進む")

        let repeated = game("SF....")
        repeated.moveForward()
        repeated.moveForward()
        repeated.moveForward()
        repeated.turnAround()
        repeated.moveForward()
        repeated.moveForward()
        try expect(repeated.state.doubleFlickTrapMovesRemaining == 5 && repeated.state.slowForwardFlickProgress == 0, "遅行再踏破は5マスへ再設定")
        repeated.moveForward()
        repeated.turnAround()
        repeated.moveForward()
        try expect(repeated.state.player.position.x == 2, "現在の仕様では旋回を挟んでもフリック進捗を維持")
    }

    private static func testWallDuringTraps() async throws {
        let poison = game("SH")
        let slow = game("SF")
        poison.moveForward()
        slow.moveForward()
        poison.moveForward()
        slow.moveForward()
        try expect(!slow.isInputLocked, "遅行の1回目は壁判定前")
        slow.moveForward()
        try expect(poison.isInputLocked && slow.isInputLocked, "壁で入力ロック")
        try expect(poison.state.playerHP == 19 && poison.state.hpDrainTrapStepsRemaining == 4, "壁では毒の歩数・HPが変わらない")
        try expect(slow.state.doubleFlickTrapMovesRemaining == 5 && slow.state.slowForwardFlickProgress == 0, "壁では遅行マス数を消費せずフリックだけリセット")
        poison.turnAround()
        slow.moveForward()
        try expect(poison.state.player.direction == .east && slow.state.slowForwardFlickProgress == 0, "壁ロック中は旋回・移動を拒否")
        // 固定の長い待ち時間ではなく、上限付きで実際の解除を待つ。
        let deadline = ProcessInfo.processInfo.systemUptime + 5
        while (poison.isInputLocked || slow.isInputLocked) && ProcessInfo.processInfo.systemUptime < deadline {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        try expect(!poison.isInputLocked && !slow.isInputLocked, "壁のロックは自動解除される")
        poison.turnAround()
        poison.moveForward()
        try expect(poison.state.player.position.x == 0 && poison.state.playerHP == 18, "壁ロック解除後に移動と毒処理が再開")
    }

    private static func testItemLocks() throws {
        for item in ["K", "W"] {
            for cancel in [false, true] {
                let g = game("S\(item)..")
                g.moveForward()
                try expect(g.isItemPickupInputLocked, "\(item)取得直後にモデル側でロック")
                g.moveForward()
                g.turnRight()
                g.turnLeft()
                g.turnAround()
                try expect(g.state.player.position.x == 1 && g.state.player.direction == .east, "取得中は全移動操作を拒否")
                if cancel { g.cancelItemPickupPresentation() } else { g.finishItemPickupPresentation() }
                try expect(!g.isItemPickupInputLocked, "正常終了・画面離脱で解除")
                g.moveForward()
                try expect(g.state.player.position.x == 2, "解除後に前進できる")
                g.turnAround()
                g.moveForward()
                try expect(!g.isItemPickupInputLocked, "取得済みマスで再ロックしない")
            }
        }
    }

    private static func testDropLocks() throws {
        for cancel in [false, true] {
            let g = game("SE..")
            g.moveForward()
            // 敵HPに応じた上限で攻撃し、倒せない場合も無限ループにしない。
            for _ in 0..<20 where g.state.enemyBattle != nil { g.attackEnemy() }
            try expect(g.state.enemyBattle == nil && g.pendingSkeletonDrop != nil, "スケルトン撃破でドロップ待ち")
            try expect(g.isSkeletonDropPickupInputLocked, "撃破直後からロック")
            g.moveForward()
            g.turnAround()
            try expect(g.state.player.position.x == 1 && g.state.player.direction == .east, "ドロップ待ちの入力を拒否")
            g.finishSkeletonDropPickupPresentation()
            try expect(g.isSkeletonDropPickupInputLocked, "未回収のまま早期解除しない")
            if cancel {
                g.cancelSkeletonDropPickupPresentation()
            } else {
                g.collectPendingSkeletonDrop()
                try expect(g.pendingSkeletonDrop == nil && g.isSkeletonDropPickupInputLocked, "回収後も演出終了まではロック")
                let hp = g.state.playerHP
                let time = g.state.shiritoriTimeBonusSeconds
                let reduction = g.state.runTimeReductionSeconds
                g.collectPendingSkeletonDrop()
                try expect(g.state.playerHP == hp && g.state.shiritoriTimeBonusSeconds == time && g.state.runTimeReductionSeconds == reduction, "重複回収は無効")
                g.finishSkeletonDropPickupPresentation()
            }
            try expect(!g.isSkeletonDropPickupInputLocked && g.pendingSkeletonDrop == nil, "終了・キャンセルで待機状態を解消")
            g.moveForward()
            try expect(g.state.player.position.x == 2, "ドロップ処理後に移動を再開")
        }
    }
}
