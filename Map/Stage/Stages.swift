import Foundation

/// しりとり開始時に使用するルール・データの系統。
enum ShiritoriStageKind {
    /// チュートリアルとランダムステージで使う既存のしりとり
    case standard
    /// 試練の迷宮専用のしりとり
    case trial
}

/// ランダム迷宮の外観と専用BGM。seedだけから選ぶため、同じseedならテーマも再現する。
enum DungeonTheme: CaseIterable {
    case temple
    case cave
    case hell
    case forestMansion

    static func forSeed(_ seed: UInt64) -> DungeonTheme {
        allCases[Int(seed % UInt64(allCases.count))]
    }

    var title: String {
        switch self {
        case .temple: "古代神殿"
        case .cave: "水晶洞窟"
        case .hell: "地獄の回廊"
        case .forestMansion: "森の洋館"
        }
    }

    var backgroundMusicName: String {
        switch self {
        case .temple: "古代神殿BGM"
        case .cave: "水晶洞窟BGM"
        case .hell: "地獄の回廊BGM"
        case .forestMansion: "森の洋館BGM"
        }
    }

    var backgroundMusicExtension: String {
        "mp3"
    }

    /// 壁・床・天井それぞれの基調色。各値は0〜1のRGB。
    func stoneColor(surfaceKind: Int) -> (red: Double, green: Double, blue: Double) {
        switch (self, surfaceKind) {
        case (.temple, 1): (0.24, 0.19, 0.11)
        case (.temple, 2): (0.16, 0.12, 0.07)
        case (.temple, _): (0.39, 0.31, 0.19)
        case (.cave, 1): (0.12, 0.17, 0.22)
        case (.cave, 2): (0.075, 0.10, 0.14)
        case (.cave, _): (0.25, 0.32, 0.37)
        case (.hell, 1): (0.18, 0.055, 0.045)
        case (.hell, 2): (0.095, 0.025, 0.025)
        case (.hell, _): (0.30, 0.09, 0.075)
        case (.forestMansion, 1): (0.19, 0.15, 0.10)
        case (.forestMansion, 2): (0.11, 0.14, 0.09)
        case (.forestMansion, _): (0.29, 0.25, 0.17)
        }
    }

    var accentColor: (red: Double, green: Double, blue: Double) {
        switch self {
        case .temple: (0.95, 0.70, 0.25)
        case .cave: (0.25, 0.82, 0.98)
        case .hell: (1.0, 0.20, 0.035)
        case .forestMansion: (0.30, 0.62, 0.28)
        }
    }
}

/// 面(ステージ)の定義(仕様書§5.5)
struct Stage {
    /// 面の名前(スタート画面などで使う)
    let title: String
    /// 面のマップ(初期方向を含む)
    let map: MapData
    /// Gでクリアするのに鍵が必要か(仕様書§3.3)
    let requiresKey: Bool
    /// 案内に合わせてチュートリアルの段階を進めるか
    let isStepByStepTutorial: Bool
    /// ランダムステージの再現に使うseed（固定面では nil）
    let seed: UInt64?
    /// この面をクリアした後に起動するしりとりの系統
    let shiritoriStageKind: ShiritoriStageKind
    /// ランダムステージの外観・BGMテーマ。固定ステージは nil。
    let dungeonTheme: DungeonTheme?
    /// ランダムステージでは剣なしだとガーゴイルに攻撃が通らず、鍵宝箱も開けられない。
    let requiresSwordForKey: Bool
}

/// 各面のマップ定義(仕様書 付録A)
/// # = 壁, . = 床, S = スタート, G = ゴール, T = トラップ, W = 剣, K = 鍵の宝箱, E = 敵
enum Stages {
    /// スタート画面に並べる面の一覧(表示順)
    static let all: [Stage] = [tutorial, trial]

    /// チュートリアル(付録A.1)。前進・方向転換・探索マップ・鍵取得・ゴールを段階的に練習する
    static let tutorial: Stage = make(
        title: "チュートリアル",
        rows: [
            "#######",
            "##G####",
            "##.####",
            "##.####",
            "#.K...#",
            "#####S#",
            "#######",
        ],
        initialDirection: .north,
        requiresKey: true,
        isStepByStepTutorial: true
    )

    /// 試練の迷宮（付録A.2）。鍵が必要。
    /// 列は Excel の I〜P、行は 2〜14 に対応
    static let trial: Stage = make(
        title: "試練の迷宮",
        rows: [
            "##.#####",  // 2
            "##.#####",  // 3
            "##.#####",  // 4
            "##.#####",  // 5
            "S....E..",  // 6: 東の通路にスライム（列N）
            "##....##",  // 7
            "##...T##",  // 8: トラップ（列N）
            "##....##",  // 9
            "##.##.##",  // 10
            "##.#K.##",  // 11
            "G.E#####",  // 12: ゴール前の通路にスケルトン（列K）
            "##.#####",  // 13
            "##.#####",  // 14
        ],
        initialDirection: .east,
        requiresKey: true,
        isStepByStepTutorial: false,
        shiritoriStageKind: .trial
    )

    /// seedから同じランダム迷宮を生成する。seedはプレイ画面に表示する。
    static func random(seed: UInt64) -> Stage {
        let theme = DungeonTheme.forSeed(seed)
        return Stage(
            title: "ランダムステージ：\(theme.title)",
            map: RandomMazeGenerator.generate(seed: seed),
            requiresKey: true,
            isStepByStepTutorial: false,
            seed: seed,
            shiritoriStageKind: .standard,
            dungeonTheme: theme,
            requiresSwordForKey: true
        )
    }

    /// マップ定義の文字列から、面を作る。S が無い定義は、開発中のミスなので停止する
    private static func make(
        title: String,
        rows: [String],
        initialDirection: Direction,
        requiresKey: Bool,
        isStepByStepTutorial: Bool = false,
        shiritoriStageKind: ShiritoriStageKind = .standard
    ) -> Stage {
        guard let map = MapLoader.load(rows: rows, initialDirection: initialDirection) else {
            fatalError("\(title)のマップ定義に S がありません")
        }
        return Stage(
            title: title,
            map: map,
            requiresKey: requiresKey,
            isStepByStepTutorial: isStepByStepTutorial,
            seed: nil,
            shiritoriStageKind: shiritoriStageKind,
            dungeonTheme: nil,
            requiresSwordForKey: false
        )
    }
}
