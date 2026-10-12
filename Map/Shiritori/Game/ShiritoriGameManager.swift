//
//  ShiritoriGameManager.swift
//  shiritori
//
//  Created by cmStudent on 2026/10/02.
//

import Foundation

// キャラクターに再生するアニメーションの種類
// 成功と失敗の時間制御はView側で行い、ここでは発生時刻だけを管理する。
enum CharacterAnimationKind {
    case success
    case failure
}

// キャラクターアニメーションの開始情報
struct CharacterAnimationEvent {
    let kind: CharacterAnimationKind
    let startedAt: Date
}

// CPUが最後のカードを取得した場合のエンディング進行段階
// 通常のCPU取得メッセージ→カードを使い切ったセリフ→勝利承認の順で進める。
enum CPUFinalCardEndingStage {
    case inactive
    case normalCPUMessage
    case cardsExhaustedMessage
    case victoryAcknowledgement
    case finished
}

// 時間切れ時に健闘を称えて特別勝利を認める演出の進行段階
// 通常の時間切れセリフ→健闘を称えるセリフ→勝利を譲るセリフの順で進める。
enum TimeoutMercyVictoryStage {
    case inactive
    case defeatMessage
    case hardFoughtMessage
    case victoryConcession
    case finished
}

// CPUが選べるカードを失った場合の勝利メッセージ進行段階
// 「選べるカードがない」→「自分の負けを認める」の順で進める。
enum NoCPUTargetVictoryStage {
    case inactive
    case noCardsMessage
    case defeatAcknowledgement
    case finished
}

// ゲーム全体の進行状態を管理する
final class ShiritoriGameManager {

    // 現在のゲーム状態
    private(set) var gameState: ShiritoriGameState = .waiting

    // 勝敗結果
    private(set) var gameResult: GameResult?

    // 現在のターン
    private(set) var turn: Turn = .player

    // ゲーム盤面のカード
    private(set) var cards: [Card] = []

    // 現在のしりとり要求文字
    private(set) var currentPrompt: Character?

    // 現在選択中のカード
    private(set) var selectedCardID: UUID?

    // 2回目のタップで確定したカード
    private(set) var confirmedCardID: UUID?

    // PLAYER TIMEの残り秒数
    private(set) var playerTime: Int = 90

    // PLAYER TIMEを1秒ごとに減少させるタイマー
    private var playerTimer: Timer?

    // 現在表示するメッセージ
    private(set) var currentMessage: String?

    // CPUが25枚目のカードを取得したときのエンディング進行状態
    private(set) var cpuFinalCardEndingStage: CPUFinalCardEndingStage = .inactive

    // 時間切れ時の特別勝利演出の進行状態
    private(set) var timeoutMercyVictoryStage: TimeoutMercyVictoryStage = .inactive

    // CPUが選べるカードを失った場合の勝利演出の進行状態
    private(set) var noCPUTargetVictoryStage: NoCPUTargetVictoryStage = .inactive

    // 残り枚数がこの枚数以下なら、時間切れでも特別勝利を認める
    private let timeoutMercyVictoryRemainingCardThreshold = 7

    // CPU最終カードのエンディング進行中かどうか
    var isCPUFinalCardEndingActive: Bool {
        if case .inactive = cpuFinalCardEndingStage {
            return false
        }
        return true
    }

    // 時間切れの特別勝利演出が進行中かどうか
    var isTimeoutMercyVictoryActive: Bool {
        if case .inactive = timeoutMercyVictoryStage {
            return false
        }
        return true
    }

    // CPUが選べるカードを失った場合の勝利演出が進行中かどうか
    var isNoCPUTargetVictoryActive: Bool {
        if case .inactive = noCPUTargetVictoryStage {
            return false
        }
        return true
    }

    // キャラクターアニメーションの直近イベント。Viewは開始時刻から表示フレームを計算する。
    private(set) var cpuAnimationEvent: CharacterAnimationEvent?
    private(set) var playerAnimationEvent: CharacterAnimationEvent?

    // CPUリアクション用の3秒タイマー
    private var cpuReactionTimer: Timer?

    // CPUが事前に決定した対象カード
    private(set) var cpuTargetCardID: UUID?

