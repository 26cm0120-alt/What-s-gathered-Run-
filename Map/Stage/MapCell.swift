import Foundation

/// マップの1マス(仕様書§5.3 マス方式)
enum MapCell: Equatable {
    case wall
    case floor
    case start
    case trap
    case key
    case goal

    /// マップ定義の1文字から作る。# = 壁、S/T/K/G = 特殊マス、それ以外 = 床
    init(_ character: Character) {
        switch character {
        case "#": self = .wall
        case "S": self = .start
        case "T": self = .trap
        case "K": self = .key
        case "G": self = .goal
        default:  self = .floor
        }
    }

    var isWall: Bool { self == .wall }

    /// オートマップに(到達後のみ)表示する記号
    var mapSymbol: String? {
        switch self {
        case .trap: return "T"
        case .key:  return "K"
        case .goal: return "G"
        case .wall, .floor, .start: return nil
        }
    }
}
