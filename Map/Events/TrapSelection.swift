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
    
    return normalizedTrapRates(in: group, rates: groupRates)
}

/// 発生率の検証・補正を独立させ、設定変更時の境界条件も検証できるようにする。
func normalizedTrapRates(
    in group: TrapGroup,
    rates groupRates: [(kind: TrapKind, rate: Int)]
) -> [(kind: TrapKind, rate: Int)]? {
    // 発生率の未入力確認
    let groupTraps = TrapKind.allCases.filter { $0.group == group }
    guard groupRates.count == groupTraps.count,
          Set(groupRates.map({ $0.kind })) == Set(groupTraps),
          groupRates.allSatisfy({ $0.kind.group == group && (0...100).contains($0.rate) }) else {
        return nil
    }
    // 合計100%確認
    // グループの発生率を合計
    let totalRate = groupRates.reduce(0, { $0 + $1.rate })
    // 合計が100%ならOK
    if totalRate == 100 { return groupRates }
    // 補正不可
    if let maxRate = groupRates.map({ $0.rate }).max(),
       // 同率が複数あれば、先に記述された罠が調整対象になる。
       let adjustmentIndex = groupRates.firstIndex(where: { $0.rate == maxRate }) {
        // 合計が100%未満なら不足分を加え、100%を超えていれば超過分を引く。
        let adjustedRate = groupRates[adjustmentIndex].rate + (100 - totalRate)
        // 補正後の率が0〜100%の範囲を外れたら、補正できないためnilを返す。
        if !(0...100).contains(adjustedRate) {
            return nil
        }
        // 元の発生率設定をコピー（元の値は書き換えない）
        var normalizedRates = groupRates

        // コピー内で調整対象の罠の率だけを補正後の値に置き換え
        normalizedRates[adjustmentIndex] = (
            // 罠の種類はそのまま残す
            kind: groupRates[adjustmentIndex].kind,
            // 発生率を補正後の値にする
            rate: adjustedRate
        )
        // 補正済みの発生率一覧を返す
        return normalizedRates
    } else {
        // 最大値または調整対象が見つからなければ処理を中断する。
        return nil
    }
}

// 抽選用の乱数を省略すると通常の乱数を使う。乱数を渡せばseedに応じて再現できる。
@MainActor
func selectTrap(
    in group: TrapGroup,
    excluding excludedKinds: Set<TrapKind>,
    drawRoll: (_ upperBound: Int) -> Int = { Int.random(in: 1...$0) }
) -> TrapKind? {
    guard let normalizedRates = normalizedTrapRates(in: group) else { return nil }
    let availableRates = normalizedRates.filter { !excludedKinds.contains($0.kind) }
    let totalRate = availableRates.reduce(0) { $0 + $1.rate }
    guard totalRate > 0 else { return nil }

    let roll = drawRoll(totalRate)
    guard (1...totalRate).contains(roll) else { return nil }
    var cumulativeRate = 0
    for entry in availableRates {
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
    // グループB：ワープ系
    case warpToStart
    case randomWarp
    case warpBeforeKey
    // グループC：運命系
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

