import Foundation

/// チュートリアルで表示する案内の段階
enum TutorialStep: Equatable {
    case moveForward
    case turnDirection
    case checkMap
    case zoomMap
    case findKey
    case reachGoal

    var instruction: String {
        switch self {
        case .moveForward:
            return "ステップ1/6：上フリックで\n1マス進もう！"
        case .turnDirection:
            return "ステップ2/6：左右フリックで\n向きを変えよう！"
        case .checkMap:
            return "ステップ3/6：上のダンジョン画面で\n進む方向を見て、下の探索マップで\n現在地を確認しよう！"
        case .zoomMap:
            return "ステップ4/6：探索マップを\n2本指で広げて拡大しよう！"
        case .findKey:
            return "ステップ5/6：宝箱を探して\n鍵を見つけよう！"
        case .reachGoal:
            return "ステップ6/6：鍵を手に入れた！\nゴールを探そう！"
        }
    }
}

/// 案内を次の段階へ進める操作の種類
enum TutorialAction {
    case moveForward
    case turnLeft
    case turnRight
    case zoomMap
}

/// 戦闘中の状態。敵種ごとの最大HPを基準に、現在HPを管理する。
struct EnemyBattle: Equatable {
    let kind: EnemyKind
    let enemyPosition: GridPos
    let retreatPosition: GridPos
    var enemyHP: Int
    var message: String

    init(kind: EnemyKind, enemyPosition: GridPos, retreatPosition: GridPos, enemyHP: Int? = nil) {
        self.kind = kind
        self.enemyPosition = enemyPosition
        self.retreatPosition = retreatPosition
        self.enemyHP = min(kind.maxHP, max(1, enemyHP ?? kind.maxHP))
        self.message = "\(kind.name)が現れた！"
    }
}

/// 敵との遭遇直後、5秒間ダンジョン画面に表示するセリフ。
struct EnemyEncounterSpeech: Equatable {
    let id: Int
    let kind: EnemyKind
    let position: GridPos
    let message: String
}

/// 敵を倒した直後、3秒間だけダンジョン画面に表示するセリフ。
struct EnemyDefeatSpeech: Equatable {
    let id: Int
    let kind: EnemyKind
    let message: String
}

/// スケルトンが落とす3種類の回収アイテム。
enum SkeletonDropItem: String, CaseIterable, Identifiable {
    case shiritoriTime
    case runTimeReduction
    case bandage

    var id: String { rawValue }

    var title: String {
        switch self {
        case .shiritoriTime: "砂時計"
        case .runTimeReduction: "時短の砂時計"
        case .bandage: "絆創膏"
        }
    }

    var effect: String {
        switch self {
        case .shiritoriTime: "しりとりの持ち時間が\n5秒増えた。"
        case .runTimeReduction: "今回のクリアタイムが\n10秒短縮された。"
        case .bandage: "HPを\n5回復"
        }
    }

}

/// ゲーム全体の状態(仕様書§11)
struct GameState {
    static let playerMaxHP = 20

    var player: Player
    var hasKey: Bool = false
    var hasSword: Bool = false
    var playerHP = playerMaxHP
    /// 設定された前進フリック数で1マス進む遅行罠が発動中か。
    var doubleFlickTrapActive = false
    /// 遅行の効果が続く残り前進マス数。
    var doubleFlickTrapMovesRemaining = 0
    /// 現在の1マス移動に向けて受け付けた前進フリック数。
    var slowForwardFlickProgress = 0
    /// 移動ごとにHPが減る毒罠が発動中か。
    var hpDrainTrapActive = false
    /// 毒の効果が続く残り歩数。
    var hpDrainTrapStepsRemaining = 0
    /// 直近に踏んだ罠がカットインへ表示する発動メッセージ。
    var trapActivationMessage: String?
    /// マップ上で実際に移動した歩数。向き変更や壁への衝突は含めない。
    var mapStepCount = 0
    /// スケルトンの砂時計によるしりとり持ち時間加算。
    var shiritoriTimeBonusSeconds = 0
    /// 今回の探索タイムから差し引く秒数。
    var runTimeReductionSeconds = 0
    var enemyBattle: EnemyBattle?
    /// 逃走後も同じ敵マスで再戦できるよう、敵ごとの残りHPを保持する。
    var enemyHPByPosition: [GridPos: Int] = [:]
    var defeatedEnemies: Set<GridPos> = []
    /// 撃破したマスと敵の種類。3D表示には敵ごとの倒れた画像を残す。
    var defeatedEnemyKinds: [GridPos: EnemyKind] = [:]
    var isGameOver = false
    /// この面でクリアするのに、鍵が必要か(仕様書§3.3)。面の定義から設定する
    let requiresKey: Bool
    /// ランダム面では剣がないとガーゴイルに攻撃が通らず、鍵宝箱も開けられない。
    let requiresSwordForKey: Bool
    /// クリア済みか(仕様書§11 クリア状態)
    var isCleared: Bool = false
    /// 探索済みのマス(オートマップ用)
    var explored: Set<GridPos>
    /// 発動後に3D床とオートマップへ表示するトラップのマス。
    var activatedTrapPositions: Set<GridPos> = []
    /// 画面に表示するメッセージ
    var message: String = ""
    /// 段階式チュートリアルの現在位置。本番面では nil
    var tutorialStep: TutorialStep?

    init(
        start: GridPos,
        direction: Direction,
        requiresKey: Bool,
        requiresSwordForKey: Bool = false,
        isStepByStepTutorial: Bool = false
    ) {
        self.player = Player(position: start, direction: direction)
        self.requiresKey = requiresKey
        self.requiresSwordForKey = requiresSwordForKey
        self.explored = [start]   // Sは開始時に探索済み
        self.tutorialStep = isStepByStepTutorial ? .moveForward : nil
    }

    /// 案内に対応する操作が行われたとき、段階を次へ進める
    mutating func recordTutorialAction(_ action: TutorialAction) {
        guard let tutorialStep else { return }

        switch (tutorialStep, action) {
        case (.moveForward, .moveForward):
            self.tutorialStep = .turnDirection
        case (.turnDirection, .turnLeft), (.turnDirection, .turnRight):
            self.tutorialStep = .checkMap
        case (.checkMap, .moveForward), (.checkMap, .turnLeft), (.checkMap, .turnRight):
            self.tutorialStep = .zoomMap
        case (.zoomMap, .zoomMap):
            self.tutorialStep = .findKey
        default:
            break
        }
    }
}
