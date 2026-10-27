import SwiftUI

/// チュートリアルの「探索マップを2本指で広げて拡大する」操作を、動く指のイラストで示す。
/// タッチは受け付けず、下のマップのピンチ操作をそのまま通す。
struct PinchOutHintView: View {
    /// 1回の動きにかかる秒数。
    private let cycle = 2.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let reach = min(geometry.size.width, geometry.size.height) * 0.30

            ZStack {
                // マップの上に重なっても読めるよう、全体を少し暗くする。
                Color.black.opacity(0.28)

                TimelineView(.animation) { timeline in
                    let progress = reduceMotion ? 1.0 : phase(at: timeline.date)
                    let eased = progress * progress * (3 - 2 * progress)
                    let alpha = reduceMotion ? 1.0 : min(1, progress * 5) * min(1, (1 - progress) * 5)
                    // 近い位置から、右上と左下へ向かって離れていく。
                    let start = reach * 0.12
                    let distance = start + (reach - start) * eased
                    let direction = CGVector(dx: 0.72, dy: -0.69)

                    ZStack {
                        // 指の軌跡
                        Path { path in
                            path.move(to: CGPoint(x: center.x - direction.dx * distance, y: center.y - direction.dy * distance))
                            path.addLine(to: CGPoint(x: center.x + direction.dx * distance, y: center.y + direction.dy * distance))
                        }
                        .stroke(
                            Color.white.opacity(0.55 * alpha),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 7])
                        )

                        fingerTip
                            .position(
                                x: center.x + direction.dx * distance,
                                y: center.y + direction.dy * distance
                            )
                            .opacity(alpha)
                        fingerTip
                            .position(
                                x: center.x - direction.dx * distance,
                                y: center.y - direction.dy * distance
                            )
                            .opacity(alpha)

                        // 広がる向きを示す矢印
                        arrow(rotation: -44)
                            .position(
                                x: center.x + direction.dx * (reach + 30),
                                y: center.y + direction.dy * (reach + 30)
                            )
                            .opacity(0.9)
                        arrow(rotation: 136)
                            .position(
                                x: center.x - direction.dx * (reach + 30),
                                y: center.y - direction.dy * (reach + 30)
                            )
                            .opacity(0.9)
                    }
                }

                Text("2本指で広げる")
                    .font(DungeonTypography.maruMonica(size: 20))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.95, green: 0.62, blue: 0.15).opacity(0.92), in: Capsule())
                    .position(x: center.x, y: geometry.size.height - 22)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: 1.0, green: 0.78, blue: 0.25), lineWidth: 3)
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("探索マップの上で、2本指を広げて拡大する")
    }

    private func phase(at date: Date) -> Double {
        date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycle) / cycle
    }

    /// 指先を表す、白い光る円。
    private var fingerTip: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.88))
                .frame(width: 38, height: 38)
            Circle()
                .stroke(Color(red: 1.0, green: 0.78, blue: 0.25), lineWidth: 3)
                .frame(width: 38, height: 38)
        }
        .shadow(color: .black.opacity(0.5), radius: 5)
    }

    private func arrow(rotation: Double) -> some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 26, weight: .heavy))
            .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.40))
            .shadow(color: .black.opacity(0.6), radius: 3)
            .rotationEffect(.degrees(rotation))
    }
}
