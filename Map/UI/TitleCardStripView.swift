import SwiftUI

/// タイトル画面の、しりとりカードを小さく5枚並べた帯。
/// 左端から1枚ずつ、別のカードへランダムに切り替わり、右端まで来たら左端に戻って繰り返す。
struct TitleCardStripView: View {
    var compact = false

    private static let slotCount = 5

    /// ゲームで使うカード画像名(重複なし)
    private static let pool: [String] = {
        Array(Set((CardData.cards + CardData2.cards).map(\.imageName))).sorted()
    }()

    @State private var names: [String] = Array(TitleCardStripView.pool.shuffled().prefix(TitleCardStripView.slotCount))
    @State private var angles: [Double] = Array(repeating: 0, count: TitleCardStripView.slotCount)

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var running: Bool { scenePhase == .active }

    private var cardSize: CGFloat { IPadLayoutMetrics.isPad ? 60 : (compact ? 28 : 38) }
    private var spacing: CGFloat { IPadLayoutMetrics.isPad ? 12 : (compact ? 6 : 8) }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(names.indices, id: \.self) { index in
                cardView(names[index])
                    .rotation3DEffect(.degrees(angles[index]), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            }
        }
        .frame(maxWidth: IPadLayoutMetrics.startContentWidth)
        .accessibilityHidden(true)
        .task(id: running) {
            guard running else { return }
            await loop()
        }
    }

    private func cardView(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .padding(2)
            .frame(width: cardSize, height: cardSize)
            .background(Color.black, in: RoundedRectangle(cornerRadius: 3))
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color(red: 0.67, green: 0.57, blue: 0.36).opacity(0.85), lineWidth: 1.2)
            }
    }

    /// 左端(0枚目)から順に1枚ずつ入れ替える。
    private func loop() async {
        var slot = 0
        while !Task.isCancelled {
            await pause(800)
            guard !Task.isCancelled else { return }
            await replaceCard(at: slot)
            slot = (slot + 1) % Self.slotCount
        }
    }

    /// 今並んでいない別のカードへ、横回転で切り替える。
    private func replaceCard(at slot: Int) async {
        guard let next = Self.pool.filter({ !names.contains($0) }).randomElement() else { return }
        if reduceMotion {
            names[slot] = next
            return
        }
        withAnimation(.easeIn(duration: 0.14)) { angles[slot] = 90 }
        await pause(150)
        guard !Task.isCancelled else {
            angles[slot] = 0
            return
        }
        names[slot] = next
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) { angles[slot] = -90 }
        withAnimation(.easeOut(duration: 0.14)) { angles[slot] = 0 }
        await pause(150)
    }

    private func pause(_ milliseconds: UInt64) async {
        try? await Task.sleep(nanoseconds: milliseconds * 1_000_000)
    }
}
