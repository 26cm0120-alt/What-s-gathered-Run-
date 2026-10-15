import Foundation

/// 戦闘に登場する敵の種類と能力値。ドラゴンはラスボス用で通常ステージには出さない。
enum EnemyKind: CaseIterable, Equatable {
    case dragon
    case slime
    case skeleton
    case gargoyle

    var name: String {
        switch self {
        case .dragon: return "ドラゴン"
        case .slime: return "スライム"
        case .skeleton: return "スケルトン"
        case .gargoyle: return "ガーゴイル"
        }
    }

    var imageName: String {
        switch self {
        case .dragon: return "MessageMonsterIdle"
        case .slime: return "DungeonSlime"
        case .skeleton: return "DungeonSkeleton"
        case .gargoyle: return "DungeonGargoyle"
        }
    }

    var encounterDialogue: String {
        switch self {
        case .slime: return "なんだか見たことないやつが\n迷い込んできたな・・・\n邪魔だ！"
        case .skeleton: return "なんだてめえ、\nこの先にいる魔王に\n出会いたかったら、俺を倒すんだな！"
        case .gargoyle: return "俺はこのダンジョンの中で\n最強だぜ・・・？"
        case .dragon: return "我が迷宮へ\nようこそ。"
        }
    }

    var defeatDialogue: String {
        switch self {
        case .slime: return "私が一番\n弱かったです、、"
        case .skeleton: return "ちくしょう！\n魔王を倒したかったら\n語彙力をつけろよ！"
        case .gargoyle: return "なんだよ！その武器！\nずるい！"
        case .dragon: return "見事だ…\n…。"
        }
    }

    var maxHP: Int {
        switch self {
        case .dragon, .skeleton, .gargoyle: return 15
        case .slime: return 10
        }
    }

    var attackDamage: Int {
        switch self {
        case .dragon, .skeleton: return 4
        case .slime: return 2
        case .gargoyle: return 5
        }
    }

    static func encounter(seed: UInt64?, position: GridPos) -> EnemyKind {
        let coordinate = (UInt64(position.x) << 32) ^ UInt64(position.y)
        let index = Int(((seed ?? 0) ^ coordinate) % 4)
        switch index {
        case 0, 1: return .slime
        case 2: return .skeleton
        default: return .gargoyle
        }
    }
}
