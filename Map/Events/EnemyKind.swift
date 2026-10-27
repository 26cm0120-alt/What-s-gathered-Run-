import Foundation

/// 戦闘に登場する敵の種類と能力値。ドラゴンはラスボス用で通常ステージには出さない。
enum EnemyKind: CaseIterable, Equatable {
    case dragon
    case slime
    case skeleton
    case gargoyle
    case imp
    case ghost
    case cyclops
    case mimic

    var name: String {
        switch self {
        case .dragon: return "ドラゴン"
        case .slime: return "スライム"
        case .skeleton: return "スケルトン"
        case .gargoyle: return "ガーゴイル"
        case .imp: return "小悪魔"
        case .ghost: return "ゴースト"
        case .cyclops: return "サイクロプス"
        case .mimic: return "ミミック"
        }
    }

    var imageName: String {
        switch self {
        case .dragon: return "MessageMonsterIdle"
        case .slime: return "DungeonSlime"
        case .skeleton: return "DungeonSkeleton"
        case .gargoyle: return "DungeonGargoyle"
        case .imp: return "DungeonImp"
        case .ghost: return "DungeonGhost"
        case .cyclops: return "DungeonCyclops"
        case .mimic: return "DungeonMimic"
        }
    }

    var hitImageName: String {
        switch self {
        case .dragon: return "MessageMonsterMove2"
        case .slime: return "SlimeHit"
        case .skeleton: return "SkeletonHit"
        case .gargoyle: return "GargoyleHit"
        case .imp: return "DungeonImp"
        case .ghost: return "DungeonGhost"
        case .cyclops: return "DungeonCyclops"
        case .mimic: return "DungeonMimic"
        }
    }

    var attackImageName: String {
        switch self {
        case .dragon: return "MessageMonsterMove1"
        case .slime: return "SlimeAttack"
        case .skeleton: return "SkeletonAttack"
        case .gargoyle: return "GargoyleAttack"
        case .imp: return "DungeonImp"
        case .ghost: return "DungeonGhost"
        case .cyclops: return "DungeonCyclops"
        case .mimic: return "DungeonMimic"
        }
    }

    var defeatedImageName: String {
        switch self {
        case .dragon: return "DragonDefeated"
        case .slime: return "SlimeDefeated"
        case .skeleton: return "SkeletonDefeated"
        case .gargoyle: return "GargoyleDefeated"
        case .imp: return "ImpDefeated"
        case .ghost: return "GhostDefeated"
        case .cyclops: return "CyclopsDefeated"
        case .mimic: return "MimicDefeated"
        }
    }

    var counterattackName: String {
        switch self {
        case .dragon: "ほのおのブレス"
        case .slime: "たいあたり"
        case .skeleton: "つるぎ斬り"
        case .gargoyle: "かぎ爪"
        case .imp: "魔法弾"
        case .ghost: "霊気"
        case .cyclops: "鉄拳"
        case .mimic: "かみつき"
        }
    }

    var encounterDialogue: String {
        switch self {
        case .slime: return "おまえが ちょうせんしゃか？\nよわそうな やつだな。\nカードなんか ひつようないぞ"
        case .skeleton: return "ぐぬぬ・・・おれには カードを\nつかえる のうみそが ねえんだ！\nちからずくで おいかえしてやる！"
        case .gargoyle: return "おろかものめっ！よわいものは\nさらに よわいものを みつけて\nたたかいを いどめっ！"
        case .dragon: return "う ぁ ぁ ぁ ぁ ぁ（書き文字）\nり・・・龍が廊下を\n練り歩いてるっ！"
        case .imp: return "ふふっ ここから さきは\nわたしの まほうの じかん！\nきみは ついて こられる？"
        case .ghost: return "ゆらり ゆらり・・・\nその あしおと きこえるぞ。\nここで いっしょに さまよおう。"
        case .cyclops: return "この めからは にがさない！\nちいさな ゆうしゃよ\nおれの こぶしを うけてみろ！"
        case .mimic: return "おたからだと おもったか？\nざんねん！ おまえの ほうが\nごちそう だったのさ！"
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
        case .imp: return "あらら まほうが からっぽ。\nきみって なかなか やるのね。\nつぎは わたしが かつんだから！"
        case .ghost: return "ああ・・・きりが はれる。\nおまえの ゆくみちが\nあかるく ありますように・・・"
        case .cyclops: return "ぐおお・・・みえていたのに。\nちからだけでは だめなのか。\nその ゆうき おぼえておくぞ！"
        case .mimic: return "ぐえっ！ かたい ごちそうだ！\nきょうは もう へいてん！\nふたを しめて ねるとするか。"
        }
    }

