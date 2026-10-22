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

/// フリック操作、戦闘コマンド、ギブアップを表示する。
struct CommandView: View {
    let onTurnLeft: () -> Void
    let onForward: () -> Void
    let onTurnRight: () -> Void
    let onTurnAround: () -> Void
    @Binding var activeFlickDirection: MovementFlickDirection?
    let onFlickEnded: (MovementFlickDirection) -> Void
    let onGiveUp: () -> Void
    let isBattling: Bool
    let isMovementDisabled: Bool
    let isBattleActionDisabled: Bool
    let onBattleAttack: () -> Void
    let onBattleFlee: () -> Void
    /// 計時対象ステージの開始時刻。戦闘中は表示を隠すが計測は継続する。
    let timerStartedAt: TimeInterval?
    let timerReductionSeconds: Int

    var body: some View {
        VStack(spacing: 8) {
            if !isBattling {
                flickControl
                    .allowsHitTesting(!isMovementDisabled)
                    .opacity(isMovementDisabled ? 0.55 : 1)
            }

            HStack(spacing: 7) {
                if isBattling {
                    Button(action: onBattleAttack) {
                        Text("こうげき")
                            .font(DungeonTypography.maruMonica(size: 13))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(DungeonPressButtonStyle())
                    .disabled(isBattleActionDisabled)

                    Button(action: onBattleFlee) {
                        Text("にげる")
                            .font(DungeonTypography.maruMonica(size: 13))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(DungeonPressButtonStyle())
                    .disabled(isBattleActionDisabled)
                } else {
                    if let timerStartedAt {
                        DungeonRunTimer(startedAt: timerStartedAt, reductionSeconds: timerReductionSeconds)
                    } else {
                        Spacer(minLength: 0)
                    }
                    Spacer(minLength: 0)
                }

                Button(action: onGiveUp) {
                    Text("ギブアップ")
                        .font(DungeonTypography.maruMonica(size: 14))
                        .frame(width: 112, height: 44)
                }
                .buttonStyle(DungeonPressButtonStyle())
            }
        }
    }

    private var flickControl: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.075, green: 0.07, blue: 0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.67, green: 0.57, blue: 0.36).opacity(0.8), lineWidth: 1.5)
                }

            HStack(spacing: 10) {
                Text("フリック")
                    .font(DungeonTypography.maruMonica(size: 13))
                    .foregroundColor(Color(red: 0.89, green: 0.78, blue: 0.49))

                Image(systemName: "arrow.up")
                    .font(DungeonTypography.maruMonica(size: 24))
                    .foregroundColor(Color(red: 0.93, green: 0.75, blue: 0.29))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(activeFlickDirection?.rotationDegrees ?? 0))
                    .animation(.easeOut(duration: 0.12), value: activeFlickDirection)

                Text("上：前進　下：反対を向く\n左右：向きを変える")
                    .font(DungeonTypography.maruMonica(size: 12))
                    .foregroundColor(.white.opacity(0.82))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    guard !isMovementDisabled else { return }
                    if let direction = MovementFlickDirection.classify(
                        horizontal: value.translation.width,
                        vertical: value.translation.height,
                        threshold: 16
                    ) {
                        activeFlickDirection = direction
                    }
                }
                .onEnded { value in
                    guard !isMovementDisabled,
                          let direction = MovementFlickDirection.classify(
                        horizontal: value.translation.width,
                        vertical: value.translation.height,
                        threshold: 16
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
    }
}

/// 探索中にコマンド領域の左側へ経過時間を表示する。
private struct DungeonRunTimer: View {
    let startedAt: TimeInterval
    let reductionSeconds: Int

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 0.1)) { _ in
            let elapsedText = DungeonTimeFormatter.string(
                from: ProcessInfo.processInfo.systemUptime - startedAt - TimeInterval(reductionSeconds)
            )
            HStack(spacing: 5) {
                Image(systemName: "stopwatch")
                    .font(DungeonTypography.maruMonica(size: 12))
                Text(elapsedText)
                .font(DungeonTypography.maruMonica(size: 13))
                .monospacedDigit()
            }
            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.45))
            .padding(.horizontal, 9)
            .frame(height: 36)
            .background(Color.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: 0.67, green: 0.57, blue: 0.36).opacity(0.75), lineWidth: 1)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("経過時間 \(elapsedText)")
        }
    }
}
