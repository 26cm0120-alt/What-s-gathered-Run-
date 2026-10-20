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

    var hitImageName: String {
        switch self {
        case .dragon: "MessageMonsterMove2"
        case .slime: "SlimeHit"
        case .skeleton: "SkeletonHit"
        case .gargoyle: "GargoyleHit"
        }
    }

    var attackImageName: String {
        switch self {
        case .dragon: "MessageMonsterMove1"
        case .slime: "SlimeAttack"
        case .skeleton: "SkeletonAttack"
        case .gargoyle: "GargoyleAttack"
        }
    }

    var defeatedImageName: String {
        switch self {
        case .dragon: "MessageMonsterMove3"
        case .slime: "SlimeDefeated"
        case .skeleton: "SkeletonDefeated"
        case .gargoyle: "GargoyleDefeated"
        }
    }

    var encounterDialogue: String {
        switch self {
        case .slime: return "おまえが ちょうせんしゃか？\nよわそうな やつだな。\nカードなんか ひつようないぞ"
        case .skeleton: return "ぐぬぬ・・・おれには カードを\nつかえる のうみそが ねえんだ！\nちからずくで おいかえしてやる！"
        case .gargoyle: return "おろかものめっ！よわいものは\nさらに よわいものを みつけて\nたたかいを いどめっ！"
        case .dragon: return "う ぁ ぁ ぁ ぁ ぁ（書き文字）\nり・・・龍が廊下を\n練り歩いてるっ！"
        }
    }

    func encounterDialogue(isTrialStage: Bool) -> String {
        guard self == .skeleton else { return encounterDialogue }
        return "ぐぬぬ・・・おれには カードを\nつかえる のうみそが ねえんだ！\nちからずくで おいかえしてやる！"
    }

    var defeatDialogue: String {
        switch self {
        case .slime: return "やっぱり カードで\nしょうぶ するんだった・・・"
        case .skeleton: return "まおうさまの ことだま は\nへんげんじざい だぜ・・・\nただ よむだけじゃ かてねぇぜ"
        case .gargoyle: return "そんなわけ ないッス！おれが\nまけるわけ ないッス！やっぱし\nこわいスね、ドラゴンぞくは。"
        case .dragon: return "弱きものから\n狩る・・・！\n次なる標的は・・・！？"
        }
    }

    func defeatDialogue(isTrialStage: Bool) -> String {
        guard self == .skeleton else { return defeatDialogue }
        if isTrialStage {
            return "もんばんの ことだま は\nひともじぜめ だぜ・・・\nイヤミなやつだが かてるもんか"
        }
        return "まおうさまの ことだま は\nへんげんじざい だぜ・・・\nただ よむだけじゃ かてねぇぜ"
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
