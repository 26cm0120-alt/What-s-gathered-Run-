import Foundation
import Combine
import AVFoundation
import UIKit

private final class AudioPlayerCompletionDelegate: NSObject, AVAudioPlayerDelegate {
    private let resourceName: String
    private let fileExtension: String
    private let completion: () -> Void
    private var hasCompleted = false

    init(resourceName: String, fileExtension: String, completion: @escaping () -> Void) {
        self.resourceName = resourceName
        self.fileExtension = fileExtension
        self.completion = completion
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        finish()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        AudioPlayback.logDecodeError(for: resourceName, withExtension: fileExtension, error: error)
        finish()
    }

    private func finish() {
        guard !hasCompleted else { return }
        hasCompleted = true
        completion()
    }
}

/// アプリ全体の画面の流れ(スタート画面 → プレイ画面 → 結果表示 → スタート画面)を管理する。
/// UIは、ここが持つ状態に従って画面を切り替えて表示するだけにする(仕様書§13.1、UI仕様書§8)
final class AppFlow: ObservableObject {
    /// 画面の状態
    enum Screen {
        case start              // ダンジョンのスタート画面
        case playing            // ダンジョンのプレイ画面
        case shiritoriPrologue  // しりとりの既存プロローグ
        case shiritoriGame      // 既存のしりとりゲーム
        case trialShiritoriGame // 試練の迷宮専用しりとりゲーム
        case cleared            // ダンジョンのクリア表示
        case gameOver           // 敗北後に表示する共通ゲームオーバー画面
    }

    @Published private(set) var screen: Screen = .start
    /// 共通ゲームオーバー画面に表示する敗北理由。
    @Published private(set) var gameOverReasonMessage = "HPが0になった"
    /// 共通ゲームオーバー画面に表示する補足文。
    @Published private(set) var gameOverDetailMessage = "迷宮の探索はここで終了です"

    /// 現在のプレイ(スタート画面のときは nil)
    @Published private(set) var game: GameManager?
    /// 前回のランダムステージseed。タイトル画面から同じ迷宮を再生成できる。
    @Published private(set) var lastRandomSeed: UInt64?
    /// 計時対象ステージの計測開始時刻（単調増加時計）
    @Published private(set) var timerStartedAt: TimeInterval?
    /// G到達時に確定した今回のタイム
    @Published private(set) var currentRunTime: TimeInterval?
    /// 現在の試練モードまたはランダムseedの最短タイム
    @Published private(set) var bestClearTime: TimeInterval?
    /// 試練の迷宮・ランダムステージで再挑戦を表示する
    @Published private(set) var supportsReplayAndTiming = false
    /// クリア画面に表示する次のステージ名
    var nextStageTitle: String {
        guard let stage = game?.stage else { return "次の迷宮へ" }
        if stage.isStepByStepTutorial { return "試練の迷宮へ" }
        return stage.seed == nil ? "ランダムステージへ" : "新しいランダムステージへ"
    }
    /// スケルトンのドロップで増えた、しりとりの初期持ち時間。
    @Published private(set) var shiritoriTimeBonusSeconds = 0
    /// 選択中モードの端末内ランキング。
    @Published private(set) var leaderboardEntries: [LeaderboardEntry] = []

    private var currentRecordKey: String?
    private var currentLeaderboardMode: LeaderboardMode?

    private var titleBackgroundAudioPlayer: AVAudioPlayer?
    private var titleBackgroundAudioErrorDelegate: AudioPlaybackErrorDelegate?
    private var stageBackgroundAudioPlayer: AVAudioPlayer?
    private var stageBackgroundAudioErrorDelegate: AudioPlaybackErrorDelegate?
    private var encounterBackgroundAudioPlayer: AVAudioPlayer?
    private var encounterBackgroundAudioErrorDelegate: AudioPlaybackErrorDelegate?
    private var doorOpenAudioPlayer: AVAudioPlayer?
    private var doorOpenCompletionDelegate: AudioPlayerCompletionDelegate?
    private var shiritoriEnemyFallAudioPlayer: AVAudioPlayer?
    private var shiritoriEnemyFallCompletionDelegate: AudioPlayerCompletionDelegate?
    private var isPlayingDoorOpenSequence = false

