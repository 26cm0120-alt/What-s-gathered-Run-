import SwiftUI

/// アプリの最初の画面。画面の状態(AppFlow)に従って、
/// スタート画面・プレイ画面・クリア表示を切り替える
struct ContentView: View {
    @StateObject private var flow = AppFlow()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

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
                    PlayView(game: game, onGiveUp: flow.returnToStart)
                        .overlay {
                            if flow.screen == .cleared {
                                ClearView(onReturn: flow.returnToStart)
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
                ShiritoriGameView(cards: TrialShiritoriCardData.cards) { playerWon in
                    flow.finishShiritori(won: playerWon)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
