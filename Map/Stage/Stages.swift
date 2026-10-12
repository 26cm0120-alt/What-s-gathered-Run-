import Foundation

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
}

/// 各面のマップ定義(仕様書 付録A)
/// # = 壁, . = 床, S = スタート, G = ゴール, T = トラップ, K = 鍵の宝箱
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
            "S.......",  // 6
            "##....##",  // 7
            "##...T##",  // 8
            "##....##",  // 9
            "##.##.##",  // 10
            "##.#K.##",  // 11
            "G..#####",  // 12
            "##.#####",  // 13
            "##.#####",  // 14
        ],
        initialDirection: .east,
        requiresKey: true,
        isStepByStepTutorial: false
    )

    /// seedから同じランダム迷宮を生成する。seedはプレイ画面に表示する。
    static func random(seed: UInt64) -> Stage {
        Stage(
            title: "ランダムステージ",
            map: RandomMazeGenerator.generate(seed: seed),
            requiresKey: true,
            isStepByStepTutorial: false,
            seed: seed
        )
    }

    /// マップ定義の文字列から、面を作る。S が無い定義は、開発中のミスなので停止する
    private static func make(
        title: String,
        rows: [String],
        initialDirection: Direction,
        requiresKey: Bool,
        isStepByStepTutorial: Bool = false
    ) -> Stage {
        guard let map = MapLoader.load(rows: rows, initialDirection: initialDirection) else {
            fatalError("\(title)のマップ定義に S がありません")
        }
        return Stage(
            title: title,
            map: map,
            requiresKey: requiresKey,
            isStepByStepTutorial: isStepByStepTutorial,
            seed: nil
        )
    }
}