    // CPUが事前に決定した対象Vocabulary
    private(set) var cpuTargetVocabulary: Vocabulary?

    // CPUスキャン状態
    private(set) var cpuScanState: CPUScanState = .idle

    // CPUスキャンを進めるタイマー
    private var cpuScanTimer: Timer?

    // CPUスキャン中の現在位置
    private var cpuScanIndex: Int = 0
    
    // UIから現在のCPUスキャン位置を読み取るためのプロパティ
    var currentCPUScanIndex: Int? {
        gameState == .cpuTurn ? cpuScanIndex : nil
    }

    // CPUスキャンの周回数
    // 0 = 1周目、1 = 2周目
    private var cpuScanRound: Int = 0

    deinit {
        // ゲームマネージャー破棄時にタイマーを停止する
        playerTimer?.invalidate()
        cpuReactionTimer?.invalidate()
        cpuScanTimer?.invalidate()
    }

    // CPUのアニメーションイベントを開始する
    private func startCPUAnimation(_ kind: CharacterAnimationKind) {
        cpuAnimationEvent = CharacterAnimationEvent(kind: kind, startedAt: Date())
    }

    // PLAYERのアニメーションイベントを開始する
    private func startPlayerAnimation(_ kind: CharacterAnimationKind) {
        playerAnimationEvent = CharacterAnimationEvent(kind: kind, startedAt: Date())
    }

    // ゲームを開始する
    // - Parameter waitForOpeningDialogue: trueの場合は導入会話が終わるまでCPUスキャンを開始しない
    func startGame(waitForOpeningDialogue: Bool = false) {
        // 前回のBGMがあれば停止して、ゲーム開始時にBGM1から再生する
        SoundEffectManager.shared.stopBGM()
        SoundEffectManager.shared.startBGM()

        // 前回のタイマーやCPU処理を停止する
        stopPlayerTimer()
        stopCPUReaction()
        stopCPUScan()

        // CPUの対象情報を初期化する
        cpuTargetCardID = nil
        cpuTargetVocabulary = nil

        // ゲーム状態を初期化する
        gameResult = nil
        currentMessage = nil
        cpuFinalCardEndingStage = .inactive
        timeoutMercyVictoryStage = .inactive
        noCPUTargetVictoryStage = .inactive
        cpuAnimationEvent = nil
        playerAnimationEvent = nil
        cpuScanState = .idle
        cpuScanRound = 0

        // 25枚のカードをシャッフルしてゲーム盤面に配置する
        self.cards = CardData.cards.shuffled()

        // ゲーム開始時は次の文字を空欄にする
        self.currentPrompt = nil
        self.selectedCardID = nil
        self.confirmedCardID = nil
        self.playerTime = 90

        // CPU先攻状態を設定する。導入会話中は初期案内文を後回しにする
        self.turn = .cpu
        self.gameState = .cpuReaction
        self.currentMessage = waitForOpeningDialogue
            ? nil
            : "よし、まずは私から選ばせてもらうぞ"

        // CPU先攻では普通読みのカードをランダムに1枚選ぶ
        prepareInitialCPUTarget()

        // 導入会話がない場合は、従来どおり3秒後にCPUスキャンを開始する
        guard !waitForOpeningDialogue else { return }
        scheduleInitialCPUScan(after: 3.0)
    }

    // 導入会話完了後に、従来のCPU先攻案内文を表示してからスキャンを開始する
    // 3つ目の導入メッセージの5秒保持が終わった直後に呼び出す
    func startInitialCPUScanAfterOpeningDialogue() {
        guard gameState == .cpuReaction else { return }
        guard cpuReactionTimer == nil else { return }

        // 導入会話のあとも従来の案内文を残し、CPUが選択を始めることを伝える
        currentMessage = "よし、まずは私から選ばせてもらうぞ"

        // 従来の初回CPU先攻と同じく、案内文を表示してから3秒後にスキャンを開始する
        scheduleInitialCPUScan(after: 3.0)
    }

    // CPU先攻のスキャン開始を指定秒数だけ待つ
    private func scheduleInitialCPUScan(after delay: TimeInterval) {
        cpuReactionTimer?.invalidate()
        cpuReactionTimer = Timer.scheduledTimer(
            withTimeInterval: delay,
            repeats: false
        ) { [weak self] _ in
            guard let self else { return }
            self.cpuReactionTimer = nil
            self.startCPUScan()
        }
    }

