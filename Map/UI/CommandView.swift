import SwiftUI

/// 押している間、色・枠・大きさを変えて操作を受け付けたことを伝える。
struct DungeonPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                ? Color(red: 0.12, green: 0.43, blue: 0.19)
                : Color(red: 0.075, green: 0.07, blue: 0.06)
            )
            .foregroundColor(configuration.isPressed ? .white : Color.white.opacity(0.9))
            .overlay {
                Rectangle()
                    .stroke(
                        configuration.isPressed
                        ? Color(red: 0.84, green: 0.75, blue: 0.48)
                        : Color(red: 0.58, green: 0.54, blue: 0.45).opacity(0.9),
                        lineWidth: configuration.isPressed ? 2.5 : 1.5
                    )
            }
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.09), value: configuration.isPressed)
    }
}

enum MovementFlickDirection: Equatable {
    case left
    case forward
    case right
    case backward

    var rotationDegrees: Double {
        switch self {
        case .left: return -90
        case .forward: return 0
        case .right: return 90
        case .backward: return 180
        }
    }

    static func classify(horizontal: CGFloat, vertical: CGFloat, threshold: CGFloat) -> Self? {
        guard max(abs(horizontal), abs(vertical)) >= threshold else { return nil }

        if abs(horizontal) > abs(vertical) {
            return horizontal < 0 ? .left : .right
        }
        return vertical < 0 ? .forward : .backward
    }
}

/// ③ フリック操作領域とギブアップ
struct CommandView: View {
    let onTurnLeft: () -> Void
    let onForward: () -> Void
    let onTurnRight: () -> Void
    let onTurnAround: () -> Void
    @Binding var activeFlickDirection: MovementFlickDirection?
    let onFlickEnded: (MovementFlickDirection) -> Void
    /// ギブアップが押されたときの処理(確認の表示は、呼び出し側で行う)
    let onGiveUp: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // 3D画面とマップでも操作できるが、この領域はフリックを始めやすい場所として残す。
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.075, green: 0.07, blue: 0.06))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.67, green: 0.57, blue: 0.36).opacity(0.8), lineWidth: 1.5)
                    }

                HStack(spacing: 10) {
                    Text("フリック")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundColor(Color(red: 0.89, green: 0.78, blue: 0.49))

                    Image(systemName: "arrow.up")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 0.93, green: 0.75, blue: 0.29))
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(activeFlickDirection?.rotationDegrees ?? 0))
                        .animation(.easeOut(duration: 0.12), value: activeFlickDirection)

                    Text("上：前進　下：反対を向く\n左右：向きを変える")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.82))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        if let direction = MovementFlickDirection.classify(
                            horizontal: value.translation.width,
                            vertical: value.translation.height,
                            threshold: 16
                        ) {
                            activeFlickDirection = direction
                        }
                    }
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height

                        guard let direction = MovementFlickDirection.classify(
                            horizontal: horizontal,
                            vertical: vertical,
                            threshold: 28
                        ) else { return }

                        onFlickEnded(direction)
                        switch direction {
                        case .left: onTurnLeft()
                        case .forward: onForward()
                        case .right: onTurnRight()
                        case .backward: onTurnAround()
                        }
                    }
            )

            // ギブアップは、押し間違えにくいよう、フリック領域とは別の右寄せに置く。
            HStack {
                Spacer()
                Button(action: onGiveUp) {
                    Text("ギブアップ")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 120, height: 44)
                }
                .buttonStyle(DungeonPressButtonStyle())
            }
        }
    }

}
