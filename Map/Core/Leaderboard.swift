import Foundation

/// 端末内ランキングを試練とランダムで分けて保存する。
enum LeaderboardMode: String, Codable, Hashable {
    case trial
    case random

    var title: String {
        switch self {
        case .trial: "試練の迷宮"
        case .random: "ランダムステージ"
        }
    }
}

struct LeaderboardEntry: Codable, Identifiable {
    let id: UUID
    var playerName: String
    let clearTime: TimeInterval
    let recordedAt: Date
    let seed: UInt64?

    init(playerName: String, clearTime: TimeInterval, seed: UInt64?) {
        self.id = UUID()
        self.playerName = playerName
        self.clearTime = clearTime
        self.recordedAt = Date()
        self.seed = seed
    }
}

enum LocalLeaderboard {
    private static let limit = 100

    static func load(_ mode: LeaderboardMode) -> [LeaderboardEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey(for: mode)),
              let entries = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) else {
            return []
        }
        return sorted(entries)
    }

    @discardableResult
    static func add(_ entry: LeaderboardEntry, to mode: LeaderboardMode) -> [LeaderboardEntry] {
        let entries = Array(sorted(load(mode) + [entry]).prefix(limit))
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey(for: mode))
        }
        return entries
    }

    /// 既存のランキング記録の名前だけを変更する。
    @discardableResult
    static func updateName(for entryID: UUID, to playerName: String, in mode: LeaderboardMode) -> Bool {
        var entries = load(mode)
        guard let index = entries.firstIndex(where: { $0.id == entryID }) else { return false }
        entries[index].playerName = playerName
        guard let data = try? JSONEncoder().encode(entries) else { return false }
        UserDefaults.standard.set(data, forKey: storageKey(for: mode))
        return true
    }

    private static func sorted(_ entries: [LeaderboardEntry]) -> [LeaderboardEntry] {
        entries.sorted {
            if $0.clearTime == $1.clearTime {
                return $0.recordedAt < $1.recordedAt
            }
            return $0.clearTime < $1.clearTime
        }
    }

    private static func storageKey(for mode: LeaderboardMode) -> String {
        "dungeon.leaderboard.\(mode.rawValue)"
    }
}
