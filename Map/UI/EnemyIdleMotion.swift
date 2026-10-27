import SwiftUI

/// 戦闘とタイトルで共通の待機動作。反応中は停止し、復帰時には同じ位相から続ける。
struct EnemyIdleMotion: ViewModifier {
    let kind: EnemyKind
    var enabled = true
    var intensity: CGFloat = 1
    var phaseOffset: Double = 0

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var elapsed = 0.0

    private var running: Bool { enabled && scenePhase == .active && !reduceMotion }

    private var pose: (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, angle: Double) {
        guard enabled && !reduceMotion else { return (0, 0, 1, 1, 0) }
        let wave = sin(elapsed * .pi * 2 / period + phaseOffset)
        let lift = (wave + 1) / 2
        switch kind {
        case .slime: return (0, 0, 1 + 0.055 * wave, 1 - 0.065 * wave, 0)
        case .skeleton: return (1.5 * wave, 0, 1, 1, 1.4 * wave)
        case .gargoyle: return (0, -3 * lift, 1 + 0.018 * wave, 1 + 0.025 * wave, 0)
        case .imp: return (2 * wave, -6 * lift, 1, 1 + 0.02 * wave, 2 * wave)
        case .ghost: return (4 * wave, -9 * lift, 1 + 0.025 * wave, 1 - 0.025 * wave, 3 * wave)
        case .cyclops: return (0, 0, 1 + 0.022 * wave, 1 + 0.035 * lift, 0.7 * wave)
        case .mimic: return (0, -2 * lift, 1 + 0.025 * wave, 1 - 0.03 * wave, 2 * wave)
        case .dragon: return (0, 0, 1 + 0.02 * lift, 1 + 0.035 * lift, 0)
        }
    }

    private var period: Double {
        switch kind {
        case .slime: 1.5
        case .skeleton: 2.4
        case .gargoyle: 2.8
        case .imp: 1.8
        case .ghost: 3.2
        case .cyclops: 3.0
        case .mimic: 2.0
        case .dragon: 2.6
        }
    }

    func body(content: Content) -> some View {
        let pose = pose
        content
            .scaleEffect(x: 1 + (pose.width - 1) * intensity,
                         y: 1 + (pose.height - 1) * intensity, anchor: .bottom)
            .rotationEffect(.degrees(pose.angle * Double(intensity)), anchor: .bottom)
            .offset(x: pose.x * intensity, y: pose.y * intensity)
            .task(id: running) {
                guard running else { return }
                // 自動反復アニメーションを残さず、非表示・中断時はタスクを終了する。
                while !Task.isCancelled {
                    do { try await Task.sleep(nanoseconds: 33_333_333) }
                    catch { return }
                    elapsed += 1.0 / 30
                }
            }
    }
}
