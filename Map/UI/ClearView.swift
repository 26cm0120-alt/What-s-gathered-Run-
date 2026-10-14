import AVFoundation
import SwiftUI

/// クリア表示(仕様書§13.1、UI仕様書§14)。プレイ画面の上に重ねて、画面全体を覆って表示する
struct ClearView: View {
    /// 「スタート画面へ」が押されたときの処理
    let onReturn: () -> Void

    @State private var clearAudioPlayer: AVAudioPlayer?
    @State private var clearAudioErrorDelegate: AudioPlaybackErrorDelegate?
    @State private var isCelebrating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DungeonBackground()

                VictoryBurst()
                    .opacity(0.42)
                    .ignoresSafeArea()

                RoundedRectangle(cornerRadius: 26)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.55), Color(red: 0.92, green: 0.70, blue: 0.30), Color.white.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .padding(16)

                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color(red: 0.82, green: 0.63, blue: 0.28).opacity(0.38), lineWidth: 1)
                    .padding(24)

                VStack(spacing: 0) {
                    Spacer(minLength: 24)

                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                        Text("DUNGEON CONQUERED")
                            .tracking(3)
                        Image(systemName: "sparkles")
                    }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.94, green: 0.75, blue: 0.36))

                    ZStack {
                        Circle()
                            .fill(Color(red: 0.88, green: 0.63, blue: 0.22).opacity(0.13))
                            .frame(width: 112, height: 112)
                        Circle()
                            .stroke(Color(red: 0.96, green: 0.75, blue: 0.34).opacity(0.85), lineWidth: 2)
                            .frame(width: 92, height: 92)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 43, weight: .black))
                            .foregroundStyle(LinearGradient(
                                colors: [Color(red: 1.0, green: 0.88, blue: 0.52), Color(red: 0.78, green: 0.48, blue: 0.12)],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                    }
                    .scaleEffect(isCelebrating ? 1.06 : 0.96)
                    .shadow(color: Color(red: 1.0, green: 0.67, blue: 0.18).opacity(0.65), radius: isCelebrating ? 30 : 12)
                    .padding(.top, 22)
                    .padding(.bottom, 14)

                    Text("おめでとう!")
                        .font(.system(size: min(geometry.size.width * 0.145, 58), weight: .black, design: .serif))
                        .tracking(2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .foregroundStyle(LinearGradient(
                            colors: [Color(red: 1.0, green: 0.91, blue: 0.62), Color(red: 0.94, green: 0.68, blue: 0.24), Color(red: 0.76, green: 0.43, blue: 0.10)],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .shadow(color: Color(red: 1.0, green: 0.66, blue: 0.18).opacity(0.7), radius: isCelebrating ? 24 : 8)

                    Text("VICTORY")
                        .font(.system(size: 23, weight: .black, design: .serif))
                        .tracking(9)
                        .foregroundStyle(Color.white.opacity(0.92))
                        .padding(.top, 8)

                    HStack(spacing: 12) {
                        Rectangle().fill(Color(red: 0.80, green: 0.62, blue: 0.30).opacity(0.75)).frame(height: 1)
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color(red: 0.95, green: 0.75, blue: 0.35))
                        Rectangle().fill(Color(red: 0.80, green: 0.62, blue: 0.30).opacity(0.75)).frame(height: 1)
                    }
                    .frame(maxWidth: 250)
                    .padding(.vertical, 18)

                    Text("ゲームクリア")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundStyle(.white)

                    Text("迷宮の試練を突破した")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.70))
                        .padding(.top, 8)

                    Spacer(minLength: 24)

                    Button(action: onReturn) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.uturn.backward")
                            Text("スタート画面へ")
                        }
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .foregroundStyle(Color(red: 0.12, green: 0.09, blue: 0.04))
                        .background(LinearGradient(
                            colors: [Color(red: 1.0, green: 0.85, blue: 0.49), Color(red: 0.78, green: 0.53, blue: 0.18)],
                            startPoint: .top,
                            endPoint: .bottom
                        ), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.68), lineWidth: 1))
                    }
                    .buttonStyle(DungeonPressButtonStyle())
                    .frame(maxWidth: 290)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 38)
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                isCelebrating = true
            }
            guard let player = AudioPlayback.makePlayer(named: "レトロなゲームクリア音") else { return }
            let errorDelegate = AudioPlaybackErrorDelegate(resourceName: "レトロなゲームクリア音")
            player.delegate = errorDelegate
            guard AudioPlayback.play(player, named: "レトロなゲームクリア音") else { return }
            clearAudioPlayer = player
            clearAudioErrorDelegate = errorDelegate
        }
        .onDisappear {
            clearAudioPlayer?.stop()
            clearAudioPlayer = nil
            clearAudioErrorDelegate = nil
        }
    }
}

/// 迷宮RPGらしい光の放射を描き、クリアした瞬間の高揚感を加える。
private struct VictoryBurst: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let rayCount = 28
            let radius = hypot(size.width, size.height)

            for index in 0..<rayCount {
                let angle = CGFloat(index) / CGFloat(rayCount) * 2 * .pi
                let innerRadius = index.isMultiple(of: 2) ? radius * 0.12 : radius * 0.24
                let outerRadius = radius * 0.86
                var ray = Path()
                ray.move(to: CGPoint(x: center.x + cos(angle) * innerRadius, y: center.y + sin(angle) * innerRadius))
                ray.addLine(to: CGPoint(x: center.x + cos(angle) * outerRadius, y: center.y + sin(angle) * outerRadius))
                context.stroke(ray, with: .color(Color(red: 0.98, green: 0.72, blue: 0.28).opacity(index.isMultiple(of: 2) ? 0.25 : 0.11)), lineWidth: index.isMultiple(of: 2) ? 2 : 1)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
