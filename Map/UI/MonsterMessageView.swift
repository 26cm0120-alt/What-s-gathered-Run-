import SwiftUI

/// 状況メッセージの隣で呼吸し、プレイヤーの移動や旋回に合わせて跳ねるPlayer。
struct MonsterMessageView: View {
    let message: String
    let reactionID: Int

    @State private var isBreathing = false
    @State private var actionFrame: String?
    @State private var reactionTask: Task<Void, Never>?

    private var imageName: String {
        actionFrame ?? (isBreathing ? "PlayerBreath" : "PlayerIdle")
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(2)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(imageName)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 78, height: 74)
                .accessibilityHidden(true)
                .animation(.easeInOut(duration: 0.08), value: imageName)
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
}