    init() {
        AudioPlayback.configureForDeviceSettings()
        playTitleBackgroundMusic()
    }

    /// 面を選んで、プレイを開始する。
    /// 毎回、新しいゲームを作るので、前回のプレイの状態は引き継がない(仕様書§13.2)
    func startGame(stage: Stage) {
        gameOverReasonMessage = "HPが0になった"
        gameOverDetailMessage = "迷宮の探索はここで終了です"
        stopTitleBackgroundMusic()
        stopStageBackgroundMusic()
        stopEncounterBackgroundMusic()
        doorOpenAudioPlayer?.stop()
        doorOpenAudioPlayer = nil
        doorOpenCompletionDelegate = nil
        shiritoriEnemyFallAudioPlayer?.stop()
        shiritoriEnemyFallAudioPlayer = nil
        shiritoriEnemyFallCompletionDelegate = nil
        isPlayingDoorOpenSequence = false
        let newGame = GameManager(
            stage: stage,
            wallCollisionDamageEnabled: !stage.isStepByStepTutorial
        )
        lastRandomSeed = stage.seed
        currentRecordKey = clearTimeRecordKey(for: stage)
        supportsReplayAndTiming = currentRecordKey != nil
        shiritoriTimeBonusSeconds = 0
        currentLeaderboardMode = leaderboardMode(for: stage)
        leaderboardEntries = currentLeaderboardMode.map { LocalLeaderboard.load($0) } ?? []
        bestClearTime = currentRecordKey.flatMap { loadBestClearTime(for: $0) }
        currentRunTime = nil
        timerStartedAt = supportsReplayAndTiming
            ? ProcessInfo.processInfo.systemUptime
            : nil
        // ドアの音が終わってからしりとりのプロローグへ切り替える
        newGame.onCleared = { [weak self, weak newGame] in
            guard let self, let newGame, self.game === newGame else { return }
            self.stopTimerAtGoal()
            self.playDoorOpenThenStartShiritori()
        }
        newGame.onGameOver = { [weak self, weak newGame] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                guard let self, let newGame,
                      self.game === newGame, newGame.state.isGameOver else { return }
                self.stopStageBackgroundMusic()
                self.stopEncounterBackgroundMusic()
                self.timerStartedAt = nil
                self.gameOverReasonMessage = "HPが0になった"
                self.gameOverDetailMessage = "迷宮の探索はここで終了です"
                self.screen = .gameOver
            }
        }
        newGame.onBattleStateChanged = { [weak self, weak newGame] enemyKind in
            guard let self, let newGame, self.game === newGame else { return }
            self.setEncounterBackgroundMusic(for: enemyKind, game: newGame)
        }
        game = newGame
        screen = .playing
        playStageBackgroundMusic(for: newGame.stage)
    }

    /// 新しいseedでランダムステージを開始する。
    func startRandomGame() {
        let seed = UInt64.random(in: UInt64.min...UInt64.max)
        startGame(stage: Stages.random(seed: seed))
    }

    /// 前回のseedを使って同じ迷宮を再生成する。
    func replayRandomGame(seed: UInt64) {
        startGame(stage: Stages.random(seed: seed))
    }

    /// クリアした面を最初から再開する。ランダム面は同じseedを使う。
    func replayCurrentStage() {
        guard let stage = game?.stage, supportsReplayAndTiming else { return }
        startGame(stage: stage)
    }

    /// クリア後の進行先へ移る。チュートリアルの次は試練、それ以降は新しいランダム面にする。
    func startNextStage() {
        guard case .cleared = screen, let stage = game?.stage else { return }
        if stage.isStepByStepTutorial {
            startGame(stage: Stages.trial)
        } else {
            startRandomGame()
        }
    }

    /// しりとりのプロローグ終了後、開始元に対応するゲーム画面へ進む。
    func startShiritoriGame() {
        guard case .shiritoriPrologue = screen else { return }
        shiritoriTimeBonusSeconds = game?.state.shiritoriTimeBonusSeconds ?? 0

        if game?.stage.shiritoriStageKind == .trial {
            screen = .trialShiritoriGame
        } else {
            screen = .shiritoriGame
        }
    }

    /// しりとりの結果を受け取り、勝利はクリア画面、敗北は共通ゲームオーバー画面へ進める。
    func finishShiritori(won: Bool) {
        switch screen {
        case .trialShiritoriGame:
            // 試練ルートも勝利時は既存のクリア画面・クリア音を表示する。
            if won {
                saveBestClearTimeIfNeeded()
                playShiritoriEnemyFallThenShowClear()
            } else {
                gameOverReasonMessage = "時間切れ・・・"
                gameOverDetailMessage = "しりとりはここで終了です"
                screen = .gameOver
            }
        case .shiritoriGame:
            if won {
                saveBestClearTimeIfNeeded()
                playShiritoriEnemyFallThenShowClear()
            } else {
                gameOverReasonMessage = "時間切れ・・・"
                gameOverDetailMessage = "しりとりはここで終了です"
                screen = .gameOver
            }
        default:
            return
        }
    }

    /// スタート画面に戻る。現在のプレイの状態は破棄する
    func returnToStart() {
        stopStageBackgroundMusic()
        stopEncounterBackgroundMusic()
        doorOpenAudioPlayer?.stop()
        doorOpenAudioPlayer = nil
        doorOpenCompletionDelegate = nil
        isPlayingDoorOpenSequence = false
        shiritoriEnemyFallAudioPlayer?.stop()
        shiritoriEnemyFallAudioPlayer = nil
        shiritoriEnemyFallCompletionDelegate = nil
        timerStartedAt = nil
        gameOverReasonMessage = "HPが0になった"
        gameOverDetailMessage = "迷宮の探索はここで終了です"
        currentRunTime = nil
        bestClearTime = nil
        currentRecordKey = nil
        supportsReplayAndTiming = false
        shiritoriTimeBonusSeconds = 0
        leaderboardEntries = []
        currentLeaderboardMode = nil
        game = nil
        screen = .start
        playTitleBackgroundMusic()
    }

    /// ドアを開ける音を最後まで再生してから、しりとりのプロローグへ進む。
    private func playDoorOpenThenStartShiritori() {
        guard !isPlayingDoorOpenSequence else { return }
        isPlayingDoorOpenSequence = true
        stopStageBackgroundMusic()
        stopEncounterBackgroundMusic()
        let gameAtClear = game

        guard let player = AudioPlayback.makePlayer(named: "ドアを開ける1") else {
            isPlayingDoorOpenSequence = false
            screen = .shiritoriPrologue
            return
        }

        let completionDelegate = AudioPlayerCompletionDelegate(resourceName: "ドアを開ける1", fileExtension: "mp3") { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.doorOpenAudioPlayer = nil
                self.doorOpenCompletionDelegate = nil
                self.isPlayingDoorOpenSequence = false
                guard self.game === gameAtClear, case .playing = self.screen else { return }
                self.screen = .shiritoriPrologue
            }
        }
        doorOpenAudioPlayer = player
        doorOpenCompletionDelegate = completionDelegate
        player.delegate = completionDelegate
        if !AudioPlayback.play(player, named: "ドアを開ける1") {
            doorOpenAudioPlayer = nil
            doorOpenCompletionDelegate = nil
            isPlayingDoorOpenSequence = false
            screen = .shiritoriPrologue
        }
    }

    /// しりとり勝利後、敵が倒れる音を再生し終えてからクリア画面を出す。
    private func playShiritoriEnemyFallThenShowClear() {
        guard let player = AudioPlayback.makePlayer(named: "しりとり敵撃破", withExtension: "wav") else {
            showClearScreenAfterShiritoriWin()
            return
        }
        let delegate = AudioPlayerCompletionDelegate(resourceName: "しりとり敵撃破", fileExtension: "wav") { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.shiritoriEnemyFallAudioPlayer = nil
                self.shiritoriEnemyFallCompletionDelegate = nil
                self.showClearScreenAfterShiritoriWin()
            }
        }
        shiritoriEnemyFallAudioPlayer = player
        shiritoriEnemyFallCompletionDelegate = delegate
        player.delegate = delegate
        if !AudioPlayback.play(player, named: "しりとり敵撃破", withExtension: "wav") {
            shiritoriEnemyFallAudioPlayer = nil
            shiritoriEnemyFallCompletionDelegate = nil
            showClearScreenAfterShiritoriWin()
        }
    }

    private func showClearScreenAfterShiritoriWin() {
        switch screen {
        case .shiritoriGame, .trialShiritoriGame:
            screen = .cleared
        default:
            break
        }
    }

    /// ステージ中のBGMをループ再生する。
    private func playStageBackgroundMusic(for stage: Stage) {
        let resourceName = stage.dungeonTheme?.backgroundMusicName ?? "探索BGM"
        let fileExtension = stage.dungeonTheme?.backgroundMusicExtension ?? "mp3"
        guard let player = AudioPlayback.makePlayer(named: resourceName, withExtension: fileExtension) else { return }

        player.volume = AudioPlayback.backgroundMusicVolume
        player.numberOfLoops = -1
        let errorDelegate = AudioPlaybackErrorDelegate(resourceName: resourceName, fileExtension: fileExtension)
        player.delegate = errorDelegate
        guard AudioPlayback.play(player, named: resourceName, withExtension: fileExtension) else { return }
        stageBackgroundAudioPlayer = player
        stageBackgroundAudioErrorDelegate = errorDelegate
    }

    /// 敵との戦闘中だけ新しい戦闘BGMをループし、通常探索BGMと重ねない。
    private func setEncounterBackgroundMusic(for enemyKind: EnemyKind?, game: GameManager) {
        if let enemyKind {
            stopStageBackgroundMusic()
            stopEncounterBackgroundMusic()
            let resourceName = enemyKind == .gargoyle ? "ガーゴイル戦闘BGM" : "通常戦闘BGM"
            guard let player = AudioPlayback.makePlayer(named: resourceName, withExtension: "wav") else {
                playStageBackgroundMusic(for: game.stage)
                return
            }
            player.volume = AudioPlayback.encounterMusicVolume
            player.numberOfLoops = -1
            let delegate = AudioPlaybackErrorDelegate(resourceName: resourceName, fileExtension: "wav")
            player.delegate = delegate
            guard AudioPlayback.play(player, named: resourceName, withExtension: "wav") else {
                playStageBackgroundMusic(for: game.stage)
                return
            }
            encounterBackgroundAudioPlayer = player
            encounterBackgroundAudioErrorDelegate = delegate
        } else {
            stopEncounterBackgroundMusic()
            guard case .playing = screen,
                  !game.state.isCleared,
                  !game.state.isGameOver else { return }
            stopStageBackgroundMusic()
            playStageBackgroundMusic(for: game.stage)
        }
    }

    private func stopEncounterBackgroundMusic() {
        encounterBackgroundAudioPlayer?.stop()
        encounterBackgroundAudioPlayer = nil
        encounterBackgroundAudioErrorDelegate = nil
    }

    /// タイトル画面のBGMをループ再生する。
    private func playTitleBackgroundMusic() {
        guard titleBackgroundAudioPlayer?.isPlaying != true,
              let player = AudioPlayback.makePlayer(named: "タイトルBGM") else { return }

        player.volume = AudioPlayback.backgroundMusicVolume
        player.numberOfLoops = -1
        let errorDelegate = AudioPlaybackErrorDelegate(resourceName: "タイトルBGM")
        player.delegate = errorDelegate
        guard AudioPlayback.play(player, named: "タイトルBGM") else { return }
        titleBackgroundAudioPlayer = player
        titleBackgroundAudioErrorDelegate = errorDelegate
    }

    /// タイトル画面を離れるときにタイトルBGMを止める。
    private func stopTitleBackgroundMusic() {
        titleBackgroundAudioPlayer?.stop()
        titleBackgroundAudioPlayer = nil
        titleBackgroundAudioErrorDelegate = nil
    }

    /// ステージを離れるときはBGMを止める。
    private func stopStageBackgroundMusic() {
        stageBackgroundAudioPlayer?.stop()
        stageBackgroundAudioPlayer = nil
        stageBackgroundAudioErrorDelegate = nil
    }

    /// タイマーは単調増加時計で計り、ゴールに入った時点で止める。
    private func stopTimerAtGoal() {
        guard let timerStartedAt else { return }
        let timeReduction = TimeInterval(game?.state.runTimeReductionSeconds ?? 0)
        currentRunTime = max(0, ProcessInfo.processInfo.systemUptime - timerStartedAt - timeReduction)
        self.timerStartedAt = nil
    }

    /// クリア画面で入力された名前を、現在のモードの上位100件へ保存する。
    func saveLeaderboardEntry(playerName: String) {
        guard let currentLeaderboardMode, let currentRunTime else { return }
        let cleanName = String(playerName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(16))
        guard !cleanName.isEmpty else { return }
        let entry = LeaderboardEntry(playerName: cleanName, clearTime: currentRunTime, seed: game?.stage.seed)
        leaderboardEntries = LocalLeaderboard.add(entry, to: currentLeaderboardMode)
        if bestClearTime == nil || currentRunTime < bestClearTime! {
            bestClearTime = currentRunTime
            if let currentRecordKey {
                UserDefaults.standard.set(currentRunTime, forKey: currentRecordKey)
            }
        }
    }

    /// 完走タイムが既存の記録より短い場合だけ端末内に保存する。
    private func saveBestClearTimeIfNeeded() {
        guard let currentRecordKey, let currentRunTime else { return }
        let savedTime = loadBestClearTime(for: currentRecordKey)
        if let savedTime, savedTime <= currentRunTime {
            bestClearTime = savedTime
            return
        }

        UserDefaults.standard.set(currentRunTime, forKey: currentRecordKey)
        bestClearTime = currentRunTime
    }

    private func loadBestClearTime(for key: String) -> TimeInterval? {
        let defaults = UserDefaults.standard
        let stored = defaults.object(forKey: key) as? TimeInterval
        guard key == "dungeon.bestClearTime.random" else { return stored }
        let legacy = defaults.dictionaryRepresentation().compactMap { name, value -> TimeInterval? in
            guard name.hasPrefix("dungeon.bestClearTime.random."),
                  let time = value as? TimeInterval else { return nil }
            return time
        }
        return ([stored].compactMap { $0 } + legacy).min()
    }

    /// 試練とランダムの最短タイムは各モード共通で保存する。
    private func clearTimeRecordKey(for stage: Stage) -> String? {
        if stage.seed != nil {
            return "dungeon.bestClearTime.random"
        }

        guard !stage.isStepByStepTutorial else { return nil }
        switch stage.shiritoriStageKind {
        case .trial:
            return "dungeon.bestClearTime.trial"
        case .standard:
            return nil
        }
    }

    private func leaderboardMode(for stage: Stage) -> LeaderboardMode? {
        if stage.seed != nil { return .random }
        guard !stage.isStepByStepTutorial, stage.shiritoriStageKind == .trial else { return nil }
        return .trial
    }
}

enum DungeonTimeFormatter {
    static func string(from time: TimeInterval) -> String {
        let tenths = Int((max(0, time) * 10).rounded(.down))
        let minutes = tenths / 600
        let seconds = (tenths / 10) % 60
        let fraction = tenths % 10
        return String(format: "%02d:%02d.%d", minutes, seconds, fraction)
    }
}
