import Foundation

/// 1つの面のマップ。マップ外は壁として扱う
struct MapData {
    let cells: [[MapCell]]
    let startPosition: GridPos
    let initialDirection: Direction
    /// ランダム面でseedから固定した敵種。固定面は空の辞書を使う。
    var enemyKinds: [GridPos: EnemyKind] = [:]
    /// ランダム面でseedから固定したトラップ種。未指定のTは基本トラップを使う。
    var trapKinds: [GridPos: TrapKind] = [:]

    var rows: Int { cells.count }
    var cols: Int { cells.map { $0.count }.max() ?? 0 }

    func cell(x: Int, y: Int) -> MapCell {
        guard y >= 0, y < cells.count else { return .wall }
        guard x >= 0, x < cells[y].count else { return .wall }
        return cells[y][x]
    }

    func cell(at pos: GridPos) -> MapCell {
        cell(x: pos.x, y: pos.y)
    }

    func isWall(x: Int, y: Int) -> Bool {
        cell(x: x, y: y).isWall
    }
}
