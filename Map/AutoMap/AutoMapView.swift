import SwiftUI

// MARK: - オートマップ(探索済みのマスだけを表示)
struct AutoMapView: View {
    let map: MapData
    let explored: Set<GridPos>
    let player: Player

    var body: some View {
        Canvas { ctx, size in
            let cols = map.cols
            let rows = map.rows
            let cell = min(size.width / CGFloat(cols), size.height / CGFloat(rows))
            let ox = (size.width - cell * CGFloat(cols)) / 2
            let oy = (size.height - cell * CGFloat(rows)) / 2

            func origin(_ x: Int, _ y: Int) -> CGPoint {
                CGPoint(x: ox + cell * CGFloat(x), y: oy + cell * CGFloat(y))
            }
            let sides: [(dx: Int, dy: Int)] = [(0, -1), (1, 0), (0, 1), (-1, 0)]

            for pos in explored {
                let o = origin(pos.x, pos.y)
                let r = CGRect(x: o.x, y: o.y, width: cell, height: cell)

                // 到達したマスだけ緑に色づけし、特殊地点は控えめな色で区別する
                let floorColor: Color
                switch map.cell(at: pos) {
                case .trap:
                    floorColor = Color(red: 0.42, green: 0.15, blue: 0.10)
                case .key:
                    floorColor = Color(red: 0.48, green: 0.34, blue: 0.08)
                case .goal:
                    floorColor = Color(red: 0.48, green: 0.19, blue: 0.12)
                default:
                    floorColor = Color(red: 0.055, green: 0.47, blue: 0.12)
                }
                ctx.fill(Path(r), with: .color(floorColor))

                // 確認済みの壁(そのマスの四辺のうち、隣が壁の辺)
                for k in 0..<4 {
                    let n = sides[k]
                    guard map.isWall(x: pos.x + n.dx, y: pos.y + n.dy) else { continue }
                    var p = Path()
                    switch k {
                    case 0:
                        p.move(to: CGPoint(x: r.minX, y: r.minY))
                        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
                    case 1:
                        p.move(to: CGPoint(x: r.maxX, y: r.minY))
                        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
                    case 2:
                        p.move(to: CGPoint(x: r.minX, y: r.maxY))
                        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
                    default:
                        p.move(to: CGPoint(x: r.minX, y: r.minY))
                        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
                    }
                    ctx.stroke(
                        p,
                        with: .color(Color(red: 0.72, green: 0.67, blue: 0.54)),
                        lineWidth: max(1.2, min(2.5, cell * 0.07))
                    )
                }

                // 到達済みの特殊マスだけ記号を表示(未到達のT/K/Gは出さない)
                if let symbol = map.cell(at: pos).mapSymbol, pos != player.position {
                    let symbolColor: Color
                    switch map.cell(at: pos) {
                    case .trap:
                        symbolColor = Color(red: 1.0, green: 0.66, blue: 0.46)
                    case .key:
                        symbolColor = Color(red: 1.0, green: 0.86, blue: 0.42)
                    case .goal:
                        symbolColor = Color(red: 1.0, green: 0.88, blue: 0.69)
                    default:
                        symbolColor = .white
                    }
                    ctx.draw(
                        Text(symbol)
                            .font(.system(size: cell * 0.6, weight: .bold))
                            .foregroundColor(symbolColor),
                        at: CGPoint(x: r.midX, y: r.midY)
                    )
                }
            }

            // プレイヤーの現在位置(円形カーソル)
            let po = origin(player.position.x, player.position.y)
            let c = CGPoint(x: po.x + cell / 2, y: po.y + cell / 2)
            let cursorDiameter = cell * 0.56
            let cursorRect = CGRect(
                x: c.x - cursorDiameter / 2,
                y: c.y - cursorDiameter / 2,
                width: cursorDiameter,
                height: cursorDiameter
            )
            ctx.fill(
                Path(ellipseIn: cursorRect.insetBy(dx: -cell * 0.045, dy: -cell * 0.045)),
                with: .color(Color.black.opacity(0.78))
            )
            ctx.fill(
                Path(ellipseIn: cursorRect),
                with: .color(Color(red: 1.0, green: 0.94, blue: 0.72))
            )
        }
        .background(Color(red: 0.025, green: 0.024, blue: 0.022))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.48, green: 0.44, blue: 0.36).opacity(0.8), lineWidth: 1.5)
        }
    }
}
