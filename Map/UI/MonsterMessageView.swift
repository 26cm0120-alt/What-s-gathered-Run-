import SwiftUI

/// 状況メッセージの隣で呼吸し、プレイヤーの移動や旋回に合わせて跳ねるPlayer。
struct MonsterMessageView: View {
    let message: String
    let reactionID: Int
    let surpriseReactionID: Int
    let isTutorial: Bool

    @State private var isBreathing = false
    @State private var actionFrame: String?
    @State private var reactionTask: Task<Void, Never>?
    @State private var collisionShakeOffset: CGFloat = 0
    @State private var collisionTilt: Double = 0
    @State private var isSurprised = false

    private var imageName: String {
        if isSurprised { return "PlayerBlink" }
        return actionFrame ?? (isBreathing ? "PlayerBreath" : "PlayerIdle")
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(isTutorial ? 3 : 2)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack(alignment: .topTrailing) {
                Image(imageName)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 78, height: 74)
                    .offset(x: collisionShakeOffset)
                    .rotationEffect(.degrees(collisionTilt))
                    .accessibilityHidden(true)
                    .animation(.easeInOut(duration: 0.08), value: imageName)

                if isSurprised {
                    Text("!")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.24))
                        .shadow(color: .black, radius: 2, y: 1)
                        .offset(x: -4, y: 2)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(Color(red: 0.075, green: 0.07, blue: 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.42, green: 0.39, blue: 0.32), lineWidth: 1)
        }
        .onChange(of: reactionID) { _, _ in
            playMovementAnimation()
        }
        .onChange(of: surpriseReactionID) { _, _ in
            playSurpriseAnimation()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 750_000_000)
                guard !Task.isCancelled else { break }
                isBreathing.toggle()
            }
        }
        .onDisappear {
            reactionTask?.cancel()
        }
    }

    private func playMovementAnimation() {
        reactionTask?.cancel()
        isSurprised = false
        collisionShakeOffset = 0
        collisionTilt = 0
        reactionTask = Task { @MainActor in
            for frame in ["PlayerMove1", "PlayerMove2", "PlayerMove3"] {
                guard !Task.isCancelled else { return }
                actionFrame = frame
                try? await Task.sleep(nanoseconds: 110_000_000)
            }
            guard !Task.isCancelled else { return }
            actionFrame = nil
        }
    }

    private func playSurpriseAnimation() {
        reactionTask?.cancel()
        reactionTask = Task { @MainActor in
            isSurprised = true
            let reactions: [(CGFloat, Double, String)] = [
                (-6, -11, "PlayerBlink"),
                (7, 9, "PlayerIdle"),
                (-4, -6, "PlayerBlink"),
                (2, 3, "PlayerIdle"),
                (0, 0, "PlayerBlink")
            ]

            for (offset, tilt, frame) in reactions {
                guard !Task.isCancelled else { return }
                actionFrame = frame
                withAnimation(.spring(response: 0.075, dampingFraction: 0.48)) {
                    collisionShakeOffset = offset
                    collisionTilt = tilt
                }
                try? await Task.sleep(nanoseconds: 85_000_000)
            }

            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.18, dampingFraction: 0.62)) {
                collisionShakeOffset = 0
                collisionTilt = 0
                isSurprised = false
            }
            actionFrame = nil
        }
    }
}
