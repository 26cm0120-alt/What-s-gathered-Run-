import Foundation

// 発生率
private func normalizedTrapRates(
    in group: TrapGroup
) -> [(kind: TrapKind, rate: Int)]? {
    let groupRates: [(kind: TrapKind, rate: Int)]
    switch group {
        
    // 手動設定
    case .a:
        groupRates = [
            // グループA：状態変化
            (kind: .turnRight, rate: 30),
            (kind: .doubleFlick, rate: 30),
            (kind: .hpDrain, rate: 40),
        ]
    case .b:
        groupRates = [
            // グループB：ワープ
            (kind: .warpToStart, rate: 30),
            (kind: .randomWarp, rate: 30),
            (kind: .warpBeforeKey, rate: 40),
        ]
    case .c:
        groupRates = [
            // グループC：運命
            (kind: .forceGameOver, rate: 10),
            (kind: .unexploded, rate: 90),
        ]
    }
    
    // 発生率の未入力確認
    let groupTraps = TrapKind.allCases.filter { $0.group == group }
    guard groupRates.count == groupTraps.count,
          Set(groupRates.map({ $0.kind })) == Set(groupTraps),
          groupRates.allSatisfy({ $0.kind.group == group && (0...100).contains($0.rate) }) else {
        return nil
    }
    // 合計100%確認
    // グループ内の発生率を合計
    let totalRate = groupRates.reduce(0, { $0 + $1.rate })
    // 合計が100%ならOK
    if totalRate == 100 { return groupRates }
    // 最大値が見つからなければ補正できないため、nilを返す。
    if let maxRate = groupRates.map({ $0.rate }).max(),
       // 最大値と同じ率を持つ罠を設定順に探す。
       // 同率が複数あれば、先に記述された罠が調整対象になる。
       let adjustmentIndex = groupRates.firstIndex(where: { $0.rate == maxRate }) {
        // 合計が100%未満なら不足分を加え、100%を超えていれば超過分を引く。
        let adjustedRate = groupRates[adjustmentIndex].rate + (100 - totalRate)

        // 補正後の率が0〜100%の範囲を外れたら、補正できないためnilを返す。
        if !(0...100).contains(adjustedRate) {
            return nil
        }

        // 元の発生率設定をコピーする。元の値は書き換えない。
        var normalizedRates = groupRates

        // コピー内で調整対象の罠の率だけを補正後の値に置き換える。
        normalizedRates[adjustmentIndex] = (
            // 罠の種類はそのまま残す。
            kind: groupRates[adjustmentIndex].kind,
            // 発生率を補正後の値にする。
            rate: adjustedRate
        )
        // 補正済みの発生率一覧を返す。
        return normalizedRates
    } else {
        // 最大値または調整対象が見つからなければ処理を中断する。
        return nil
    }
}

/// 抽選用の乱数を省略すると通常の乱数を使う。乱数を渡せばseedに応じて再現できる。
func selectTrap(
    in group: TrapGroup,
    drawRoll: () -> Int = { Int.random(in: 1...100) }
) -> TrapKind? {
    // 発生率の検証と補正を専用関数で行う。
    guard let normalizedRates = normalizedTrapRates(in: group) else { return nil }

    let roll = drawRoll()
    guard (1...100).contains(roll) else { return nil }
    var cumulativeRate = 0
    for entry in normalizedRates {
        cumulativeRate += entry.rate
        if roll <= cumulativeRate {
            return entry.kind
        }
    }
    return nil
}

/// 罠の機能グループ
enum TrapGroup: CaseIterable, Hashable {
    case a
    case b
    case c
}

/// 罠の種類
enum TrapKind: CaseIterable, Hashable {
    // グループA：状態変化
    case turnRight
    case doubleFlick
    case hpDrain

    // グループB：ワープ
    case warpToStart
    case randomWarp
    case warpBeforeKey

    // グループC：運命
    case forceGameOver
    case unexploded

    var group: TrapGroup {
        switch self {
        case .turnRight, .doubleFlick, .hpDrain: .a
        case .warpToStart, .randomWarp, .warpBeforeKey: .b
        case .forceGameOver, .unexploded: .c
        }
    }

}


struct TrapEvent: TileEvent {
    let kind: TrapKind
    let map: MapData

    init(kind: TrapKind, map: MapData) {
        self.kind = kind
        self.map = map
    }

    /// グループごとの振り分け
    func onEnter(state: inout GameState, from previousPosition: GridPos) {
        switch kind.group {
        case .a:
            activateGroupA(state: &state)
        case .b:
            activateGroupB(state: &state)
        case .c:
            activateGroupC(state: &state)
        }
    }

    // MARK: - グループA：状態変化
    private func activateGroupA(state: inout GameState) {
        switch kind {
        case .turnRight:
            turnPlayerRight(state: &state)
        case .doubleFlick:
            activateDoubleFlick(state: &state)
        case .hpDrain:
            activateHPDrain(state: &state)
        default:
            break
        }
    }

