import AVFoundation
import SwiftUI

/// プレイ中の敗北後に表示する共通ゲームオーバー画面。
struct GameOverView: View {
    let onReturn: () -> Void
    let reasonMessage: String
    let detailMessage: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isContentVisible = false
    @State private var isPlayerFallen = false
    @State private var gameOverAudioPlayer: AVAudioPlayer?
    @State private var gameOverAudioErrorDelegate: AudioPlaybackErrorDelegate?

    init(
        onReturn: @escaping () -> Void,
        reasonMessage: String = "HPが0になった",
        detailMessage: String = "迷宮の探索はここで終了です"
    ) {
        self.onReturn = onReturn
        self.reasonMessage = reasonMessage
        self.detailMessage = detailMessage
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DungeonBackground()
                RadialGradient(
                    colors: [
                        Color(red: 0.34, green: 0.045, blue: 0.12).opacity(0.76),
                        Color(red: 0.035, green: 0.02, blue: 0.07).opacity(0.96)
                    ],
                    center: .center,
                    startRadius: 12,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.78
                )
                .ignoresSafeArea()

                RoundedRectangle(cornerRadius: 26)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.52),
                                Color(red: 0.77, green: 0.20, blue: 0.30),
                                Color.white.opacity(0.28)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .padding(16)

                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 24)
                        titleBadge
                        deathEmblem
                            .padding(.top, 24)
                        Text("力尽きた……")
                            .font(DungeonTypography.maruMonica(size: min(geometry.size.width * 0.13, 52)))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                            .foregroundStyle(LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.78, blue: 0.72),
                                    Color(red: 0.91, green: 0.31, blue: 0.39),
                                    Color(red: 0.58, green: 0.12, blue: 0.25)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .shadow(color: Color(red: 0.88, green: 0.16, blue: 0.26).opacity(0.62), radius: 16)

                        Text("GAME OVER")
                            .font(DungeonTypography.maruMonica(size: 23))
                            .tracking(6)
                            .foregroundStyle(.white.opacity(0.92))
                            .padding(.top, 10)

                        ornamentalDivider

                        VStack(spacing: 8) {
                            Text(reasonMessage)
                                .font(DungeonTypography.maruMonica(size: 24))
                                .foregroundStyle(.white)
                            Text(detailMessage)
                                .font(DungeonTypography.maruMonica(size: 17))
                                .foregroundStyle(.white.opacity(0.72))
                        }

                        Spacer(minLength: 34)
                        returnButton
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 34)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height)
                }
                .scrollIndicators(.hidden)
                .opacity(reduceMotion || isContentVisible ? 1 : 0)
                .offset(y: reduceMotion || isContentVisible ? 0 : -12)
            }
        }
        .onAppear {
            playGameOverSound()
            if reduceMotion {
                isContentVisible = true
                isPlayerFallen = true
            } else {
                withAnimation(.easeOut(duration: 0.48)) {
                    isContentVisible = true
                }
                withAnimation(.easeIn(duration: 0.32).delay(0.08)) {
                    isPlayerFallen = true
                }
            }
        }
        .onDisappear {
            gameOverAudioPlayer?.stop()
            gameOverAudioPlayer = nil
            gameOverAudioErrorDelegate = nil
        }
    }

    private var titleBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "diamond.fill")
            Text("DUNGEON OVER")
                .tracking(3)
            Image(systemName: "diamond.fill")
        }
        .font(DungeonTypography.maruMonica(size: 14))
        .foregroundStyle(Color(red: 0.96, green: 0.54, blue: 0.55))
    }

    private var deathEmblem: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.82, green: 0.13, blue: 0.25).opacity(0.16))
                .frame(width: 112, height: 112)
            Circle()
                .stroke(Color(red: 0.94, green: 0.34, blue: 0.40).opacity(0.86), lineWidth: 2)
                .frame(width: 92, height: 92)
            Image("PlayerIdle")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 78, height: 78)
                .rotationEffect(.degrees(isPlayerFallen ? 72 : 0), anchor: .bottom)
                .offset(x: isPlayerFallen ? 8 : 0, y: isPlayerFallen ? 9 : -3)
                .animation(reduceMotion ? nil : .easeIn(duration: 0.32), value: isPlayerFallen)
            Image(systemName: "heart.slash.fill")
                .font(DungeonTypography.maruMonica(size: 19))
                .foregroundStyle(Color(red: 1.0, green: 0.54, blue: 0.57))
                .offset(x: 37, y: 34)
        }
        .shadow(color: Color(red: 0.85, green: 0.13, blue: 0.23).opacity(0.42), radius: 18)
        .padding(.bottom, 18)
    }

    private var ornamentalDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(red: 0.76, green: 0.25, blue: 0.34).opacity(0.78))
                .frame(height: 1)
            Image(systemName: "diamond.fill")
                .font(DungeonTypography.maruMonica(size: 9))
                .foregroundStyle(Color(red: 0.97, green: 0.46, blue: 0.49))
            Rectangle()
                .fill(Color(red: 0.76, green: 0.25, blue: 0.34).opacity(0.78))
                .frame(height: 1)
        }
        .frame(maxWidth: 250)
        .padding(.vertical, 20)
    }

    private var returnButton: some View {
        Button(action: onReturn) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.uturn.backward")
                Text("スタート画面へ")
            }
            .font(DungeonTypography.maruMonica(size: 19))
            .frame(maxWidth: .infinity, minHeight: 54)
            .foregroundStyle(.white.opacity(0.94))
            .background(
                LinearGradient(
                    colors: [Color(red: 0.56, green: 0.15, blue: 0.25), Color(red: 0.30, green: 0.07, blue: 0.16)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 1.0, green: 0.55, blue: 0.58).opacity(0.68), lineWidth: 1))
        }
        .buttonStyle(DungeonPressButtonStyle())
        .frame(maxWidth: 290)
    }

    private func playGameOverSound() {
        guard gameOverAudioPlayer == nil,
              let player = AudioPlayback.makePlayer(for: .gameOver) else { return }
        let delegate = AudioPlaybackErrorDelegate(resource: .gameOver)
        player.delegate = delegate
        guard AudioPlayback.play(player, for: .gameOver) else { return }
        gameOverAudioPlayer = player
        gameOverAudioErrorDelegate = delegate
    }
}
