import SwiftUI

/// プレイ画面。表示と入力の受け渡しだけを行い、ゲームの状態は GameManager が持つ
struct PlayView: View {
    /// 現在のプレイ(AppFlow が作って渡す)
    @ObservedObject var game: GameManager

    /// 計時対象の面で計測中なら単調増加時計の開始時刻
    let timerStartedAt: TimeInterval?

    /// ギブアップが確定したときの処理(スタート画面へ戻る)
    let onGiveUp: () -> Void

    /// ギブアップの確認を表示中か
    @State private var isConfirmingGiveUp = false
    /// 鍵取得演出を表示中か
    @State private var isShowingKeyAcquisition = false
    @State private var isShowingSwordPickup = false
    /// 直近のフリック方向を矢印ガイドに表示する
    @State private var activeFlickDirection: MovementFlickDirection?
    /// プレイヤーの位置・向きが変わるたびに、メッセージ横のモンスターを動かす
    @State private var monsterReactionID = 0
    @State private var dungeonShakeOffset: CGFloat = 0
    @State private var collisionFlashOpacity = 0.0
    @State private var isShowingEventCutIn = false
    @State private var eventCutInTitle = ""
    @State private var eventCutInMessage = ""
    @State private var eventCutInStyle: PlayerCutInStyle = .wall
    @State private var eventCutInTask: Task<Void, Never>?
    /// トラップ時はカットインと状況欄の反応を同時に開始・終了する。
    @State private var isTrapReactionActive = false
    @State private var trapAnimationFrame = "PlayerIdle"
    @State private var trapAnimationOffset: CGFloat = 0
    @State private var trapAnimationTilt = 0.0
    @State private var trapAnimationTask: Task<Void, Never>?
    @State private var isBattleActionLocked = false
    @State private var battleActionTask: Task<Void, Never>?
    @State private var counterSoundTask: Task<Void, Never>?
    @State private var playerAttackAnimationID = 0

    private let battleSoundEffects = SoundEffectController()

    /// プレイヤーが鍵のあるマスにいるか
    private var isStandingAtKey: Bool {
        game.map.cell(at: game.state.player.position) == .key
    }

    /// 鍵・剣の取得演出中は、表示が重ならないよう移動入力を止める。
    private var isAcquisitionAnimationActive: Bool {
        isShowingKeyAcquisition || isShowingSwordPickup
    }

    /// イベントの状況メッセージを優先し、なければチュートリアル案内を表示する
    private var displayedMessage: String {
        game.state.message.isEmpty
            ? game.state.tutorialStep?.instruction ?? "迷宮を探索しよう"
            : game.state.message
    }

    private var playerMotionKey: String {
        "\(game.state.player.position.x),\(game.state.player.position.y),\(game.state.player.direction.rawValue)"
    }

    private func finishFlick(in direction: MovementFlickDirection) {
        activeFlickDirection = direction
    }

