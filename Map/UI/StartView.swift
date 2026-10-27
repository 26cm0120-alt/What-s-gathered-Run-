import SwiftUI

/// スタート画面。石造りの門と古い金色の装飾で、クラシックな迷宮RPGの雰囲気を表現する。
struct StartView: View {
    /// 選べる面の一覧(表示順)
    let stages: [Stage]
    /// 前回のランダムステージseed。再挑戦に使う
    let lastRandomSeed: UInt64?
    /// 面が選ばれたときの処理
    let onSelect: (Stage) -> Void
    /// 新しいランダムステージを始める処理
    let onRandomStage: () -> Void
    /// 前回のseedで同じランダムステージを始める処理
    let onReplayRandomStage: (UInt64) -> Void
    /// 音量設定が変わったときの処理(再生中のBGMへ反映する)
    var onAudioVolumeChanged: () -> Void = {}

    @State private var isShowingAudioSettings = false

    var body: some View {
        GeometryReader { geometry in
            // iPhone 16e の表示領域では通常サイズを使い、特に小さい画面だけ縮小する。
            let compact = geometry.size.height < 700
            ZStack {
                DungeonBackground()

                VStack(spacing: compact ? 3 : 6) {
                    DungeonGateEmblem()
                        .frame(width: compact ? 50 : 64, height: compact ? 44 : 56)
                        .padding(.top, compact ? 2 : 4)

                    // タイトルロゴと、向かい合う2体のドラゴン
                    TitleLogoWithDragons(compact: compact)

                    // しりとりカードが左端から1枚ずつ入れ替わる
                    TitleCardStripView(compact: compact)
                        .padding(.vertical, compact ? 1 : 4)

                    VStack(spacing: compact ? 3 : 6) {
                        Text("ファミコン時代の Wizardry・女神転生を思わせる、\nグリッド型の3Dダンジョン探索ゲーム")
                            .font(DungeonTypography.maruMonica(size: compact ? 13 : 15))
                            .foregroundStyle(Color.white.opacity(0.78))

                        Text("鍵を見つけてゴールを目指そう\n最短クリアを目指しタイムを競おう！")
                            .font(DungeonTypography.maruMonica(size: compact ? 15 : 17))
                            .foregroundStyle(Color.white.opacity(0.96))
                    }
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: IPadLayoutMetrics.startContentWidth)
                    .padding(.horizontal, compact ? 8 : 14)
                    .padding(.vertical, compact ? 6 : 9)
                    .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.67, green: 0.57, blue: 0.36).opacity(0.48), lineWidth: 1)
                    }

                    // 青ドラゴンが左右の雑魚敵の間を走り、触れた側の敵を倒して入れ替える
                    TitleRunStageView(compact: compact)

                    Text("探索モードを選ぶ")
                        .font(DungeonTypography.maruMonica(size: compact ? 17 : 19))
                        .foregroundStyle(Color(red: 0.89, green: 0.78, blue: 0.49))
                        .frame(maxWidth: IPadLayoutMetrics.startContentWidth, alignment: .leading)
                        .padding(.top, compact ? 0 : 2)

                    VStack(spacing: compact ? 5 : 8) {
                        ForEach(stages.indices, id: \.self) { index in
                            let stage = stages[index]
                            modeButton(
                                title: stage.title,
                                symbol: stage.isStepByStepTutorial ? "book.closed.fill" : "shield.fill",
                                subtitle: stage.isStepByStepTutorial
                                    ? "操作と鍵の取り方を練習"
                                    : "固定マップを探索",
                                compact: compact
                            ) {
                                onSelect(stage)
                            }
                        }

                        modeButton(
                            title: "ランダムステージ",
                            symbol: "shuffle",
                            subtitle: "4つの迷宮と新要素を探索",
                            compact: compact
                        ) {
                            onRandomStage()
                        }

                        if let lastRandomSeed {
                            modeButton(
                                title: "前回の迷宮を再現",
                                symbol: "arrow.clockwise",
                                subtitle: "SEED \(seedText(lastRandomSeed))",
                                compact: compact
                            ) {
                                onReplayRandomStage(lastRandomSeed)
                            }
                        }
                    }
                    .frame(maxWidth: IPadLayoutMetrics.startContentWidth)

