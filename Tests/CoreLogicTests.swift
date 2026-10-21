import Foundation

@main
struct CoreLogicTests {
    private static var assertionCount = 0

    @MainActor
    static func main() throws {
        if CommandLine.arguments.contains("--determinism-probe") {
            for seed in 0..<256 {
                print(mapSignature(RandomMazeGenerator.generate(seed: UInt64(seed))))
            }
            return
        }

        try testStageTimingPolicy()
        print("PASS: 初回タイム計測ポリシー")

        try testGeneratedMazesAcrossSeeds()
        print("PASS: 500 seed の迷宮構造・到達可能性")

        try testLeaderboardOrderingAndModeIsolation()
        print("PASS: ランキング順とモード分離")

        try testLeaderboardLimit()
        print("PASS: ランキング上限100件")

        try testLeaderboardNameUpdate()
        print("PASS: 名前更新時の記録情報維持")

        print("完了: \(assertionCount) assertions")
    }

    private static func testStageTimingPolicy() throws {
        let tutorial = Stages.tutorial
        let trial = Stages.trial
        let random = Stages.random(seed: 42)
        let seededTutorial = Stage(
            title: tutorial.title,
            map: tutorial.map,
            requiresKey: tutorial.requiresKey,
            isStepByStepTutorial: true,
            seed: 43,
            shiritoriStageKind: tutorial.shiritoriStageKind,
            dungeonTheme: tutorial.dungeonTheme,
            requiresSwordForKey: tutorial.requiresSwordForKey
        )

        try expect(!StageTimingPolicy.startsTimer(for: tutorial), "チュートリアルは計時しない")
        try expect(StageTimingPolicy.recordKey(for: tutorial) == nil, "チュートリアルの記録キーがない")
        try expect(StageTimingPolicy.leaderboardMode(for: tutorial) == nil, "チュートリアルはランキング対象外")
        try expect(!StageTimingPolicy.startsTimer(for: seededTutorial), "seedがあってもチュートリアルは計時しない")
        try expect(StageTimingPolicy.leaderboardMode(for: seededTutorial) == nil, "seedがあってもチュートリアルはランキング対象外")

        try expect(StageTimingPolicy.startsTimer(for: trial), "試練は初回から計時する")
        try expect(StageTimingPolicy.recordKey(for: trial) == "dungeon.bestClearTime.trial", "試練の最短タイムキー")
        try expect(StageTimingPolicy.leaderboardMode(for: trial) == .trial, "試練ランキング")

        try expect(StageTimingPolicy.startsTimer(for: random), "ランダムは初回から計時する")
        try expect(StageTimingPolicy.recordKey(for: random) == "dungeon.bestClearTime.random", "ランダムの最短タイムキー")
        try expect(StageTimingPolicy.leaderboardMode(for: random) == .random, "ランダムランキング")
    }

    private static func testGeneratedMazesAcrossSeeds() throws {
        var trapTypeCounts: [TrapKind: Int] = [:]
        var hasDuplicateTrapTypes = false
        for seed in 0..<500 {
            let map = RandomMazeGenerator.generate(seed: UInt64(seed))
            let cells = map.cells.flatMap { $0 }
            try expect(map.rows == 17 && map.cols == 17, "seed \(seed): 17x17")
            try expect(cells.filter { $0 == .start }.count == 1, "seed \(seed): start が1つ")
            try expect(cells.filter { $0 == .goal }.count == 1, "seed \(seed): goal が1つ")
            try expect(cells.filter { $0 == .sword }.count == 1, "seed \(seed): sword が1つ")
            try expect(cells.filter { $0 == .key }.count == 1, "seed \(seed): key が1つ")
            try expect(cells.filter { $0 == .enemy }.count == 2, "seed \(seed): enemy が2つ")
            try expect(cells.filter { $0.isTrap }.count == 2, "seed \(seed): trap が2つ")
            try expect(map.enemyKinds.count == 2, "seed \(seed): 敵の種類定義が2つ")
            try expect(map.enemyKinds.values.contains(.gargoyle), "seed \(seed): gargoyle を含む")
            try expect(map.trapKinds.count == 2, "seed \(seed): trap の種類定義が2つ")
            try expect(map.trapKinds.values.allSatisfy { $0.group == .a }, "seed \(seed): trap はグループA")
            if Set(map.trapKinds.values).count == 1 {
                hasDuplicateTrapTypes = true
            }
            for kind in map.trapKinds.values {
                trapTypeCounts[kind, default: 0] += 1
            }

            let reachable = reachablePositions(from: map.startPosition, in: map)
            let walkable = Set(map.cells.indices.flatMap { y in
                map.cells[y].indices.compactMap { x -> GridPos? in
                    map.cells[y][x].isWall ? nil : GridPos(x: x, y: y)
                }
            })
            try expect(reachable == walkable, "seed \(seed): 通路が全て連結")
            try expect(map.trapKinds.keys.allSatisfy { reachable.contains($0) }, "seed \(seed): trap に到達可能")

            let repeated = RandomMazeGenerator.generate(seed: UInt64(seed))
            try expect(mapSignature(map) == mapSignature(repeated), "seed \(seed): 同じseedで同じマップ")
        }
        try expect(hasDuplicateTrapTypes, "異なる2マスに同じグループA罠が生成されるseedがある")
        try expect(trapTypeCounts.count == 3, "500 seedでグループAの全種類が抽選される")
    }

