import SwiftUI

/// アプリの最初の画面。画面の状態(AppFlow)に従って、
/// スタート画面・プレイ画面・クリア表示を切り替える
struct ContentView: View {
    @StateObject private var flow = AppFlow()

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
                    onReplayRandomStage: flow.replayRandomGame
                )

            case .playing, .cleared:
                // ダンジョンのプレイ画面。しりとり勝利後は既存のクリア表示を重ねる。
                if let game = flow.game {
                    PlayView(
                        game: game,
                        timerStartedAt: flow.timerStartedAt,
                        onGiveUp: flow.returnToStart
                    )
                        .overlay {
                            if flow.screen == .cleared {
                                ClearView(
                                    currentRunTime: flow.currentRunTime,
                                    isFirstClearRun: flow.isFirstClearRun,
                                    bestClearTime: flow.bestClearTime,
                                    onReplay: flow.supportsReplayAndTiming
                                        ? { flow.replayCurrentStage() }
                                        : nil,
                                    onReturn: flow.returnToStart
                                )
                            }
                        }
                }

            case .shiritoriPrologue:
                ShiritoriStartView(onGameStart: flow.startShiritoriGame)

            case .shiritoriGame:
                ShiritoriGameView { playerWon in
                    flow.finishShiritori(won: playerWon)
                }

            case .trialShiritoriGame:
                // 試練専用データを使うが、ゲームルールと演出は既存版と共通にする。
                ShiritoriGameView(cards: CardData2.cards, stage: .trial) { playerWon in
                    flow.finishShiritori(won: playerWon)
                }
            }
        }
    }
}

/// タイトル・プレイ・クリア画面で共通して使う、深い青から紫黒、ワインレッドへの背景。
struct DungeonBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.18, blue: 0.32),
                Color(red: 0.035, green: 0.025, blue: 0.09),
                Color(red: 0.25, green: 0.065, blue: 0.16)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
