import Foundation

enum MapLoader {
    /// 文字列の配列からマップを作る。Sが見つからない場合は nil
    static func load(rows: [String], initialDirection: Direction) -> MapData? {
        let cells: [[MapCell]] = rows.map { row in row.map { MapCell($0) } }
        for (y, row) in cells.enumerated() {
            for (x, cell) in row.enumerated() where cell == .start {
                return MapData(
                    cells: cells,
                    startPosition: GridPos(x: x, y: y),
                    initialDirection: initialDirection
                )
            }
        }
        return nil
    }
}
