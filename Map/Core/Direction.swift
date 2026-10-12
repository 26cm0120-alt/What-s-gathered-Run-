import Foundation

/// プレイヤーの向き(北・東・南・西)
enum Direction: Int {
    case north = 0
    case east = 1
    case south = 2
    case west = 3

    /// この向きへ1マス進んだときの x の増減
    var dx: Int {
        switch self {
        case .north: return 0
        case .east:  return 1
        case .south: return 0
        case .west:  return -1
        }
    }

    /// この向きへ1マス進んだときの y の増減(北は y が減る)
    var dy: Int {
        switch self {
        case .north: return -1
        case .east:  return 0
        case .south: return 1
        case .west:  return 0
        }
    }

    var turnedLeft: Direction { Direction(rawValue: (rawValue + 3) % 4) ?? self }
    var turnedRight: Direction { Direction(rawValue: (rawValue + 1) % 4) ?? self }
    /// 180度反転(トラップで使用)
    var reversed: Direction { Direction(rawValue: (rawValue + 2) % 4) ?? self }
}