    /// ダンジョン画面、ステータス、メッセージ、探索マップからフリック操作を受け付ける。
    private var movementFlickGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if let direction = MovementFlickDirection.classify(
                    horizontal: value.translation.width,
                    vertical: value.translation.height,
                    threshold: 16
                ) {
                    activeFlickDirection = direction
                }
            }
            .onEnded { value in
                guard !isAcquisitionAnimationActive else { return }
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard let direction = MovementFlickDirection.classify(
                    horizontal: horizontal,
                    vertical: vertical,
                    threshold: 28
                ) else { return }

                finishFlick(in: direction)
                switch direction {
                case .left: game.turnLeft()
                case .forward: game.moveForward()
                case .right: game.turnRight()
                case .backward: game.turnAround()
                }
            }
    }

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700
            let dungeonHeight = min(geometry.size.height * (isCompact ? 0.38 : 0.41), geometry.size.width * 0.98)
            let explorationMapHeight = max(geometry.size.height * (isCompact ? 0.14 : 0.18), isCompact ? 100 : 135)

            VStack(spacing: isCompact ? 6 : 10) {
            // ① ダンジョン画面
            DungeonView(
                map: game.map,
                player: game.state.player,
                theme: game.stage.dungeonTheme
            )
            .overlay {
                if let battle = game.state.enemyBattle {
                    EnemyBattleView(
                        battle: battle,
                        playerHP: game.state.playerHP
                    )
                    .transition(.opacity)
                    .zIndex(3)
                }
            }
            .overlay {
                if let speech = game.encounterEnemySpeech {
                    EnemyEncounterSpeechOverlay(
                        speech: speech,
                        showEnemySprite: game.state.enemyBattle == nil
                    )
                    .id(speech.id)
                    .zIndex(4)
                }
            }
            .overlay {
                if let speech = game.defeatedEnemySpeech {
                    EnemyDefeatSpeechOverlay(speech: speech)
                        .id(speech.id)
                        .zIndex(3)
                }
            }
            .overlay {
                if isStandingAtKey {
                    KeyAcquisitionView(
                        hasKey: game.state.hasKey,
                        isAcquiringKey: isShowingKeyAcquisition,
                        onFinished: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                isShowingKeyAcquisition = false
                            }
                        }
                    )
                    .padding(2)
                    .transition(.opacity)
                }
            }
            .overlay {
                if isShowingSwordPickup {
                    SwordPickupView {
                        withAnimation(.easeOut(duration: 0.22)) {
                            isShowingSwordPickup = false
                        }
                    }
                    .padding(2)
                    .transition(.opacity)
                    .zIndex(4)
                }
            }
            .overlay {
                Rectangle()
                    .fill(Color(red: 0.75, green: 0.12, blue: 0.16).opacity(collisionFlashOpacity))
                    .allowsHitTesting(false)
            }
            .offset(x: dungeonShakeOffset)
            .contentShape(Rectangle())
            .simultaneousGesture(movementFlickGesture)
            .frame(height: dungeonHeight)

            // ステージと鍵の状態は、イベントメッセージが変わっても常に確認できる
            statusBar
                .contentShape(Rectangle())
                .simultaneousGesture(movementFlickGesture)

            // ② メッセージ(段階案内と状況メッセージを固定の高さに表示する)
            MonsterMessageView(
                message: displayedMessage,
                reactionID: monsterReactionID,
                surpriseReactionID: game.surpriseReactionID,
                isTrapReactionActive: isTrapReactionActive,
                trapAnimationFrame: trapAnimationFrame,
                trapAnimationOffset: trapAnimationOffset,
                trapAnimationTilt: trapAnimationTilt,
                wallCollisionID: game.wallCollisionID,
                playerAttackAnimationID: playerAttackAnimationID,
                battle: game.state.enemyBattle,
                playerHP: game.state.playerHP,
                isTutorial: game.stage.isStepByStepTutorial
            )
                .contentShape(Rectangle())
                .simultaneousGesture(movementFlickGesture)

            // ③ 探索マップ
            AutoMapView(
                map: game.map,
                explored: game.state.explored,
                player: game.state.player,
                defeatedEnemies: game.state.defeatedEnemies
            )
            .frame(maxWidth: .infinity)
            .frame(height: explorationMapHeight)
            .contentShape(Rectangle())
            .simultaneousGesture(movementFlickGesture)

            // ④ コマンド
            CommandView(
                onTurnLeft: game.turnLeft,
                onForward: game.moveForward,
                onTurnRight: game.turnRight,
                onTurnAround: game.turnAround,
                activeFlickDirection: $activeFlickDirection,
                onFlickEnded: { finishFlick(in: $0) },
                onGiveUp: { isConfirmingGiveUp = true },   // まず確認を表示する
                isBattling: game.state.enemyBattle != nil,
                isMovementDisabled: isAcquisitionAnimationActive || game.isInputLocked || game.state.isGameOver,
                isBattleActionDisabled: isBattleActionLocked || game.state.isGameOver,
                onBattleAttack: performBattleAttack,
                onBattleFlee: performBattleFlee,
                timerStartedAt: timerStartedAt
            )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DungeonBackground())
        }
        // ギブアップの確認(表示中は、後ろの操作を受け付けない)
        .overlay {
            if isConfirmingGiveUp {
                GiveUpConfirmView(
                    onYes: onGiveUp,
                    onNo: { isConfirmingGiveUp = false }
                )
            }
        }
        .overlay(alignment: .top) {
            if isShowingEventCutIn {
                PlayerEventCutIn(
                    title: eventCutInTitle,
                    message: eventCutInMessage,
                    style: eventCutInStyle,
                    animationFrame: eventCutInStyle == .trap ? trapAnimationFrame : nil,
                    animationOffset: eventCutInStyle == .trap ? trapAnimationOffset : 0,
                    animationTilt: eventCutInStyle == .trap ? trapAnimationTilt : 0
                )
                    .padding(.horizontal, 14)
                    .padding(.top, 58)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .onChange(of: game.state.hasKey) { hadKey, hasKey in
            // hasKey が初めて false から true になったときだけ演出する
            if !hadKey && hasKey {
                withAnimation(.easeIn(duration: 0.12)) {
                    isShowingKeyAcquisition = true
                }
            }
        }
        .onChange(of: game.state.hasSword) { hadSword, hasSword in
            // 剣を初めて取得した瞬間、ダンジョン表示にアイテムを重ねる。
            if !hadSword && hasSword {
                withAnimation(.easeIn(duration: 0.12)) {
                    isShowingSwordPickup = true
                }
            }
        }
        .onChange(of: isStandingAtKey) { _, isAtKey in
            // 演出中に鍵のあるマスを離れたら、再入場時は空の宝箱を表示する
            if !isAtKey {
                isShowingKeyAcquisition = false
            }
        }
        .onChange(of: playerMotionKey) { _, _ in
            monsterReactionID += 1
        }
        .onChange(of: game.wallCollisionID) { _, _ in
            playWallCollisionAnimation()
        }
        .onChange(of: game.trapActivationID) { _, _ in
            showEventCutIn(title: "TRAP!", message: "滑った、、", style: .trap, startsTrapReaction: true)
        }
        .onChange(of: game.enemyEncounterID) { _, _ in
            showEventCutIn(title: "ENCOUNTER", message: "敵が現れた！", style: .encounter)
        }
        .onChange(of: game.state.playerHP) { oldHP, newHP in
            guard newHP < oldHP, game.state.enemyBattle != nil else { return }
            counterSoundTask?.cancel()
            counterSoundTask = Task { @MainActor in
                // 攻撃音の後に反撃音が続くよう、短い間隔を空ける。
                try? await Task.sleep(nanoseconds: 360_000_000)
                guard !Task.isCancelled else { return }
                battleSoundEffects.play(named: "戦闘反撃")
                counterSoundTask = nil
            }
        }
        .onDisappear {
            battleActionTask?.cancel()
            counterSoundTask?.cancel()
            eventCutInTask?.cancel()
            trapAnimationTask?.cancel()
            isTrapReactionActive = false
            trapAnimationFrame = "PlayerIdle"
            trapAnimationOffset = 0
            trapAnimationTilt = 0
        }
    }

    private func performBattleAttack() {
        guard !isBattleActionLocked, game.state.enemyBattle != nil else { return }
        isBattleActionLocked = true
        playerAttackAnimationID += 1
        battleSoundEffects.play(named: "戦闘攻撃")
        battleActionTask?.cancel()
        battleActionTask = Task { @MainActor in
            // Playerの踏み込み攻撃を見せてから、敵へのダメージと反撃を進める。
            try? await Task.sleep(nanoseconds: 530_000_000)
            guard !Task.isCancelled else { return }
            game.attackEnemy()
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            isBattleActionLocked = false
            battleActionTask = nil
        }
    }

    private func performBattleFlee() {
        guard !isBattleActionLocked, game.state.enemyBattle != nil else { return }
        isBattleActionLocked = true
        battleSoundEffects.play(named: "戦闘逃走")
        battleActionTask?.cancel()
        battleActionTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            game.fleeBattle()
            isBattleActionLocked = false
            battleActionTask = nil
        }
    }

    private func playWallCollisionAnimation() {
        Task { @MainActor in
            showEventCutIn(title: "WALL IMPACT", message: "痛い・・・", style: .wall)
            withAnimation(.easeOut(duration: 0.07)) { collisionFlashOpacity = 0.24 }
            for offset in [CGFloat(-8), 7, -4, 0] {
                withAnimation(.easeOut(duration: 0.05)) { dungeonShakeOffset = offset }
                try? await Task.sleep(nanoseconds: 55_000_000)
            }
            withAnimation(.easeOut(duration: 0.18)) { collisionFlashOpacity = 0 }
        }
    }

    private func showEventCutIn(
        title: String,
        message: String,
        style: PlayerCutInStyle,
        startsTrapReaction: Bool = false
    ) {
        eventCutInTask?.cancel()
        trapAnimationTask?.cancel()
        trapAnimationTask = nil
        isTrapReactionActive = startsTrapReaction
        trapAnimationFrame = startsTrapReaction ? "PlayerMove1" : "PlayerIdle"
        trapAnimationOffset = 0
        trapAnimationTilt = 0
        eventCutInTitle = title
        eventCutInMessage = message
        eventCutInStyle = style
        if startsTrapReaction {
            startTrapReactionAnimation()
        }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
            isShowingEventCutIn = true
        }
        eventCutInTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_250_000_000)
            guard !Task.isCancelled else { return }
            trapAnimationTask?.cancel()
            trapAnimationTask = nil
            withAnimation(.easeIn(duration: 0.2)) {
                isShowingEventCutIn = false
                isTrapReactionActive = false
                trapAnimationFrame = "PlayerIdle"
                trapAnimationOffset = 0
                trapAnimationTilt = 0
            }
            eventCutInTask = nil
        }
    }

    /// 状況欄とカットインに同じ目を開けたフレーム・揺れ・傾きを配る。
    private func startTrapReactionAnimation() {
        let frames: [(String, CGFloat, Double)] = [
            ("PlayerMove1", -8, -12),
            ("PlayerMove2", 9, 11),
            ("PlayerMove3", -6, -8),
            ("PlayerIdle", 5, 7),
            ("PlayerMove1", -2, -3)
        ]
        var frameIndex = 0
        trapAnimationTask = Task { @MainActor in
            while !Task.isCancelled {
                let (frame, offset, tilt) = frames[frameIndex % frames.count]
                withAnimation(.spring(response: 0.07, dampingFraction: 0.4)) {
                    trapAnimationFrame = frame
                    trapAnimationOffset = offset
                    trapAnimationTilt = tilt
                }
                try? await Task.sleep(nanoseconds: 105_000_000)
                guard !Task.isCancelled else { return }
                frameIndex += 1
            }
        }
    }

    private var statusBar: some View {
        let keyText: String
        if !game.state.requiresKey {
            keyText = "不要"
        } else {
            keyText = game.state.hasKey ? "所持" : "未取得"
        }

        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(game.stage.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0.88, green: 0.84, blue: 0.73))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let seed = game.stage.seed {
                    Text("SEED \(String(format: "%016llX", seed))")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                        .accessibilityLabel("seed \(seed)")
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 5) {
                if game.stage.requiresSwordForKey {
                    Text("⚔")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(game.state.hasSword ? Color(red: 1.0, green: 0.79, blue: 0.25) : .white.opacity(0.35))
                    Text(game.state.hasSword ? "剣：所持" : "剣：未所持")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(game.state.hasSword ? Color(red: 1.0, green: 0.79, blue: 0.25) : .white.opacity(0.68))
                }
                Image("key")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 19, height: 19)
                    .opacity(game.state.hasKey ? 1 : 0.34)

                Text("鍵：\(keyText)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(
                        game.state.hasKey
                            ? Color(red: 1.0, green: 0.83, blue: 0.36)
                            : Color.white.opacity(0.84)
                    )
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 34)
        .background(Color(red: 0.075, green: 0.07, blue: 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(red: 0.42, green: 0.39, blue: 0.32), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(game.stage.title)\(game.stage.seed.map { "。seed \($0)" } ?? "")。\(game.stage.requiresSwordForKey ? "剣：\(game.state.hasSword ? "所持" : "未所持")。" : "")鍵：\(keyText)")
    }
}