    /// 反転
    private func turnPlayerRight(state: inout GameState) {
        state.player.direction = state.player.direction.turnedRight
        let message = "トラップ！ 向きが右に90度変わった"
        state.message = message
        state.trapActivationMessage = message
    }

    /// 進行妨害
    private func activateDoubleFlick(state: inout GameState) {
        state.doubleFlickTrapActive = true
        state.hasPendingDoubleFlick = false
        let message = "トラップ! 前進には2回フリックが必要になった"
        state.message = message
        state.trapActivationMessage = message
    }

    /// 毒
    private func activateHPDrain(state: inout GameState) {
        state.hpDrainTrapActive = true
        let message = "トラップ! 1マス進むごとにHPが1減る"
        state.message = message
        state.trapActivationMessage = message
    }

    // MARK: - グループB：ワープ

    private func activateGroupB(state: inout GameState) {
        switch kind {
        case .warpToStart:
            warpToStart(state: &state)
        case .randomWarp:
            randomWarp(state: &state)
        case .warpBeforeKey:
            warpBeforeKey(state: &state)
        default:
            break
        }
    }

    /// スタート地点へ位置を移し、そこを探索済みにする。向きは維持する。
    private func warpToStart(state: inout GameState) {
        movePlayer(to: map.startPosition, state: &state)
        let message = "ワープの罠！ スタート地点へ戻された"
        state.message = message
        state.trapActivationMessage = message
    }

    /// 通常床の中から現在地以外を選び、そこへ位置を移す。
    private func randomWarp(state: inout GameState) {
        let ordinaryFloorPositions = map.cells.indices.flatMap { y in
            map.cells[y].indices.compactMap { x in
                map.cells[y][x] == .floor ? GridPos(x: x, y: y) : nil
            }
        }
        let destinations = ordinaryFloorPositions.filter { $0 != state.player.position }
        guard let destination = destinations.randomElement() else {
            let message = "ワープの罠！ 行き先が見つからなかった"
            state.message = message
            state.trapActivationMessage = message
            return
        }

        movePlayer(to: destination, state: &state)
        let message = "ワープの罠！ 迷宮の別の場所へ飛ばされた"
        state.message = message
        state.trapActivationMessage = message
    }

    /// 鍵に隣接する通常床へ移り、鍵の方向を向く。
    private func warpBeforeKey(state: inout GameState) {
        func findKeyPosition() -> GridPos? {
            for y in map.cells.indices {
                for x in map.cells[y].indices where map.cells[y][x] == .key {
                    return GridPos(x: x, y: y)
                }
            }
            return nil
        }

        func keyFrontPositions(for key: GridPos) -> [(position: GridPos, facingKey: Direction)] {
            let candidates: [(position: GridPos, facingKey: Direction)] = [
                (GridPos(x: key.x, y: key.y - 1), .south),
                (GridPos(x: key.x + 1, y: key.y), .west),
                (GridPos(x: key.x, y: key.y + 1), .north),
                (GridPos(x: key.x - 1, y: key.y), .east),
            ]
            return candidates.filter { map.cell(at: $0.position) == .floor }
        }

        func distance(_ first: GridPos, from second: GridPos) -> Int {
            abs(first.x - second.x) + abs(first.y - second.y)
        }

        guard let keyPosition = findKeyPosition(),
              let destination = keyFrontPositions(for: keyPosition)
                .min(by: { distance($0.position, from: state.player.position) < distance($1.position, from: state.player.position) }) else {
            let message = "ワープの罠！ 鍵の前へ移動できなかった"
            state.message = message
            state.trapActivationMessage = message
            return
        }

        movePlayer(to: destination.position, state: &state)
        state.player.direction = destination.facingKey
        let message = "ワープの罠！ 鍵の前へ飛ばされた"
        state.message = message
        state.trapActivationMessage = message
    }

    /// ワープ先のマスを探索済みにする。着地先のイベントは連鎖発動しない。
    private func movePlayer(to destination: GridPos, state: inout GameState) {
        state.player.position = destination
        state.explored.insert(destination)
    }

    // MARK: - グループC：発動結果
    private func activateGroupC(state: inout GameState) {
        switch kind {
        case .forceGameOver:
            forceGameOver(state: &state)
        case .unexploded:
            unExploded(state: &state)
        default:
            break
        }
    }

    /// 不発
    private func unExploded(state: inout GameState) {
        let message = "トラップ！ しかしなにも起こらなかった"
        state.message = message
        state.trapActivationMessage = message
    }
    /// 強制ゲームオーバー
    private func forceGameOver(state: inout GameState) {
        state.playerHP = 0 //HP0に
        state.isCleared = false
        state.isGameOver = true
        state.enemyBattle = nil
        let message = "トラップ！ 強制的にゲームオーバーになった"
        state.message = message
        state.trapActivationMessage = message
    }

}
