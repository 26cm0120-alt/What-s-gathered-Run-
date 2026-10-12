//
//  ShiritoriGameView.swift
//  shiritori
//
//  Phase18-2：CPU・PLAYERキャラクター表示
//  Phase21：キャラクター拡大・画面レイアウト再配置
//

import SwiftUI

// ゲーム画面全体を担当する
struct ShiritoriGameView: View {

    /// 勝敗と最終演出が確定したあと、統合アプリへ結果を通知する。
    let onGameFinished: (Bool) -> Void

    // ゲーム進行を管理する
    @State private var gameManager = ShiritoriGameManager()

    // 結果通知と遷移タイマーの重複を防ぐ
    @State private var hasScheduledGameFinish = false
    @State private var finishTransitionTimer: Timer?

    // ゲーム開始済みかどうか
    @State private var hasStarted = false

    // プロローグ直後のCPU導入会話を表示しているか
    @State private var isShowingOpeningDialogue = true

    // 導入会話の現在位置（0から2まで）
    @State private var openingDialogueIndex = 0

    // PLAYER敗北用BGMが同じ対局内で重複再生されないようにする
    @State private var defeatBGMPlayed = false

    // プロローグ直後にCPUが表示する3段階の導入メッセージ
    private let openingDialogueMessages = [
        "よくぞ　あのダンジョンをくぐりぬけた。ほめてやろう。",
        "ふっふっふ・・・このカードのいみは、いうまでもあるまい。\nでは、いざ。",
        "What's gathered? Run!\nワギャラン"
    ]

    // 通常アニメーションを基本画像から開始するための基準時刻
    @State private var characterAnimationEpoch = Date()