                    Text("上フリックで前進、左右で旋回、下で反転。\n鍵を手に入れてゴールへ。")
                        .font(DungeonTypography.maruMonica(size: compact ? 12 : 14))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.white.opacity(0.76))
                        .frame(maxWidth: IPadLayoutMetrics.startContentWidth)
                        .padding(.horizontal, 4)
                        .padding(.bottom, compact ? 3 : 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, compact ? 24 : 26)

                // 古い石碑を思わせる二重の金縁
                GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(red: 0.67, green: 0.57, blue: 0.36).opacity(0.65), lineWidth: 1)
                    .frame(width: max(0, geometry.size.width - 16), height: max(0, geometry.size.height - 16))
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .allowsHitTesting(false)
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    .frame(width: max(0, geometry.size.width - 26), height: max(0, geometry.size.height - 26))
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .allowsHitTesting(false)
                }

                // 右上の音量・振動設定ボタン
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            isShowingAudioSettings = true
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color(red: 0.89, green: 0.78, blue: 0.49))
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.06), in: Circle())
                                .overlay {
                                    Circle().stroke(Color(red: 0.67, green: 0.57, blue: 0.36).opacity(0.55), lineWidth: 1)
                                }
                        }
                        .accessibilityLabel("音量・振動設定")
                    }
                    Spacer()
                }
                .padding(.top, 14)
                .padding(.trailing, 18)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $isShowingAudioSettings) {
            AudioSettingsView(onChange: onAudioVolumeChanged)
        }
    }

    private func modeButton(
        title: String,
        symbol: String,
        subtitle: String,
        compact: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: symbol)
                    .font(DungeonTypography.maruMonica(size: compact ? 16 : 19))
                    .foregroundStyle(Color(red: 0.89, green: 0.78, blue: 0.49))
                    .frame(width: compact ? 32 : 38, height: compact ? 32 : 38)
                    .background(Color.white.opacity(0.06), in: Circle())

                VStack(alignment: .leading, spacing: compact ? 1 : 4) {
                    Text(title)
                        .font(DungeonTypography.maruMonica(size: compact ? 18 : 20))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(Color.white.opacity(0.95))
                    Text(subtitle)
                        .font(DungeonTypography.maruMonica(size: compact ? 12 : 14))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(Color.white.opacity(0.84))
                }
                Spacer(minLength: 6)
                Image(systemName: "chevron.right")
                    .font(DungeonTypography.maruMonica(size: compact ? 14 : 16))
                    .foregroundStyle(Color(red: 0.89, green: 0.78, blue: 0.49))
            }
            .padding(.horizontal, compact ? 10 : 15)
            .frame(maxWidth: .infinity, minHeight: compact ? 58 : 68)
        }
        .buttonStyle(DungeonPressButtonStyle())
    }

    private func seedText(_ seed: UInt64) -> String {
        String(format: "%016llX", seed)
    }
}

/// 石積みのアーチ門と、門に刻まれた小さな紋章を描く。
private struct DungeonGateEmblem: View {
    private let gold = Color(red: 0.77, green: 0.66, blue: 0.42)

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 120, size.height / 108)
            let offset = CGPoint(x: (size.width - 120 * scale) / 2, y: (size.height - 108 * scale) / 2)

            func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
                CGRect(x: offset.x + x * scale, y: offset.y + y * scale, width: width * scale, height: height * scale)
            }
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: offset.x + x * scale, y: offset.y + y * scale)
            }

            // 門を囲む石壁
            context.fill(Path(roundedRect: rect(5, 5, 110, 98), cornerRadius: 5 * scale), with: .color(Color(red: 0.20, green: 0.18, blue: 0.15)))
            for row in 0..<5 {
                let y = CGFloat(9 + row * 19)
                let shift: CGFloat = row.isMultiple(of: 2) ? 0 : 10
                for column in 0..<4 {
                    let x = CGFloat(8 + column * 28) - shift
                    let stone = Path(roundedRect: rect(x, y, 25, 16), cornerRadius: 2 * scale)
                    let shade = 0.22 + Double((row * 3 + column) % 5) * 0.025
                    context.fill(stone, with: .color(Color(red: shade, green: shade * 0.93, blue: shade * 0.82)))
                    context.stroke(stone, with: .color(gold.opacity(0.24)), lineWidth: 0.7 * scale)
                }
            }

            // アーチ状の暗い開口部
            var arch = Path()
            arch.move(to: point(17, 96))
            arch.addLine(to: point(17, 39))
            arch.addQuadCurve(to: point(103, 39), control: point(60, 0))
            arch.addLine(to: point(103, 96))
            arch.closeSubpath()
            context.fill(arch, with: .color(Color(red: 0.045, green: 0.035, blue: 0.027)))
            context.stroke(arch, with: .color(gold), lineWidth: 2 * scale)

            // 閉ざされた扉と木板の縁取り
            let door = Path(roundedRect: rect(27, 48, 66, 48), cornerRadius: 2 * scale)
            context.stroke(door, with: .color(gold.opacity(0.74)), lineWidth: 1.4 * scale)
            for x in [CGFloat(39), 52, 68, 81] {
                var plank = Path()
                plank.move(to: point(x, 51))
                plank.addLine(to: point(x, 93))
                context.stroke(plank, with: .color(gold.opacity(0.36)), lineWidth: 0.8 * scale)
            }

            // 扉の中央に控えめな紋章
            var sigil = Path()
            sigil.move(to: point(60, 57))
            sigil.addLine(to: point(67, 64))
            sigil.addLine(to: point(60, 71))
            sigil.addLine(to: point(53, 64))
            sigil.closeSubpath()
            context.stroke(sigil, with: .color(gold), lineWidth: 1.2 * scale)
        }
        .accessibilityHidden(true)
    }
}