    func defeatDialogue(isTrialStage: Bool) -> String {
        guard self == .skeleton else { return defeatDialogue }
        if isTrialStage {
            return "もんばんの ことだま は\nひともじぜめ だぜ・・・\nイヤミなやつだが かてるもんか"
        }
        return "まおうさまの ことだま は\nへんげんじざい だぜ・・・\nただ よむだけじゃ かてねぇぜ"
    }

    // MARK: - バランス設計
    //
    // 狙い: 「全員クリアできるが、仕組みを知らないと全滅しそうに見える」。
    //  - 剣なしで戦う最初のテーマ敵は、どのテーマでも1戦でHPがほぼ半分(9〜10)減る。
    //  - 戦闘は必ずプレイヤーが先に攻撃するため、受ける反撃は「倒すまでの攻撃回数 - 1」回。
    //    (剣なし=1回5ダメージ、剣あり=1回10ダメージ)
    //  - 剣を取ったあとのガーゴイル・通常敵は1戦4以下。HP20なので、最初の戦闘から
    //    回復なしで3戦連続しても必ず2以上残り、戦闘だけで死ぬことはない。
    //  - 実際には歩行回復(5歩で1)や逃走もあるため、通常プレイの最低HPは6〜9程度になる。
    // スライム・スケルトンは試練の迷宮(剣なし・スライム→スケルトンで合計10)の調整を保つため変更しない。
    // 数値を変えたら Tests/CoreLogicTests.swift の testEnemyBalanceDesign も確認すること。

    var maxHP: Int {
        switch self {
        case .dragon, .skeleton, .gargoyle, .imp, .mimic, .ghost: return 15
        case .cyclops: return 20
        case .slime: return 10
        }
    }

    var attackDamage: Int {
        switch self {
        case .dragon, .skeleton, .gargoyle: return 4
        case .slime: return 2
        case .cyclops: return 3
        case .imp, .mimic, .ghost: return 5
        }
    }

    /// 専用の反撃効果音が設定されている敵種の音源。ドラゴンは nil。
    var counterattackAudioResource: AudioResource? {
        switch self {
        case .dragon: nil
        case .imp: .impCounterattack
        case .ghost: .ghostCounterattack
        case .cyclops: .cyclopsCounterattack
        case .mimic: .mimicCounterattack
        case .slime: .slimeCounterattack
        case .skeleton: .skeletonCounterattack
        case .gargoyle: .gargoyleCounterattack
        }
    }

    /// 新しい敵は透過素材をコードで動かす。既存の差分画像方式と共存する。
    var usesProceduralMotion: Bool {
        switch self {
        case .imp, .ghost, .cyclops, .mimic: true
        default: false
        }
    }

    /// ランダムステージの通常敵。スライムかスケルトンをseedから抽選する。
    static let randomEncounterKinds: [EnemyKind] = [.slime, .skeleton]

    /// ガーゴイルは生成側で1体固定配置するため、この抽選には含めない。
    static func randomEncounter(seed: UInt64, position: GridPos) -> EnemyKind {
        let coordinate = (UInt64(position.x) << 32) ^ UInt64(position.y)
        return randomEncounterKinds[Int((seed ^ coordinate) % UInt64(randomEncounterKinds.count))]
    }

    /// ランダムステージのテーマごとに1体だけ配置される専用の敵。
    static func themeEnemy(for theme: DungeonTheme) -> EnemyKind {
        switch theme {
        case .temple: .cyclops
        case .cave: .mimic
        case .forestMansion: .ghost
        case .hell: .imp
        }
    }

    /// 倒すと剣を落とす敵。
    var dropsSword: Bool {
        switch self {
        case .cyclops, .mimic, .ghost, .imp: true
        default: false
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

/// 攻撃の予備動作・飛来・着弾を、ViewとHP更新側で同じ時間にする。
enum EnemyCounterattackTiming {
    static let windupNanoseconds: UInt64 = 180_000_000
    static let travelDuration = 0.42
    static let travelNanoseconds: UInt64 = 420_000_000
    static let impactNanoseconds = windupNanoseconds + travelNanoseconds
    static let recoveryNanoseconds: UInt64 = 320_000_000
}
