import SwiftUI

/// 敵から手前へ飛来する攻撃本体。種類ごとに輪郭・色を変え、着弾時に火花を出す。
struct EnemyCounterattackEffect: View, Animatable {
    let kind: EnemyKind
    var progress: Double
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let p = min(1, max(0, progress))
            let unit = min(size.width, size.height) * (0.012 + p * 0.019)
            let origin = CGPoint(x: size.width * 0.5, y: size.height * (0.43 + 0.25 * p))
            let palette: [Character: Color] = [
                "W": .white, "S": Color(white: 0.7), "D": Color(white: 0.2),
                "Y": .yellow, "O": .orange, "R": .red,
                "P": .purple, "M": .pink, "C": .cyan, "B": .blue,
                "G": .green, "L": Color(red: 0.65, green: 1, blue: 0.2)
            ]
            func pixels(_ rows: [String], x: CGFloat = 0, y: CGFloat = 0, scale: CGFloat = 1) {
                let step = unit * scale
                let width = CGFloat(rows.map(\.count).max() ?? 0) * step
                let height = CGFloat(rows.count) * step
                for (row, text) in rows.enumerated() {
                    for (col, char) in text.enumerated() {
                        guard let color = palette[char] else { continue }
                        let rect = CGRect(x: origin.x + x + CGFloat(col) * step - width / 2,
                                          y: origin.y + y + CGFloat(row) * step - height / 2,
                                          width: step + 0.2, height: step + 0.2)
                        context.fill(Path(rect), with: .color(color))
                    }
                }
            }
            let flame = ["....R....", "...ROR...", "..ROOR...", ".ROYYOR..", "RROYYOOR.", "ROYYWYOOR", ".ROYYOOR.", "..RRRRR.."]
            switch kind {
            case .dragon:
                pixels(flame, x: -unit * 4, y: -unit * 2, scale: 0.7)
                pixels(flame, x: unit * 4, y: -unit * 3, scale: 0.7)
                pixels(flame)
            case .slime:
                pixels(["...GGGG...", "..GLLLLG..", ".GLLLLLLG.", "GLLWLLWLLG", "GLLDLLDLLG", "GLLLLLLLLG", ".GGLLLLGG.", "...GGGG..."])
            case .skeleton:
                pixels([".........WW", "........WWS", ".......WWSD", "......WWSD.", ".....WWSD..", "....WWSD...", "Y..WWSD....", ".YYWSD.....", "..YYY......", "..DDYY.....", ".DD...Y....", "DD........."])
            case .gargoyle:
                for column in 0..<3 {
                    let x = origin.x + CGFloat(column - 1) * unit * 4
                    var slash = Path()
                    slash.move(to: CGPoint(x: x + unit * 3, y: origin.y - unit * 6))
                    slash.addLine(to: CGPoint(x: x - unit * 2, y: origin.y + unit * 6))
                    slash.addLine(to: CGPoint(x: x, y: origin.y - unit * 2))
                    slash.closeSubpath()
                    context.fill(slash, with: .color(.red))
                    context.stroke(slash, with: .color(.white), lineWidth: unit * 0.4)
                }
            case .imp:
                pixels(["M.........M", ".P.......P.", "...PPPPP...", "..PMMMMMP..", ".PMMWWW M P.".replacingOccurrences(of: " ", with: ""), ".PMWWWWMMP.", ".PMMWWWMMP.", "..PMMMMMP..", "...PPPPP...", ".M.......M."])
            case .ghost:
                let wisp = ["...C...", "..CWC..", ".CWWWC.", "CWWDWWC", "CWDD DWC".replacingOccurrences(of: " ", with: ""), ".CWWWC.", "..CWC..", "...C...", "..C...."]
                pixels(wisp, x: -unit * 4, y: -unit * 2, scale: 0.75)
                pixels(wisp, x: unit * 4, y: -unit * 2, scale: 0.75)
                pixels(wisp)
            case .cyclops:
                pixels(["..DDDDDDDD..", ".DGGDGGDGGD.", ".DGLDGLDGLD.", ".DGLDGLDGLD.", "DGGGGGGGGGD.", "DGLGGGGGGGGD", "DGLLGGGGGGGD", ".DGGGGGGGGGD", "..DDGGGGGDD.", "...DGGGGGD..", "...DDDDDDD.."])
            case .mimic:
                let gap = unit * CGFloat(1 - p) * 5
                pixels(["RRRRRRRRRRRR", "RWWRWWRWWRWR", ".W..W..W..W.", ".W..W..W..W."], y: -gap - unit * 2)
                pixels([".W..W..W..W.", "RWWRWWRWWRWR", "RRRRRRRRRRRR", "....RRRR....", ".....RRR...."], y: gap + unit * 2)
            }
            if p > 0.94 {
                for index in 0..<8 {
                    let angle = Double(index) * .pi / 4
                    let a = CGPoint(x: origin.x + cos(angle) * unit * 7,
                                    y: origin.y + sin(angle) * unit * 7)
                    let b = CGPoint(x: origin.x + cos(angle) * unit * 10,
                                    y: origin.y + sin(angle) * unit * 10)
                    var ray = Path(); ray.move(to: a); ray.addLine(to: b)
                    context.stroke(ray, with: .color(.yellow), lineWidth: max(2, unit * 0.65))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
