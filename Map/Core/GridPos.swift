import Foundation

/// グリッド上の位置。左上が (0, 0)、x は右へ、y は下へ増える
struct GridPos: Hashable {
    let x: Int
    let y: Int

    /// 指定した向きへ n マス進んだ位置
    func moved(_ direction: Direction, by n: Int = 1) -> GridPos {
        GridPos(x: x + direction.dx * n, y: y + direction.dy * n)
    }
}