    // ゲーム開始時のCPU先攻カードを普通読みからランダムに決定する
    private func prepareInitialCPUTarget() {
        let candidates: [(card: Card, vocabulary: Vocabulary)] = cards.compactMap { card in
            guard !card.isCleared,
                  let normalVocabulary = card.vocabularies.first(where: { $0.type == .normal }) else {
                return nil
            }
            return (card: card, vocabulary: normalVocabulary)
        }

        guard let result = candidates.randomElement() else {
            cpuTargetCardID = nil
            cpuTargetVocabulary = nil
            return
        }

        cpuTargetCardID = result.card.id
        cpuTargetVocabulary = result.vocabulary
    }

    // PLAYER TIMEタイマーを開始する
    func startPlayerTimer() {
        guard gameState == .playerTurn else { return }
        guard playerTimer == nil else { return }

        playerTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in
            self?.decreasePlayerTime(by: 1)
        }
    }

    // PLAYER TIMEタイマーを停止する
    func stopPlayerTimer() {
        playerTimer?.invalidate()
        playerTimer = nil
    }

    // CPUリアクションタイマーを開始する
    private func startCPUReaction() {
        // 既存のCPUリアクションタイマーがあれば停止する
        stopCPUReaction()

        // CPUリアクション中はPLAYER TIMEを停止する
        stopPlayerTimer()

        // CPUリアクション開始
        gameState = .cpuReaction

        // 3秒後にCPU対象決定とスキャンを開始する
        cpuReactionTimer = Timer.scheduledTimer(
            withTimeInterval: 3.0,
            repeats: false
        ) { [weak self] _ in
            guard let self else { return }

            // タイマーを解除する
            self.cpuReactionTimer = nil

            // CPUの対象を決定してからスキャンを開始する
            self.prepareCPUTarget()
            self.startCPUScan()
        }
    }

    // CPUリアクションタイマーを停止する
    private func stopCPUReaction() {
        cpuReactionTimer?.invalidate()
        cpuReactionTimer = nil
    }

    // カードをタップする
    func selectCard(id: UUID) {
        guard gameState == .playerTurn else { return }
        guard let card = cards.first(where: { $0.id == id }) else { return }
        guard !card.isCleared else { return }

        // 別のカードをタップした場合は、以前の選択を解除して新しく選択する
        if selectedCardID != id {
            selectedCardID = id
            confirmedCardID = nil

            // 別のカードへ選択を移動したときにカーソル音を再生する
            SoundEffectManager.shared.playCursor()
            return
        }

        // 同じカードを2回目にタップした場合は、そのカードを確定する
        confirmedCardID = id
    }

    // 確定したカードのしりとり判定と取得処理を行う
    func confirmSelectedCard() {
        guard gameState == .playerTurn else { return }
        guard let confirmedCardID else { return }

        guard let cardIndex = cards.firstIndex(where: {
            $0.id == confirmedCardID
        }) else {
            clearSelection()
            return
        }

        let card = cards[cardIndex]

        // 現在の要求文字からVocabularyを自動決定する
        guard let currentPrompt else {
            clearSelection()
            return
        }

        guard let vocabulary = VocabularySelector.select(
            from: card.vocabularies,
            currentPrompt: currentPrompt
        ) else {
            // 読みが存在しない場合は接続失敗として扱う
            SoundEffectManager.shared.playFailure()
            handlePlayerConnectionFailure()
            return
        }

        // 正規化後の末尾が「ん」ならプレイヤー自滅
        if KanaNormalizer.endsWithN(vocabulary.word) {
            // 「ん」による自滅なので不正解音を再生する
            SoundEffectManager.shared.playFailure()

            clearSelection()
            stopPlayerTimer()
            // PLAYERは失敗表情、勝者のCPUは成功ジャンプを開始する
            startPlayerAnimation(.failure)
            startCPUAnimation(.success)
            gameResult = .playerLoseN
            SoundEffectManager.shared.stopBGM()
            gameState = .gameOver
            return
        }

        // 選択された読みが現在の要求文字に接続できるか確認する
        let firstCharacter = KanaNormalizer.firstCharacter(
            of: vocabulary.word
        )

        guard firstCharacter == currentPrompt else {
            // 接続可能なVocabularyが1つもない場合は接続失敗
            SoundEffectManager.shared.playFailure()
            handlePlayerConnectionFailure()
            return
        }

        // しりとり接続に成功したので正解音を再生する
        SoundEffectManager.shared.playSuccess()
        // PLAYERは成功ジャンプ、CPUは悔しがる失敗表情を開始する
        startPlayerAnimation(.success)
        startCPUAnimation(.failure)

        // 正解したカードの取得時にPLAYER TIMEを5秒回復する
        // 持ち時間の上限は90秒とする
        playerTime = min(90, playerTime + 5)

        // プレイヤー取得メッセージを作成する
        currentMessage = MessageSelector.playerMessage(
            for: vocabulary
        )

        // 正常な読みなのでカードを取得する
        cards[cardIndex].isCleared = true
        updateBGMForRemainingCardCount()

        // 成功した読みの正規化後の末尾を次の要求文字にする
        self.currentPrompt = KanaNormalizer.lastCharacter(of: vocabulary.word)

        clearSelection()

        // 25枚すべて取得した場合は即プレイヤー勝利
        if cards.allSatisfy({ $0.isCleared }) {
            // 全カード取得ではCPUが敗北するため、困った表情を表示する
            startCPUAnimation(.failure)
            stopPlayerTimer()
            stopCPUReaction()
            gameResult = .playerWinAllCards
            SoundEffectManager.shared.stopBGM()
            gameState = .gameOver
            return
        }

        // プレイヤーターン終了時にPLAYER TIMEを停止する
        stopPlayerTimer()

        // CPUの対象情報を初期化する
        cpuTargetCardID = nil
        cpuTargetVocabulary = nil

        // CPUスキャン状態を初期化する
        cpuScanState = .idle
        cpuScanRound = 0

        // CPUリアクション3秒を開始する
        startCPUReaction()
    }

    // プレイヤーの接続失敗を処理する
    private func handlePlayerConnectionFailure() {
        // 接続失敗を1.5秒の失敗アニメーションで示す
        startPlayerAnimation(.failure)
        clearSelection()

        // 接続失敗では要求文字を変更せず、PLAYER TIMEを5秒減らす
        playerTime = max(0, playerTime - 5)

        // 0秒になった場合は、残り枚数に応じて通常敗北または特別勝利を判定する
        if playerTime == 0 {
            handlePlayerTimeout()
            return
        }

        // 5秒減少後もプレイヤーターンを継続する
        gameState = .playerTurn
    }

    // CPUの対象カードとVocabularyを事前に決定する
    func prepareCPUTarget() {
        guard gameState == .cpuReaction || gameState == .cpuTurn else {
            return
        }

        guard let currentPrompt else {
            cpuTargetCardID = nil
            cpuTargetVocabulary = nil
            return
        }

        // CPUSelectorで対象を事前に決定する
        guard let result = CPUSelector.select(
            from: cards,
            currentPrompt: currentPrompt
        ) else {
            // 接続可能なカードがない場合は対象なし
            cpuTargetCardID = nil
            cpuTargetVocabulary = nil
            return
        }

        cpuTargetCardID = result.card.id
        cpuTargetVocabulary = result.vocabulary
    }

    // CPUスキャンを開始する
    func startCPUScan() {
        guard gameState == .cpuReaction || gameState == .cpuTurn else {
            return
        }

        // CPU対象がまだ決定されていなければ先に決定する
        if cpuTargetCardID == nil || cpuTargetVocabulary == nil {
            prepareCPUTarget()
        }

        // 25枚の盤面がなければスキャンしない
        guard cards.count == 25 else {
            cpuScanState = .idle
            return
        }

        // 対象が見つからない場合でも、すぐに諦めず通常どおり2周スキャンする。
        // 選択可能なカードがないときの勝敗確定は、2周目の最後まで走査してから行う。

        // PLAYER TIMEはCPU処理中には動かさない
        stopPlayerTimer()

        // CPUスキャン開始前の状態を設定する
        gameState = .cpuTurn
        cpuScanIndex = 0
        cpuScanRound = 0
        cpuScanState = .scanning(index: 0)

        // CPUが1マス目へ移動したのでカーソル音を再生する
        SoundEffectManager.shared.playCursor()

        // 既存のCPUスキャンタイマーを停止する
        stopCPUScan()

        // 0.15秒ごとに盤面を左上から右下へ進める
        cpuScanTimer = Timer.scheduledTimer(
            withTimeInterval: 0.15,
            repeats: true
        ) { [weak self] _ in
            self?.advanceCPUScan()
        }
    }

    // CPUスキャンを1マス進める
    private func advanceCPUScan() {
        guard gameState == .cpuTurn else {
            stopCPUScan()
            return
        }

        // 2周目に選択カードへ到達したらスキャン終了
        if cpuScanRound == 1,
           let targetCardID = cpuTargetCardID,
           cpuScanIndex < cards.count,
           cards[cpuScanIndex].id == targetCardID {
            cpuScanState = .scanning(index: cpuScanIndex)
            stopCPUScan()

            // 選択カードへ到達したため、CPU取得処理へ進む
            acquireCPUCard()
            return
        }

        // 現在位置を表示したまま次のマスへ進める
        if cpuScanIndex < 24 {
            cpuScanIndex += 1
            cpuScanState = .scanning(index: cpuScanIndex)

            // CPUが次のマスへ移動したのでカーソル音を再生する
            SoundEffectManager.shared.playCursor()
            return
        }

        // 1周目の25マスを完了したら、2周目を左上から開始する
        if cpuScanRound == 0 {
            cpuScanRound = 1
            cpuScanIndex = 0
            cpuScanState = .scanning(index: 0)

            // CPUが2周目の1マス目へ移動したのでカーソル音を再生する
            SoundEffectManager.shared.playCursor()
            return
        }

        // 2周目の末尾まで到達したので、CPUスキャンを停止する。
        cpuScanState = .idle
        stopCPUScan()

        // 対象がないまま2周した場合にだけ、ここでプレイヤー勝利を確定する。
        // 対象がある場合は従来どおり、事前に選んだカードの取得処理へ進む。
        guard cpuTargetCardID != nil,
              cpuTargetVocabulary != nil else {
            finishNoCPUTargetVictory()
            return
        }

        acquireCPUCard()
    }

    // 2周スキャンしてもCPUが選べるカードを見つけられなかった場合の勝利処理
    private func finishNoCPUTargetVictory() {
        stopPlayerTimer()
        stopCPUReaction()
        stopCPUScan()
        clearSelection()

        // 最終メッセージはスキャン終了後に初めて設定する。
        currentMessage = "なんと、えらべるカードがないではないか。"
        noCPUTargetVictoryStage = .noCardsMessage

        cpuTargetCardID = nil
        cpuTargetVocabulary = nil
        cpuScanState = .idle
        cpuScanRound = 0

        // CPUは敗者の失敗表情、PLAYERは勝者のジャンプ演出を開始する。
        startCPUAnimation(.failure)
        startPlayerAnimation(.success)
        gameResult = .playerWinNoCPUTarget
        SoundEffectManager.shared.stopBGM()
        gameState = .gameOver
    }

    // CPUが事前に決定したカードを取得する
    private func acquireCPUCard() {
        guard gameState == .cpuTurn else { return }
        guard let targetCardID = cpuTargetCardID,
              let targetVocabulary = cpuTargetVocabulary else {
            return
        }

        guard let cardIndex = cards.firstIndex(where: {
            $0.id == targetCardID
        }) else {
            return
        }

        // 正規化後の末尾が「ん」ならCPU自滅
        if KanaNormalizer.endsWithN(targetVocabulary.word) {
            // CPUの「ん」自滅なので不正解音を再生する
            SoundEffectManager.shared.playFailure()

            stopPlayerTimer()
            stopCPUScan()
            clearSelection()

            // CPUが選択した実際の表示語をメッセージに使用する
            currentMessage =
                "・・・しまったいかん！ \(targetVocabulary.displayWord) では ’ん’ がついてしまうではないか！私の負けだ"

            cpuTargetCardID = nil
            cpuTargetVocabulary = nil
            cpuScanState = .idle
            cpuScanRound = 0
            // CPUは失敗表情、PLAYERは勝者の成功ジャンプを開始する
            startCPUAnimation(.failure)
            startPlayerAnimation(.success)
            gameResult = .playerWinCPUN
            SoundEffectManager.shared.stopBGM()
            gameState = .gameOver
            return
        }

        // CPUのしりとり接続に成功したので正解音を再生する
        SoundEffectManager.shared.playSuccess()
        // CPUは成功ジャンプ、PLAYERは悔しがる失敗表情を開始する
        startCPUAnimation(.success)
        startPlayerAnimation(.failure)

        // CPU取得メッセージを作成する
        // 取得した読みの末尾から、次に選べる文字も同時に表示する
        let nextPrompt = KanaNormalizer.lastCharacter(
            of: targetVocabulary.word
        )
        currentMessage = MessageSelector.cpuMessageWithNextPrompt(
            for: targetVocabulary,
            nextPrompt: nextPrompt
        )

        // 「ん」でない場合はカードを取得する
        cards[cardIndex].isCleared = true
        updateBGMForRemainingCardCount()

        // 取得した読みの正規化後の末尾を次の要求文字にする
        currentPrompt = KanaNormalizer.lastCharacter(
            of: targetVocabulary.word
        )

        // CPUターン終了後は対象情報を解除する
        cpuTargetCardID = nil
        cpuTargetVocabulary = nil
        cpuScanState = .idle
        cpuScanRound = 0

        // CPUが25枚目を取得した場合は、通常メッセージから専用エンディングへ進む
        if cards.allSatisfy({ $0.isCleared }) {
            stopPlayerTimer()
            stopCPUReaction()
            stopCPUScan()
            gameResult = .playerWinAllCards
            cpuFinalCardEndingStage = .normalCPUMessage
            turn = .player
            // 最終カードの専用エンディング中は、ゲームBGMを止めずに流し続ける。
            gameState = .gameOver
            return
        }

        // プレイヤーターンへ移行する
        turn = .player
        gameState = .playerTurn
        startPlayerTimer()
    }

    // CPU最終カードのメッセージが表示完了したら、次のエンディング文へ進める
    // 通常メッセージは保持時間なし、特殊メッセージはView側で2秒保持してから通知される。
    func advanceCPUFinalCardEnding(after completedMessage: String) {
        guard isCPUFinalCardEndingActive else { return }
        guard completedMessage == currentMessage else { return }

        switch cpuFinalCardEndingStage {
        case .normalCPUMessage:
            // 通常メッセージのあと、カードを使い切ったことに気づくセリフへ進む
            cpuFinalCardEndingStage = .cardsExhaustedMessage
            currentMessage = "・・・といいたいところだが、なんと カードを つかいきって しまったではないか"

            // ここから先はCPUを通常ポーズ、PLAYERを勝利アニメーションにする
            startPlayerAnimation(.success)

        case .cardsExhaustedMessage:
            // 2秒保持後、CPUがPLAYERの勝利を認めるセリフへ進む
            cpuFinalCardEndingStage = .victoryAcknowledgement
            currentMessage = "みごとだ。きさまの しょうりを みとめよう。"

        case .victoryAcknowledgement:
            // 最後のセリフも2秒保持したら、ポーズとメッセージをそのまま維持する
            cpuFinalCardEndingStage = .finished

        case .inactive, .finished:
            return
        }
    }

    // 時間切れの特別勝利メッセージが表示完了したら、次のセリフへ進める
    // 各メッセージはView側で2秒保持してから通知される。
    func advanceTimeoutMercyVictory(after completedMessage: String) {
        guard isTimeoutMercyVictoryActive else { return }
        guard completedMessage == currentMessage else { return }

        switch timeoutMercyVictoryStage {
        case .defeatMessage:
            // 通常の時間切れセリフのあと、残り枚数を示して健闘を称える
            timeoutMercyVictoryStage = .hardFoughtMessage
            let remainingCardCount = cards.filter { !$0.isCleared }.count
            currentMessage = "だが、のこり まいすう \(remainingCardCount) まい か。この わたしを あいてに よくたたかった。"

        case .hardFoughtMessage:
            // 健闘を称えるセリフのあと、CPUが勝利を譲る
            timeoutMercyVictoryStage = .victoryConcession
            currentMessage = "よかろう、おまえの けんとうを たたえ、しょうりを ゆずってやろう。"

        case .victoryConcession:
            // 最終セリフの保持が終わったら、メッセージとポーズをそのまま維持する
            timeoutMercyVictoryStage = .finished

        case .inactive, .finished:
            return
        }
    }

    // CPUが選べるカードを失ったあとのセリフを、表示完了通知に応じて進める
    func advanceNoCPUTargetVictory(after completedMessage: String) {
        guard isNoCPUTargetVictoryActive else { return }
        guard completedMessage == currentMessage else { return }

        switch noCPUTargetVictoryStage {
        case .noCardsMessage:
            // 最初のセリフを表示し終えたら、CPUが自分の負けを認める
            noCPUTargetVictoryStage = .defeatAcknowledgement
            currentMessage = "ぐぬぬ・・・おみごと、わたしのまけだ。"

        case .defeatAcknowledgement:
            // 最後のセリフはそのまま画面に残す
            noCPUTargetVictoryStage = .finished

        case .inactive, .finished:
            return
        }
    }

    // 残り枚数が12枚になった時点でBGM2へ切り替え、その後はBGM2を維持する
    private func updateBGMForRemainingCardCount() {
        let remainingCardCount = cards.filter { !$0.isCleared }.count
        guard remainingCardCount == 12 else { return }

        SoundEffectManager.shared.switchToBGM2Permanently(fadeOutDuration: 3.0)
    }

    // CPUスキャンを停止する
    func stopCPUScan() {
        cpuScanTimer?.invalidate()
        cpuScanTimer = nil
    }

    // 選択状態と確定状態を解除する
    func clearSelection() {
        selectedCardID = nil
        confirmedCardID = nil
    }

    // PLAYER TIMEを減少させる
    func decreasePlayerTime(by seconds: Int) {
        guard seconds > 0 else { return }
        guard gameState == .playerTurn else { return }

        playerTime = max(0, playerTime - seconds)

        // PLAYER TIMEが0秒になったら、残り枚数に応じて時間切れ処理を行う
        if playerTime == 0 {
            handlePlayerTimeout()
        }
    }

    // 時間切れを処理する。残り7枚以下ならCPUが健闘を認める特別勝利にする。
    private func handlePlayerTimeout() {
        clearSelection()
        stopPlayerTimer()
        stopCPUReaction()
        stopCPUScan()

        // 時間切れ時点でCPUの選択やスキャンが残らないよう初期化する
        cpuTargetCardID = nil
        cpuTargetVocabulary = nil
        cpuScanState = .idle
        cpuScanRound = 0

        // 接続失敗・通常タイマーのどちらから0秒になっても同じ基準で判定する
        let remainingCardCount = cards.filter { !$0.isCleared }.count
        startPlayerAnimation(.failure)
        startCPUAnimation(.success)
        currentMessage = "フハハハ！時間切れだ！貴様の負けだ！"

        if remainingCardCount <= timeoutMercyVictoryRemainingCardThreshold {
            // 残り7枚以下なら、時間切れの通常セリフを経て特別勝利の演出へ進む。
            // 専用演出中はBGMを止めず、CPUの台詞完了通知で段階を切り替える。
            timeoutMercyVictoryStage = .defeatMessage
            gameResult = .playerWinTimeoutMercy
        } else {
            // それ以外の時間切れは、従来どおりCPU勝利・PLAYER敗北とする。
            timeoutMercyVictoryStage = .inactive
            gameResult = .playerLoseTimeout
            SoundEffectManager.shared.stopBGM()
        }

        gameState = .gameOver
    }








    // ゲームを終了状態にする
    func finishGame() {
        // ゲーム終了時にBGMを停止する
        SoundEffectManager.shared.stopBGM()

        clearSelection()
        stopPlayerTimer()
        stopCPUReaction()
        stopCPUScan()
        cpuTargetCardID = nil
        cpuTargetVocabulary = nil
        cpuScanState = .idle
        cpuScanRound = 0
        gameState = .gameOver
    }
}