    private static func testLeaderboardOrderingAndModeIsolation() throws {
        try withIsolatedDefaults { defaults in
            let earlier = LeaderboardEntry(
                id: stableID(1),
                playerName: "先の登録",
                clearTime: 12.0,
                recordedAt: Date(timeIntervalSince1970: 100),
                seed: nil
            )
            let later = LeaderboardEntry(
                id: stableID(2),
                playerName: "後の登録",
                clearTime: 12.0,
                recordedAt: Date(timeIntervalSince1970: 200),
                seed: nil
            )
            let faster = LeaderboardEntry(
                id: stableID(3),
                playerName: "最速",
                clearTime: 11.9,
                recordedAt: Date(timeIntervalSince1970: 300),
                seed: nil
            )

            _ = LocalLeaderboard.add(later, to: .trial, defaults: defaults)
            _ = LocalLeaderboard.add(earlier, to: .trial, defaults: defaults)
            _ = LocalLeaderboard.add(faster, to: .trial, defaults: defaults)

            let trial = LocalLeaderboard.load(.trial, defaults: defaults)
            try expect(trial.map(\.id) == [faster.id, earlier.id, later.id], "タイム昇順、同タイムは登録日時昇順")
            try expect(LocalLeaderboard.load(.random, defaults: defaults).isEmpty, "試練とランダムのランキングを分離")
        }
    }

    private static func testLeaderboardLimit() throws {
        try withIsolatedDefaults { defaults in
            for index in 0..<105 {
                let entry = LeaderboardEntry(
                    id: stableID(index + 100),
                    playerName: "Player\(index)",
                    clearTime: TimeInterval(index),
                    recordedAt: Date(timeIntervalSince1970: TimeInterval(index)),
                    seed: UInt64(index)
                )
                _ = LocalLeaderboard.add(entry, to: .random, defaults: defaults)
            }

            let entries = LocalLeaderboard.load(.random, defaults: defaults)
            try expect(entries.count == 100, "保存・読込件数を100件に制限")
            try expect(entries.first?.clearTime == 0, "最速記録を保持")
            try expect(entries.last?.clearTime == 99, "101位以降を除外")
        }
    }

    private static func testLeaderboardNameUpdate() throws {
        try withIsolatedDefaults { defaults in
            let original = LeaderboardEntry(
                id: stableID(500),
                playerName: "修正前",
                clearTime: 34.5,
                recordedAt: Date(timeIntervalSince1970: 1234),
                seed: 9876
            )
            _ = LocalLeaderboard.add(original, to: .trial, defaults: defaults)

            try expect(
                LocalLeaderboard.updateName(for: original.id, to: "修正後", in: .trial, defaults: defaults),
                "保存済みの名前を更新"
            )
            let updated = try unwrap(
                LocalLeaderboard.load(.trial, defaults: defaults).first,
                "更新後の記録を再読込"
            )
            try expect(updated.playerName == "修正後", "新しい名前を保存")
            try expect(updated.id == original.id, "記録IDを維持")
            try expect(updated.clearTime == original.clearTime, "タイムを維持")
            try expect(updated.recordedAt == original.recordedAt, "登録日時を維持")
            try expect(updated.seed == original.seed, "seedを維持")
        }
    }

    private static func withIsolatedDefaults(_ body: (UserDefaults) throws -> Void) throws {
        let suiteName = "Wagyaran.CoreLogicTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestError.failed("テスト用UserDefaultsを作成できません")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }
        try body(defaults)
    }

    private static func reachablePositions(from start: GridPos, in map: MapData) -> Set<GridPos> {
        let offsets = [(x: 0, y: -1), (x: 1, y: 0), (x: 0, y: 1), (x: -1, y: 0)]
        var visited: Set<GridPos> = [start]
        var queue = [start]
        var index = 0

        while index < queue.count {
            let current = queue[index]
            index += 1
            for offset in offsets {
                let next = GridPos(x: current.x + offset.x, y: current.y + offset.y)
                guard !map.cell(at: next).isWall, visited.insert(next).inserted else { continue }
                queue.append(next)
            }
        }
        return visited
    }

    private static func mapSignature(_ map: MapData) -> String {
        let cells = map.cells.map { row in row.map(cellCode).joined() }.joined(separator: "/")
        let enemies = map.enemyKinds.map { "\($0.key.x),\($0.key.y):\($0.value)" }.sorted().joined(separator: ";")
        let traps = map.trapKinds.map { "\($0.key.x),\($0.key.y):\($0.value)" }.sorted().joined(separator: ";")
        return "\(cells)|S:\(map.startPosition.x),\(map.startPosition.y)|D:\(map.initialDirection.rawValue)|E:\(enemies)|T:\(traps)"
    }

    private static func cellCode(_ cell: MapCell) -> String {
        switch cell {
        case .wall: "#"
        case .floor: "."
        case .start: "S"
        case .trap: "T"
        case .doubleFlickTrap: "F"
        case .hpDrainTrap: "H"
        case .warpToStartTrap: "U"
        case .randomWarpTrap: "R"
        case .keyFrontWarpTrap: "P"
        case .gameOverTrap: "D"
        case .unexplodedTrap: "N"
        case .sword: "W"
        case .key: "K"
        case .enemy: "E"
        case .goal: "G"
        }
    }

    private static func stableID(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }

    private static func unwrap<T>(_ value: T?, _ message: String) throws -> T {
        guard let value else { throw TestError.failed(message) }
        return value
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        assertionCount += 1
        guard condition() else { throw TestError.failed(message) }
    }
}

private enum TestError: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message): "テスト失敗: \(message)"
        }
    }
}
