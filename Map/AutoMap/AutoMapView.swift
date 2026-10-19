import SwiftUI

// MARK: - オートマップ(探索済みのマスだけを表示)
struct AutoMapView: View {
    let map: MapData
    let explored: Set<GridPos>
    let player: Player
    let defeatedEnemies: Set<GridPos>
    let defeatedEnemyKinds: [GridPos: EnemyKind]

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
                case .sword:
                    floorColor = Color(red: 0.08, green: 0.24, blue: 0.38)
                case .trap, .doubleFlickTrap, .hpDrainTrap, .warpToStartTrap, .randomWarpTrap, .keyFrontWarpTrap, .gameOverTrap, .unexplodedTrap:
                    floorColor = Color(red: 0.42, green: 0.15, blue: 0.10)
                case .key:
                    floorColor = Color(red: 0.48, green: 0.34, blue: 0.08)
                case .enemy:
                    floorColor = defeatedEnemies.contains(pos)
                        ? Color(red: 0.055, green: 0.47, blue: 0.12)
                        : Color(red: 0.40, green: 0.10, blue: 0.16)
                case .goal:
                    floorColor = Color(red: 0.48, green: 0.19, blue: 0.12)
                default:
                    floorColor = Color(red: 0.055, green: 0.47, blue: 0.12)
                }
                ctx.fill(Path(r), with: .color(floorColor))

                if map.cell(at: pos) == .key {
                    let iconRect = r.insetBy(dx: cell * 0.14, dy: cell * 0.14)
                    drawPixelIcon(chestPixels, in: iconRect, context: &ctx, palette: chestPalette)
                } else if map.cell(at: pos) == .sword {
                    let iconRect = r.insetBy(dx: cell * 0.20, dy: cell * 0.10)
                    drawPixelIcon(swordPixels, in: iconRect, context: &ctx, palette: swordPalette)
                } else if let trapKind = trapKind(at: pos) {
                    let iconRect = r.insetBy(dx: cell * 0.14, dy: cell * 0.14)
                    drawPixelIcon(
                        trapPixels(for: trapKind),
                        in: iconRect,
                        context: &ctx,
                        palette: trapPalette(for: trapKind)
                    )
                } else if map.cell(at: pos) == .enemy {
                    let kind = defeatedEnemyKinds[pos]
                        ?? map.enemyKinds[pos]
                        ?? EnemyKind.encounter(seed: nil, position: pos)
                    drawEnemySprite(
                        kind,
                        defeated: defeatedEnemies.contains(pos),
                        in: r.insetBy(dx: cell * 0.10, dy: cell * 0.10),
                        context: &ctx
                    )
                }

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
                if let symbol = map.cell(at: pos).mapSymbol,
                   pos != player.position,
                   map.cell(at: pos) != .key,
                   !map.cell(at: pos).isTrap,
                   map.cell(at: pos) != .enemy {
                    let symbolColor: Color
                    switch map.cell(at: pos) {
                    case .trap, .doubleFlickTrap, .hpDrainTrap, .warpToStartTrap, .randomWarpTrap, .keyFrontWarpTrap, .gameOverTrap, .unexplodedTrap:
                        symbolColor = Color(red: 1.0, green: 0.66, blue: 0.46)
                    case .key:
                        symbolColor = Color(red: 1.0, green: 0.86, blue: 0.42)
                    case .enemy:
                        symbolColor = Color(red: 1.0, green: 0.48, blue: 0.48)
                    case .goal:
                        symbolColor = Color(red: 1.0, green: 0.88, blue: 0.69)
                    default:
                        symbolColor = .white
                    }
                    ctx.draw(
                        Text(symbol)
                            .font(DungeonTypography.maruMonica(size: cell * 0.6))
                            .foregroundColor(symbolColor),
                        at: CGPoint(x: r.midX, y: r.midY)
                    )
                }
            }

            // プレイヤーの現在位置を青いミニドラゴンで表示する。
            let po = origin(player.position.x, player.position.y)
            let dragonRect = CGRect(
                x: po.x + cell * 0.10,
                y: po.y + cell * 0.10,
                width: cell * 0.80,
                height: cell * 0.80
            )
            drawPixelIcon(dragonPixels, in: dragonRect, context: &ctx, palette: dragonPalette)
        }
        .background(Color(red: 0.025, green: 0.024, blue: 0.022))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.48, green: 0.44, blue: 0.36).opacity(0.8), lineWidth: 1.5)
        }
    }

    // MARK: - ドット絵アイコン

    private var chestPixels: [String] {
        ["..OOOOOO..", ".OCCCCCCO.", "OCCCCCCCCO", "OBBBBBBBBO", "OGGGGGGGGO",
         "OBBBOBBBBO", "OBBBOBBBBO", "OGGGGGGGGO", ".OBBBBBBO.", "..OOOOOO.."]
    }

    private var swordPixels: [String] {
        ["....BB....", "...BB.....", "..BB......", ".BB.......", "BB........",
         ".GGGG.....", "...GG.....", "...HH.....", "..HHHH....", "..HHHH...."]
    }

    private var dragonPixels: [String] {
        ["....OO....", "...OBBO...", ".OOBBBBOO.", "OOBBBBBBBO", "OBBBYBBBBB",
         ".OBBBBBBO.", "..OBBBBO..", ".OBB..BBO.", "OBB....BBO", "OO......OO"]
    }

    private var chestPalette: [Character: Color] {
        ["O": Color(red: 0.16, green: 0.075, blue: 0.035),
         "C": Color(red: 0.72, green: 0.39, blue: 0.13),
         "B": Color(red: 0.48, green: 0.22, blue: 0.075),
         "G": Color(red: 1.0, green: 0.78, blue: 0.24)]
    }

    private func trapKind(at position: GridPos) -> TrapKind? {
        switch map.cell(at: position) {
        case .trap:
            return map.trapKinds[position] ?? .turnRight
        case .doubleFlickTrap:
            return .doubleFlick
        case .hpDrainTrap:
            return .hpDrain
        case .warpToStartTrap:
            return .warpToStart
        case .randomWarpTrap:
            return .randomWarp
        case .keyFrontWarpTrap:
            return .warpBeforeKey
        case .gameOverTrap:
            return .forceGameOver
        case .unexplodedTrap:
            return .unexploded
        default:
            return nil
        }
    }

    /// 現在Gitに実装されているトラップだけを、種類ごとのドット絵にする。
    private func trapPixels(for kind: TrapKind) -> [String] {
        let frame = [
            "....II....", "...IIII...", "..I....I..", ".I......I.", "IIIIIIIIII",
            ".ODDDDDDO.", ".ODDDDDDO.", "..ODDDDO..", "...OOOO...", ".........."
        ]
        let glyph: [String]
        switch kind {
        case .turnRight:
            glyph = ["...M..", "....M.", "MMMMMM", "....M.", "...M.."]
        case .doubleFlick:
            glyph = ["M.M...", ".M.M..", "MMMMMM", ".M.M..", "M.M..."]
        case .hpDrain:
            glyph = ["..MM..", ".MMMM.", "MMMMMM", ".MMMM.", "..MM.."]
        case .warpToStart:
            glyph = ["..MM..", ".M..M.", "M....M", "MMMMMM", "M....M"]
        case .randomWarp:
            glyph = ["M...M.", ".M.M..", "..M...", "MMMMMM", "..M..."]
        case .warpBeforeKey:
            glyph = [".MMM..", "..M...", "MMMM..", "..M.M.", "MMMM.."]
        case .forceGameOver:
            glyph = ["M....M", ".M..M.", "..MM..", "..MM..", ".M..M."]
        case .unexploded:
            glyph = ["..MMM.", ".M...M", ".M.M.M", "..M...", "..MMM."]
        }

        var pixels = frame.map { Array($0) }
        for (row, glyphLine) in glyph.enumerated() {
            for (column, marker) in glyphLine.enumerated() where marker == "M" {
                pixels[row + 4][column + 2] = marker
            }
        }
        return pixels.map { String($0) }
    }

    private func trapPalette(for kind: TrapKind) -> [Character: Color] {
        let markerColor: Color
        switch kind {
        case .turnRight: markerColor = Color(red: 0.34, green: 0.88, blue: 1.0)
        case .doubleFlick: markerColor = Color(red: 1.0, green: 0.78, blue: 0.25)
        case .hpDrain: markerColor = Color(red: 0.45, green: 1.0, blue: 0.46)
        case .warpToStart: markerColor = Color(red: 0.8, green: 0.62, blue: 1.0)
        case .randomWarp: markerColor = Color(red: 0.45, green: 0.75, blue: 1.0)
        case .warpBeforeKey: markerColor = Color(red: 1.0, green: 0.86, blue: 0.38)
        case .forceGameOver: markerColor = Color(red: 1.0, green: 0.25, blue: 0.22)
        case .unexploded: markerColor = Color(red: 0.92, green: 0.9, blue: 0.72)
        }
        return [
            "I": Color(red: 0.83, green: 0.82, blue: 0.72),
            "O": Color(red: 0.12, green: 0.08, blue: 0.07),
            "D": Color(red: 0.45, green: 0.19, blue: 0.12),
            "R": Color(red: 0.96, green: 0.28, blue: 0.16),
            "M": markerColor
        ]
    }

    private func drawEnemySprite(
        _ kind: EnemyKind,
        defeated: Bool,
        in rect: CGRect,
        context: inout GraphicsContext
    ) {
        let imageName = defeated ? kind.defeatedImageName : kind.imageName
        let image = context.resolve(Image(imageName).interpolation(.none))
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }

        let scale = min(rect.width / imageSize.width, rect.height / imageSize.height)
        let fittedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let fittedRect = CGRect(
            x: rect.midX - fittedSize.width / 2,
            y: rect.midY - fittedSize.height / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
        context.draw(image, in: fittedRect)
    }

    private var swordPalette: [Character: Color] {
        ["B": Color(red: 0.72, green: 0.88, blue: 1.0),
         "G": Color(red: 1.0, green: 0.79, blue: 0.25),
         "H": Color(red: 0.43, green: 0.20, blue: 0.08)]
    }

    private var dragonPalette: [Character: Color] {
        ["O": Color(red: 0.02, green: 0.08, blue: 0.24),
         "B": Color(red: 0.08, green: 0.46, blue: 0.92),
         "Y": Color(red: 1.0, green: 0.86, blue: 0.32)]
    }

    private func drawPixelIcon(
        _ pixels: [String],
        in rect: CGRect,
        context: inout GraphicsContext,
        palette: [Character: Color]
    ) {
        guard let columns = pixels.first?.count, columns > 0 else { return }
        let pixelWidth = rect.width / CGFloat(columns)
        let pixelHeight = rect.height / CGFloat(pixels.count)

        for (row, line) in pixels.enumerated() {
            for (column, pixel) in line.enumerated() {
                guard let color = palette[pixel] else { continue }
                let pixelRect = CGRect(
                    x: rect.minX + CGFloat(column) * pixelWidth,
                    y: rect.minY + CGFloat(row) * pixelHeight,
                    width: pixelWidth,
                    height: pixelHeight
                )
                context.fill(Path(pixelRect), with: .color(color))
            }
        }
    }
}
