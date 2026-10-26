import SwiftUI

/// アプリの最初の画面。画面の状態(AppFlow)に従って、
/// スタート画面・プレイ画面・クリア表示・ゲームオーバー表示を切り替える
struct ContentView: View {
    @StateObject private var flow = AppFlow()
    #if DEBUG
    @State private var didOpenDebugClearScreen = false
    #endif

    var body: some View {
        ZStack {
            DungeonBackground()

            switch flow.screen {
            case .start:
                // スタート画面(面を選ぶ)
                StartView(
                    stages: Stages.all,
                    lastRandomSeed: flow.lastRandomSeed,
                    onSelect: flow.startGame,
                    onRandomStage: flow.startRandomGame,
                    onReplayRandomStage: flow.replayRandomGame,
                    onAudioVolumeChanged: flow.applyAudioVolumes
                )

            case .playing, .cleared, .gameOver:
                // ダンジョンのプレイ画面に、クリアまたはゲームオーバー表示を重ねる。
                if let game = flow.game {
                    PlayView(
                        game: game,
                        isInputEnabled: flow.screen == .playing,
                        timerStartedAt: flow.timerStartedAt,
                        onGiveUp: flow.returnToStart
                    )
                        // GameManagerが切り替わったらPlayViewも作り直し、前ステージの演出状態を引き継がない。
                        .id(ObjectIdentifier(game))
                        .overlay {
                            if flow.screen == .cleared {
                                ClearView(
                                    currentRunTime: flow.currentRunTime,
                                    bestClearTime: flow.bestClearTime,
                                    nextStageTitle: flow.nextStageTitle,
                                    leaderboardTitle: flow.game?.stage.seed == nil ? "試練の迷宮" : "ランダムステージ",
                                    leaderboardMode: flow.game?.stage.seed == nil ? .trial : .random,
                                    leaderboardEntries: flow.leaderboardEntries,
                                    theme: game.stage.dungeonTheme,
                                    onSaveName: flow.saveLeaderboardEntry,
                                    onUpdateName: flow.updateLeaderboardEntryName,
                                    onNextStage: flow.startNextStage,
                                    onReplay: flow.supportsReplayAndTiming
                                        ? { flow.replayCurrentStage() }
                                        : nil,
                                    onReturn: flow.returnToStart
                                )
                            } else if flow.screen == .gameOver {
                                GameOverView(
                                    onReturn: flow.returnToStart,
                                    reasonMessage: flow.gameOverReasonMessage,
                                    detailMessage: flow.gameOverDetailMessage
                                )
                            }
                        }
                }

            case .shiritoriPrologue:
                ShiritoriStartView(
                    isRandomStage: flow.game?.stage.seed != nil,
                    onGameStart: flow.startShiritoriGame
                )

            case .shiritoriGame:
                ShiritoriGameView(
                    cards: flow.game?.stage.seed != nil
                        ? RandomShiritoriCardData.cards
                        : CardData.cards,
                    isRandomStage: flow.game?.stage.seed != nil,
                    initialPlayerTimeBonusSeconds: flow.shiritoriTimeBonusSeconds,
                    playerTimePenaltySeconds: flow.shiritoriTimePenaltySeconds,
                    playerTimeHPBonusSeconds: flow.shiritoriHPBonusSeconds
                ) { playerWon in
                    flow.finishShiritori(won: playerWon)
                }

            case .trialShiritoriGame:
                // 試練専用データを使うが、ゲームルールと演出は既存版と共通にする。
                ShiritoriGameView(cards: CardData2.cards, stage: .trial, initialPlayerTimeBonusSeconds: flow.shiritoriTimeBonusSeconds, playerTimePenaltySeconds: flow.shiritoriTimePenaltySeconds, playerTimeHPBonusSeconds: flow.shiritoriHPBonusSeconds) { playerWon in
                    flow.finishShiritori(won: playerWon)
                }
            }
        }
        #if DEBUG
        .onAppear {
            guard !didOpenDebugClearScreen,
                  ProcessInfo.processInfo.arguments.contains("-debug-clear-screen") else { return }
            didOpenDebugClearScreen = true
            let isTutorial = ProcessInfo.processInfo.arguments.contains("-debug-tutorial-clear")
            flow.startGame(stage: isTutorial ? Stages.tutorial : Stages.trial)
            flow.presentDebugClearScreen()
        }
        #endif
    }
}

/// タイトル・プレイ・クリア画面で共通して使う、深い青から紫黒、ワインレッドへの背景。
/// themeを渡すと、ランダムステージのテーマ(森の洋館・古代神殿・地獄の回廊・水晶洞窟)ごとの配色になる。
struct DungeonBackground: View {
    var theme: DungeonTheme? = nil

    private var colors: [Color] {
        switch theme {
        case .forestMansion:
            // 深い緑から黒緑、古い木材のような茶色へ
            return [
                Color(red: 0.07, green: 0.22, blue: 0.13),
                Color(red: 0.015, green: 0.06, blue: 0.035),
                Color(red: 0.22, green: 0.14, blue: 0.06)
            ]
        case .temple:
            // 砂岩の金茶から暗い石色、琥珀色へ
            return [
                Color(red: 0.34, green: 0.24, blue: 0.09),
                Color(red: 0.075, green: 0.052, blue: 0.03),
                Color(red: 0.32, green: 0.17, blue: 0.05)
            ]
        case .hell:
            // 燃える赤から黒、溶岩のオレンジへ
            return [
                Color(red: 0.38, green: 0.05, blue: 0.025),
                Color(red: 0.07, green: 0.008, blue: 0.01),
                Color(red: 0.58, green: 0.13, blue: 0.015)
            ]
        case .cave:
            // 水晶の青緑から深い藍、紫水晶へ
            return [
                Color(red: 0.05, green: 0.31, blue: 0.42),
                Color(red: 0.012, green: 0.035, blue: 0.10),
                Color(red: 0.22, green: 0.12, blue: 0.42)
            ]
        case nil:
            return [
                Color(red: 0.12, green: 0.18, blue: 0.32),
                Color(red: 0.035, green: 0.025, blue: 0.09),
                Color(red: 0.25, green: 0.065, blue: 0.16)
            ]
        }
    }

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
