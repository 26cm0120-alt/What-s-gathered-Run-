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

/// アプリ全体の画面の流れ(スタート画面 → プレイ画面 → クリア表示 → スタート画面)を管理する。
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
    }

    @Published private(set) var screen: Screen = .start

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
    /// モードの初回クリアで、今回のプレイがタイム記録対象外であることを示す
    @Published private(set) var isFirstClearRun = false

    private var currentRecordKey: String?
    private var currentModeClearKey: String?

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
        let modeClearKey = modeClearKey(for: stage)
        let hasClearedMode = modeClearKey.map(hasPreviouslyClearedMode) ?? false
        let newGame = GameManager(stage: stage, wallCollisionDamageEnabled: hasClearedMode)
        lastRandomSeed = stage.seed
        currentRecordKey = clearTimeRecordKey(for: stage)
        currentModeClearKey = modeClearKey
        supportsReplayAndTiming = currentRecordKey != nil
        isFirstClearRun = supportsReplayAndTiming && !hasClearedMode
        bestClearTime = currentRecordKey.flatMap { loadBestClearTime(for: $0) }
        currentRunTime = nil
        timerStartedAt = supportsReplayAndTiming && hasClearedMode
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
                self.returnToStart()
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

    /// しりとりのプロローグ終了後、開始元に対応するゲーム画面へ進む。
    func startShiritoriGame() {
        guard case .shiritoriPrologue = screen else { return }

        if game?.stage.shiritoriStageKind == .trial {
            screen = .trialShiritoriGame
        } else {
            screen = .shiritoriGame
        }
    }

    /// しりとりの結果を受け取る。試練専用ルートは勝敗に関係なくスタートへ戻す。
    func finishShiritori(won: Bool) {
        switch screen {
        case .trialShiritoriGame:
            // 試練ルートも勝利時は既存のクリア画面・クリア音を表示する。
            if won {
                markCurrentModeAsCleared()
                saveBestClearTimeIfNeeded()
                playShiritoriEnemyFallThenShowClear()
            } else {
                returnToStart()
            }
        case .shiritoriGame:
            if won {
                markCurrentModeAsCleared()
                saveBestClearTimeIfNeeded()
                playShiritoriEnemyFallThenShowClear()
            } else {
                returnToStart()
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
        currentRunTime = nil
        bestClearTime = nil
        currentRecordKey = nil
        currentModeClearKey = nil
        supportsReplayAndTiming = false
        isFirstClearRun = false
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
        currentRunTime = max(0, ProcessInfo.processInfo.systemUptime - timerStartedAt)
        self.timerStartedAt = nil
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
        UserDefaults.standard.object(forKey: key) as? TimeInterval
    }

    /// 初回の成功クリア後、同じモードの次回以降を計時・壁ダメージの対象にする。
    private func markCurrentModeAsCleared() {
        guard let currentModeClearKey else { return }
        UserDefaults.standard.set(true, forKey: currentModeClearKey)
    }

    /// 以前のバージョンで保存済みのベストタイムがあれば、クリア済みとして引き継ぐ。
    private func hasPreviouslyClearedMode(_ key: String) -> Bool {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: key) { return true }

        let hasLegacyRecord: Bool
        if key == "dungeon.hasCleared.random" {
            hasLegacyRecord = defaults.dictionaryRepresentation().keys.contains {
                $0.hasPrefix("dungeon.bestClearTime.random.")
            }
        } else {
            hasLegacyRecord = defaults.object(forKey: "dungeon.bestClearTime.trial") != nil
        }

        if hasLegacyRecord {
            defaults.set(true, forKey: key)
        }
        return hasLegacyRecord
    }

    /// 試練とランダムを別々に初回クリア管理する。チュートリアルは対象外。
    private func modeClearKey(for stage: Stage) -> String? {
        if stage.seed != nil {
            return "dungeon.hasCleared.random"
        }

        guard !stage.isStepByStepTutorial else { return nil }
        switch stage.shiritoriStageKind {
        case .trial:
            return "dungeon.hasCleared.trial"
        case .standard:
            return nil
        }
    }

    /// 試練はモード共通、ランダムステージはseedごとに記録を分ける。
    private func clearTimeRecordKey(for stage: Stage) -> String? {
        if let seed = stage.seed {
            return "dungeon.bestClearTime.random.\(String(format: "%016llX", seed))"
        }

        guard !stage.isStepByStepTutorial else { return nil }
        switch stage.shiritoriStageKind {
        case .trial:
            return "dungeon.bestClearTime.trial"
        case .standard:
            return nil
        }
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
