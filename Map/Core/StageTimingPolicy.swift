import Foundation

/// 初回から同じ条件で計時し、チュートリアルだけを対象外にする。
enum StageTimingPolicy {
    static func startsTimer(for stage: Stage) -> Bool {
        recordKey(for: stage) != nil
    }

    static func recordKey(for stage: Stage) -> String? {
        guard !stage.isStepByStepTutorial else { return nil }

        if stage.seed != nil {
            return "dungeon.bestClearTime.random"
        }

        switch stage.shiritoriStageKind {
        case .trial:
            return "dungeon.bestClearTime.trial"
        case .standard:
            return nil
        }
    }

    static func leaderboardMode(for stage: Stage) -> LeaderboardMode? {
        guard !stage.isStepByStepTutorial else { return nil }
        if stage.seed != nil { return .random }
        guard stage.shiritoriStageKind == .trial else { return nil }
        return .trial
    }
}
