import SwiftUI

/// プレイ画面。表示と入力の受け渡しだけを行い、ゲームの状態は GameManager が持つ
struct PlayView: View {
    /// 現在のプレイ(AppFlow が作って渡す)
    @ObservedObject var game: GameManager

    /// ギブアップが確定したときの処理(スタート画面へ戻る)
    let onGiveUp: () -> Void

    /// ギブアップの確認を表示中か
    @State private var isConfirmingGiveUp = false
    /// 鍵取得演出を表示中か
    @State private var isShowingKeyAcquisition = false
    /// 直近のフリック方向を矢印ガイドに表示する
    @State private var activeFlickDirection: MovementFlickDirection?
    /// プレイヤーの位置・向きが変わるたびに、メッセージ横のモンスターを動かす
    @State private var monsterReactionID = 0

    /// プレイヤーが鍵のあるマスにいるか
    private var isStandingAtKey: Bool {
        game.map.cell(at: game.state.player.position) == .key
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
        VStack(spacing: 12) {
            // ① ダンジョン画面
            DungeonView(
                map: game.map,
                player: game.state.player
            )
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
            .contentShape(Rectangle())
            .simultaneousGesture(movementFlickGesture)

            // ステージと鍵の状態は、イベントメッセージが変わっても常に確認できる
            statusBar
                .contentShape(Rectangle())
                .simultaneousGesture(movementFlickGesture)

            // ② メッセージ(段階案内と状況メッセージを固定の高さに表示する)
            MonsterMessageView(message: displayedMessage, reactionID: monsterReactionID)
                .contentShape(Rectangle())
                .simultaneousGesture(movementFlickGesture)

            // ③ 探索マップ
            AutoMapView(
                map: game.map,
                explored: game.state.explored,
                player: game.state.player
            )
            .frame(maxWidth: .infinity)
            .frame(height: 210)
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
                onGiveUp: { isConfirmingGiveUp = true }   // まず確認を表示する
            )
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        // ギブアップの確認(表示中は、後ろの操作を受け付けない)
        .overlay {
            if isConfirmingGiveUp {
                GiveUpConfirmView(
                    onYes: onGiveUp,
                    onNo: { isConfirmingGiveUp = false }
                )
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
        .onChange(of: isStandingAtKey) { _, isAtKey in
            // 演出中に鍵のあるマスを離れたら、再入場時は空の宝箱を表示する
            if !isAtKey {
                isShowingKeyAcquisition = false
            }
        }
        .onChange(of: playerMotionKey) { _, _ in
            monsterReactionID += 1
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
                if let seed = game.stage.seed {
                    Text("SEED \(String(format: "%016llX", seed))")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                        .accessibilityLabel("seed \(seed)")
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 5) {
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
        .accessibilityLabel("\(game.stage.title)\(game.stage.seed.map { "。seed \($0)" } ?? "")。鍵：\(keyText)")
    }
}
