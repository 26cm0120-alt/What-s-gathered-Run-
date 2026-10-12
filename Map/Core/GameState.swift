import Foundation

/// チュートリアルで表示する案内の段階
enum TutorialStep: Equatable {
    case moveForward
    case turnDirection
    case checkMap
    case findKey
    case reachGoal

    var instruction: String {
        switch self {
        case .moveForward:
            return "ステップ1/5：上フリックで1マス進もう！"
        case .turnDirection:
            return "ステップ2/5：左右フリックで向きを変えよう！"
        case .checkMap:
            return "ステップ3/5：上のダンジョン画面で進む方向を見て、下の探索マップで現在地を確認しよう！"
        case .findKey:
            return "ステップ4/5：宝箱を探して鍵を見つけよう！"
        case .reachGoal:
            return "ステップ5/5：鍵を手に入れた！ゴールを探そう！"
        }
    }
}

/// 案内を次の段階へ進める操作の種類
enum TutorialAction {
    case moveForward
    case turnLeft
    case turnRight
}

/// ゲーム全体の状態(仕様書§11)
struct GameState {
    var player: Player
    var hasKey: Bool = false
    /// この面でクリアするのに、鍵が必要か(仕様書§3.3)。面の定義から設定する
    let requiresKey: Bool
    /// クリア済みか(仕様書§11 クリア状態)
    var isCleared: Bool = false
    /// 探索済みのマス(オートマップ用)
    var explored: Set<GridPos>
    /// 画面に表示するメッセージ
    var message: String = ""
    /// 段階式チュートリアルの現在位置。本番面では nil
    var tutorialStep: TutorialStep?

    init(start: GridPos, direction: Direction, requiresKey: Bool, isStepByStepTutorial: Bool = false) {
        self.player = Player(position: start, direction: direction)
        self.requiresKey = requiresKey
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
            self.tutorialStep = .findKey
        default:
            break
        }
    }
}
