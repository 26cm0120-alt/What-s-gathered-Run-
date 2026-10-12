import SwiftUI

/// タイトルの紹介文の下で、CPUとPlayerの2キャラクターを別々にアニメーション表示する。
struct AnimatedTitleMonsterView: View {
    var body: some View {
        HStack(spacing: 22) {
            AnimatedCharacterLoop(
                label: "CPU",
                frames: [
                    ("MessageMonsterIdle", 850_000_000),
                    ("MessageMonsterBreath", 500_000_000),
                    ("MessageMonsterIdle", 350_000_000),
                    ("MessageMonsterMove1", 110_000_000),
                    ("MessageMonsterMove2", 110_000_000),
                    ("MessageMonsterMove3", 260_000_000)
                ]
            )
            AnimatedCharacterLoop(
                label: "Player",
                frames: [
                    ("PlayerIdle", 900_000_000),
                    ("PlayerBlink", 180_000_000),
                    ("PlayerBreath", 500_000_000),
                    ("PlayerIdle", 300_000_000),
                    ("PlayerMove1", 110_000_000),
                    ("PlayerMove2", 110_000_000),
                    ("PlayerMove3", 260_000_000)
                ]
            )
        }
        .frame(height: 68)
    }
}

private struct AnimatedCharacterLoop: View {
    let label: String
    let frames: [(image: String, duration: UInt64)]
    @State private var currentImage: String

    init(label: String, frames: [(image: String, duration: UInt64)]) {
        self.label = label
        self.frames = frames
        _currentImage = State(initialValue: frames[0].image)
    }

    var body: some View {
        Image(currentImage)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: 92, height: 68)
            .accessibilityLabel("タイトルの\(label)キャラクター")
            .animation(.easeInOut(duration: 0.08), value: currentImage)
            .task {
                while !Task.isCancelled {
                    for frame in frames {
                        guard !Task.isCancelled else { return }
                        currentImage = frame.image
                        try? await Task.sleep(nanoseconds: frame.duration)
                    }
                }
            }
    }
}
