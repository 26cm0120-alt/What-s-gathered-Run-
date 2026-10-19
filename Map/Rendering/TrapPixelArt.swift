import SwiftUI

/// 実装済みトラップの探索マップ・3D床表示で共有するドット絵。
enum TrapPixelArt {
    static func kind(at position: GridPos, in map: MapData) -> TrapKind? {
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

    /// Gitに実装されている8種類だけを描画対象とする。
    static func pixels(for kind: TrapKind) -> [String] {
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

    static func palette(for kind: TrapKind) -> [Character: Color] {
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
}