    var body: some View {
        GeometryReader { geometry in
            // PLAYER画像の表示サイズ（既存サイズを維持）
            let characterSize = min(geometry.size.width * 0.34, geometry.size.height * 0.18)
            // CPU画像は上部の横幅を確保し、PLAYER画像より大きく表示する
            let cpuCharacterSize = min(geometry.size.width * 0.42, geometry.size.height * 0.23)

            TimelineView(.periodic(from: Date(), by: 0.05)) { timeline in
                let now = timeline.date
                ZStack {
                    Color.black
                        .ignoresSafeArea()

                    VStack(spacing: 6) {

                        // MARK: - 上部：CPU画像・残り枚数・次の文字

                        HStack(alignment: .center, spacing: 8) {
                            // CPU画像を大きく表示する
                            Image(characterImage(
                                prefix: "character_cpu",
                                event: gameManager.cpuAnimationEvent,
                                at: now,
                                isPlayer: false
                            ))
                                .resizable()
                                .scaledToFit()
                                .frame(width: cpuCharacterSize, height: cpuCharacterSize)

                            // 上段に「残り枚数」「次の文字」、その下段中央にCPUを表示する
                            VStack(spacing: 8) {
                                HeaderView(
                                    remainingCardCount: remainingCardCount,
                                    currentPrompt: gameManager.currentPrompt
                                )
                                .frame(maxWidth: .infinity)

                                Text("CPU")
                                    .font(
                                        .system(
                                            size: 14,
                                            weight: .bold,
                                            design: .monospaced
                                        )
                                    )
                                    .foregroundStyle(.white)
                                    .fixedSize()
                            }
                            .frame(maxWidth: .infinity)
                        }

                        // MARK: - メッセージウィンドウ

                        MessageWindowView(
                            message: isShowingOpeningDialogue
                                ? openingDialogueMessages[openingDialogueIndex]
                                : messageText,
                            typingDuration: isShowingOpeningDialogue && openingDialogueIndex < 2
                                ? 3.0
                                : nil,
                            displayImmediately: isShowingOpeningDialogue && openingDialogueIndex == 2,
                            // 導入会話と途中の特殊セリフは既存時間を維持し、最終セリフ後は統合用に3秒待機する
                            holdDuration: isShowingOpeningDialogue
                                ? (openingDialogueIndex < 2 ? 2.0 : 5.0)
                            : (playerLoseNMessageHoldDuration
                                ?? noCPUTargetVictoryMessageHoldDuration
                                ?? cpuFinalCardMessageHoldDuration
                                ?? timeoutMercyVictoryMessageHoldDuration),
                            // 最後の英語・署名メッセージだけ、2行とも中央揃えにする
                            centerText: isShowingOpeningDialogue && openingDialogueIndex == 2,
                            onCompleted: { completedMessage in
                                handleMessageDisplayCompleted(completedMessage)
                            }
                        )

                        // MARK: - 中央：25枚のカード

                        CardBoardView(
                            cards: gameManager.cards,
                            selectedCardID: gameManager.selectedCardID,
                            cpuScanIndex: gameManager.currentCPUScanIndex,
                            onCardTap: { id in
                                gameManager.selectCard(id: id)

                                // 同じカードを2回タップして確定した場合は判定する
                                if gameManager.confirmedCardID == id {
                                    gameManager.confirmSelectedCard()
                                }
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        // MARK: - 下部：PLAYER情報・PLAYER画像

                        HStack(alignment: .center, spacing: 8) {
                            // PLAYERと残り時間を画像の左側に表示する
                            PlayerStatusView(
                                playerTime: gameManager.playerTime
                            )
                            .frame(maxWidth: .infinity)

                            // 画面右側に向く配置に合わせ、PLAYER画像を水平方向に反転する
                            Image(characterImage(
                                prefix: "character_player",
                                event: gameManager.playerAnimationEvent,
                                at: now,
                                isPlayer: true
                            ))
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(x: -1, y: 1)
                                .frame(width: characterSize, height: characterSize)
                        }
                    }
                    .padding(8)
                }
            }
            .onAppear {
                // 画面表示時にゲームを一度だけ開始する
                guard !hasStarted else { return }

                hasStarted = true
                // 盤面とCPUの先攻対象を準備し、3段階の導入会話が終わるまでスキャンを待つ
                gameManager.startGame(waitForOpeningDialogue: true)
            }
            .onDisappear {
                finishTransitionTimer?.invalidate()
                finishTransitionTimer = nil
            }
        }
    }

    // メッセージの完了に応じて、導入会話を進めるか敗北BGMを再生する
    private func handleMessageDisplayCompleted(_ completedMessage: String) {
        if isShowingOpeningDialogue {
            // 古いメッセージの完了通知で導入会話が飛ばないように確認する
            guard completedMessage == openingDialogueMessages[openingDialogueIndex] else {
                return
            }

            if openingDialogueIndex < openingDialogueMessages.count - 1 {
                openingDialogueIndex += 1
            } else {
                // 3つ目は一気に表示したあと5秒保持し、その後CPU先攻を開始する
                isShowingOpeningDialogue = false
                gameManager.startInitialCPUScanAfterOpeningDialogue()
            }
            return
        }

        // 古いメッセージの完了通知では再生しない
        guard completedMessage == messageText else { return }

        // 「ん」敗北は、気づきのセリフから敗北宣告へ段階的に進める。
        if gameManager.isPlayerLoseNEndingActive {
            switch gameManager.playerLoseNEndingStage {
            case .recognitionMessage:
                gameManager.advancePlayerLoseNEnding(after: completedMessage)
                return
            case .defeatMessage:
                gameManager.advancePlayerLoseNEnding(after: completedMessage)
            case .inactive, .finished:
                break
            }
        }

        // CPU最終カードのエンディング。最後のセリフ全文表示後に統合用の待機を開始する。
        if gameManager.isCPUFinalCardEndingActive {
            if case .victoryAcknowledgement = gameManager.cpuFinalCardEndingStage {
                gameManager.advanceCPUFinalCardEnding(after: completedMessage)
                scheduleGameFinish(won: true)
            } else {
                gameManager.advanceCPUFinalCardEnding(after: completedMessage)
            }
            return
        }

        // 時間切れ特別勝利。最後のセリフ全文表示後に統合用の待機を開始する。
        if gameManager.isTimeoutMercyVictoryActive {
            if case .victoryConcession = gameManager.timeoutMercyVictoryStage {
                gameManager.advanceTimeoutMercyVictory(after: completedMessage)
                scheduleGameFinish(won: true)
            } else {
                gameManager.advanceTimeoutMercyVictory(after: completedMessage)
            }
            return
        }

        // CPUが選べるカードを失った場合の、最後の敗北承認メッセージ。
        if gameManager.isNoCPUTargetVictoryActive {
            if case .defeatAcknowledgement = gameManager.noCPUTargetVictoryStage {
                gameManager.advanceNoCPUTargetVictory(after: completedMessage)
                scheduleGameFinish(won: true)
            } else {
                gameManager.advanceNoCPUTargetVictory(after: completedMessage)
            }
            return
        }

        guard let result = gameManager.gameResult else { return }
        switch result {
        case .playerLoseTimeout, .playerLoseN:
            guard !defeatBGMPlayed else { return }
            // 既存の敗北BGMを開始してから、統合用の3秒待機を始める。
            defeatBGMPlayed = true
            SoundEffectManager.shared.playDefeatBGMOnce()
            scheduleGameFinish(won: false)

        case .playerWinAllCards, .playerWinNoCPUTarget, .playerWinCPUN, .playerWinTimeoutMercy:
            // 特殊エンディングは上の分岐で処理し、通常勝利はここで結果を通知する。
            scheduleGameFinish(won: true)
        }
    }

    // 最終メッセージの全文表示と必要な結果演出の後、3秒待って統合アプリへ結果を渡す。
    private func scheduleGameFinish(won: Bool) {
        guard !hasScheduledGameFinish else { return }
        hasScheduledGameFinish = true

        finishTransitionTimer?.invalidate()
        finishTransitionTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            finishTransitionTimer = nil
            SoundEffectManager.shared.stopBGM()
            onGameFinished(won)
        }
    }

    // ゲーム結果のイベントを優先し、終了後は基本画像から通常ループを再開する
    private func characterImage(
        prefix: String,
        event: CharacterAnimationEvent?,
        at date: Date,
        isPlayer: Bool
    ) -> String {
        // 時間切れ特別勝利の健闘セリフ以降は、CPUを通常画像、PLAYERをWrong画像に固定する。
        switch gameManager.timeoutMercyVictoryStage {
        case .hardFoughtMessage, .victoryConcession, .finished:
            return isPlayer ? "\(prefix)_wrong" : prefix
        case .inactive, .defeatMessage:
            break
        }

        // カードを使い切ったセリフ以降は、CPUを通常画像、PLAYERを勝利ジャンプに固定する。
        switch gameManager.cpuFinalCardEndingStage {
        case .cardsExhaustedMessage, .victoryAcknowledgement, .finished:
            // CPUは通常ポーズのままにし、PLAYERは勝利ジャンプ3フレームを繰り返す。
            guard isPlayer else { return prefix }
            let startDate = gameManager.playerAnimationEvent?.startedAt ?? characterAnimationEpoch
            let elapsed = max(0, date.timeIntervalSince(startDate))
            let frame = Int(elapsed / 0.5) % 3
            switch frame {
            case 0: return "\(prefix)_jump_01"
            case 1: return "\(prefix)_jump_02"
            default: return "\(prefix)_jump_03"
            }

        case .inactive, .normalCPUMessage:
            break
        }

        // 最後の通常CPUメッセージ中だけは、結果確定より通常の取得アニメーションを優先する。
        if case .normalCPUMessage = gameManager.cpuFinalCardEndingStage {
            // この段階は次の特殊メッセージへ移るまで通常のアニメーションを続ける。
        } else if let result = gameManager.gameResult {
            // それ以外の終了時は勝者がジャンプを繰り返し、敗者はwrongを維持する。
            let playerWon: Bool
            switch result {
            case .playerWinAllCards, .playerWinNoCPUTarget, .playerWinCPUN:
                playerWon = true
            case .playerLoseTimeout, .playerLoseN, .playerWinTimeoutMercy:
                // 特別勝利の最初の「時間切れ」セリフ中だけ、従来の時間切れポーズを保つ。
                playerWon = false
            }

            if isPlayer == playerWon {
                let startDate = event?.startedAt ?? characterAnimationEpoch
                let elapsed = max(0, date.timeIntervalSince(startDate))
                let frame = Int(elapsed / 0.5) % 3
                switch frame {
                case 0: return "\(prefix)_jump_01"
                case 1: return "\(prefix)_jump_02"
                default: return "\(prefix)_jump_03"
                }
            } else {
                return "\(prefix)_wrong"
            }
        }

        var normalElapsed = date.timeIntervalSince(characterAnimationEpoch)

        if let event {
            let elapsed = date.timeIntervalSince(event.startedAt)

            if elapsed >= 0 {
                let eventDuration: TimeInterval

                switch event.kind {
                case .success:
                    eventDuration = 3.0

                    // 3フレームを各0.5秒で表示し、合計3秒（2ループ）で通常へ戻す
                    if elapsed < eventDuration {
                        let frame = Int(elapsed / 0.5) % 3
                        switch frame {
                        case 0: return "\(prefix)_jump_01"
                        case 1: return "\(prefix)_jump_02"
                        default: return "\(prefix)_jump_03"
                        }
                    }

                case .failure:
                    eventDuration = 1.5

                    // wrong画像は1.5秒だけ表示して通常へ戻す
                    if elapsed < eventDuration {
                        return "\(prefix)_wrong"
                    }
                }

                // イベント終了時点を通常ループの起点にするため、基本画像から再開する。
                normalElapsed = elapsed - eventDuration
            }
        }

        // 通常時は基本1秒→瞬き0.5秒→呼吸0.5秒→羽0.5秒の2.5秒周期で繰り返す。
        // 羽の表示が終わると基本画像へ戻り、基本画像を1秒表示してから次の瞬きへ進む。
        let phase = normalElapsed.truncatingRemainder(dividingBy: 2.5)

        if phase < 1.0 {
            return prefix
        } else if phase < 1.5 {
            return "\(prefix)_blink"
        } else if phase < 2.0 {
            return "\(prefix)_breath"
        } else {
            return "\(prefix)_wing"
        }
    }

    // 「ん」敗北の段階セリフとCPUの特殊エンディングは、勝敗の既定メッセージより優先する
    private var messageText: String {
        if gameManager.isPlayerLoseNEndingActive {
            switch gameManager.playerLoseNEndingStage {
            case .recognitionMessage:
                return gameManager.currentMessage ?? "なんと・・・ん？"
            case .defeatMessage, .finished:
                return "ん がついているではないか、お前の負けだ"
            case .inactive:
                break
            }
        }

        if gameManager.isCPUFinalCardEndingActive || gameManager.isTimeoutMercyVictoryActive || gameManager.isNoCPUTargetVictoryActive {
            return gameManager.currentMessage ?? ""
        }

        // ゲーム終了時は勝敗結果を優先して表示する
        if let gameResult = gameManager.gameResult {
            switch gameResult {
            case .playerWinAllCards:
                return "見事だ…私の負けだ"

            case .playerWinNoCPUTarget:
                return gameManager.currentMessage
                    ?? "なんと、選べるカードがないではないか"

            case .playerWinCPUN:
                return gameManager.currentMessage
                    ?? "・・・しまったいかん！ 私の負けだ"

            case .playerWinTimeoutMercy:
                return gameManager.currentMessage ?? "よかろう、おまえの けんとうを たたえ、しょうりを ゆずってやろう。"

            case .playerLoseTimeout:
                return "フハハハ！時間切れだ！貴様の負けだ！"

            case .playerLoseN:
                return "ちょっと待て、’ん’ で終わりではないか。貴様の負けだ"
            }
        }

        // ゲーム中はShiritoriGameManagerが設定したメッセージを表示する
        return gameManager.currentMessage
            ?? "「さあ、始めるとしよう」"
    }

    // 「ん」敗北の気づきのセリフだけ、全文表示後に2秒保持する。
    private var playerLoseNMessageHoldDuration: TimeInterval? {
        gameManager.playerLoseNEndingStage == .recognitionMessage ? 2.0 : nil
    }

    // 時間切れ特別勝利の途中メッセージは2秒保持し、最後は統合用の3秒待機に委ねる
    private var timeoutMercyVictoryMessageHoldDuration: TimeInterval? {
        switch gameManager.timeoutMercyVictoryStage {
        case .defeatMessage, .hardFoughtMessage:
            return 2.0
        case .victoryConcession:
            return nil
        case .inactive, .finished:
            return nil
        }
    }

    // CPU最終カードの途中メッセージは2秒保持し、最後は統合用の3秒待機に委ねる
    private var cpuFinalCardMessageHoldDuration: TimeInterval? {
        switch gameManager.cpuFinalCardEndingStage {
        case .normalCPUMessage:
            // 次の特殊セリフへ切り替える前に、通常セリフの最後まで読める短い間を設ける
            return 0.5
        case .cardsExhaustedMessage:
            return 2.0
        case .victoryAcknowledgement:
            return nil
        case .inactive, .finished:
            return nil
        }
    }
    
    
    // CPU対象なしの勝利メッセージは、最初のセリフを全文表示後に2秒保持する
    private var noCPUTargetVictoryMessageHoldDuration: TimeInterval? {
        switch gameManager.noCPUTargetVictoryStage {
        case .noCardsMessage:
            return 2.0
        case .defeatAcknowledgement, .inactive, .finished:
            return nil
        }
    }


    
    
    // まだ取得されていないカードの枚数を数える
    // カード取得のたびにShiritoriGameManager.cardsのisClearedを参照して表示を更新する
    private var remainingCardCount: Int {
        gameManager.cards.filter { !$0.isCleared }.count
    }
}

#Preview {
    ShiritoriGameView(onGameFinished: { _ in })
}
