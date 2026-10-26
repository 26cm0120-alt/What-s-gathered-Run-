//
//  SoundEffectManager.swift
//  shiritori
//
//  効果音・BGMの再生を一元管理する
//

import Foundation
import AVFoundation
import UIKit
import OSLog

/// 効果音とBGMの再生を一元管理するクラス
final class SoundEffectManager: NSObject, AVAudioPlayerDelegate {

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "DungeonGame",
        category: "ShiritoriBGM"
    )

    /// しりとり画面のBGM・効果音は、設定画面で決めた音量(初期値50%)で再生する。
    private var backgroundMusicVolume: Float { AudioPlayback.backgroundMusicVolume }
    private var soundEffectVolume: Float { AudioPlayback.soundEffectVolume }

    /// アプリ全体で共通して使用する効果音管理インスタンス
    static let shared = SoundEffectManager()

    /// 連続する効果音でプレイヤーを毎回生成しないよう、音源ごとに少数を再利用する。
    /// 同じ効果音が重なった場合だけ、最大数まで追加プレイヤーを作る。
    private let effectPlayerPoolLimit = 4
    private var effectPlayerPools: [String: [AVAudioPlayer]] = [:]
    private var nextEffectPlayerIndex: [String: Int] = [:]

    /// 現在再生中のBGMプレイヤー
    private var bgmPlayer: AVAudioPlayer?

    /// 現在再生中のBGM番号
    /// 1 = BGM1、2 = BGM2
    private var currentBGMNumber: Int = 0

    /// BGM1からBGM2へ移行する際のフェードタイマー
    private var bgmFadeTimer: Timer?

    /// 残り12枚の条件を満たした後、BGM2を永久ループさせるかどうか
    private var isBGM2LockedPermanently = false

    /// 外部から直接インスタンスを作成しない
    private override init() {
        super.init()
    }

    /// 指定したData Setの音声を効果音として再生する
    /// - Parameter assetName: Assets.xcassets内のData Set名
    private func play(assetName: String, volume: Float? = nil) {
        AudioPlayback.performOnPlaybackQueue { [weak self] in
            self?.playEffectOnQueue(assetName: assetName, volume: volume)
        }
    }

    /// 効果音キュー上でプレイヤーを取得または生成し、先頭から再生する。
    private func playEffectOnQueue(assetName: String, volume: Float?) {
        var players = effectPlayerPools[assetName, default: []]
        let player: AVAudioPlayer

        if let idlePlayer = players.first(where: { !$0.isPlaying }) {
            idlePlayer.currentTime = 0
            player = idlePlayer
        } else if players.count < effectPlayerPoolLimit {
            guard let asset = NSDataAsset(name: assetName),
                  let newPlayer = try? AVAudioPlayer(data: asset.data) else {
                return
            }
            players.append(newPlayer)
            effectPlayerPools[assetName] = players
            player = newPlayer
        } else {
            // 効果音が重なり続けてもプレイヤー数を増やさず、最も古い枠を再利用する。
            let index = nextEffectPlayerIndex[assetName, default: 0] % players.count
            let reusedPlayer = players[index]
            reusedPlayer.stop()
            reusedPlayer.currentTime = 0
            nextEffectPlayerIndex[assetName] = (index + 1) % players.count
            player = reusedPlayer
        }

        player.volume = volume ?? soundEffectVolume
        AudioPlayback.prepareAndPlayOnPlaybackQueue(player, assetName: assetName)
    }

    /// プレイヤー・CPUのカーソル移動音を再生する
    func playCursor() {
        play(assetName: "shiritori_card_cursor_01")
    }

    /// しりとりでカードを選んだ時の軽い触覚を返す。
    /// CPUのスキャン移動ではなく、カード選択が確定した時に呼び出す。
    func playCardSelectionHaptic() {
        Haptics.selection()
    }

    /// 画面上のボタン押下音を再生する。既存の短いUIカーソル音を共用する。
    func playButtonTap() {
        play(assetName: "shiritori_card_cursor_01")
    }

    /// メッセージを一文字表示するたびに鳴らす効果音を再生する
    func playMessageBeep() {
        play(assetName: "shiritori_message_beep")
    }

    /// 正解音を再生する
    func playSuccess() {
        play(assetName: "shiritori_seikai_pop_v3")
    }

    /// 不正解音を再生する
    func playFailure() {
        play(assetName: "shiritori_fuseikai_pop_v3")
    }

    /// PLAYER敗北メッセージの表示完了後に、敗北用BGMを1回だけ再生する
    func playDefeatBGMOnce() {
        // 共通再生処理はループ設定を行わないため、音源を最後まで1回だけ再生する
        play(assetName: "shiritori_defeat_death_bgm_3sec")
    }

    // MARK: - プロローグBGM

    /// プロローグ専用BGMを1回だけ再生する
    func startPrologueBGM() {

        // すでに再生中のBGMを停止する
        stopBGM()

        // Assets.xcassets内のプロローグBGMを取得する
        guard let asset = NSDataAsset(
            name: "nes_boss_15sec_rhythmic"
        ) else {
            return
        }

        do {
            let player = try AVAudioPlayer(data: asset.data)

            player.volume = backgroundMusicVolume

            // プロローグBGMはループさせない
            player.numberOfLoops = 0

            bgmPlayer = player
            AudioPlayback.performOnPlaybackQueue {
                AudioPlayback.prepareAndPlayOnPlaybackQueue(
                    player,
                    assetName: "nes_boss_15sec_rhythmic"
                )
            }

        } catch {
            bgmPlayer = nil
        }
    }

    /// プロローグBGMを停止する
    func stopPrologueBGM() {
        AudioPlayback.stop(bgmPlayer)
        bgmPlayer = nil
        currentBGMNumber = 0
    }

    // MARK: - ゲーム中BGM

    /// しりとりゲーム中のBGMをBGM1から開始する
    /// BGM1終了後はBGM2、BGM2終了後はBGM1へ戻り、繰り返し再生する
    func startBGM() {
        #if DEBUG
        Self.logger.debug("startBGM called")
        #endif
        stopBGM()
        currentBGMNumber = 1
        playCurrentBGM()
    }

    /// 現在のBGMを停止する
    func stopBGM() {
        // 診断用：BGM停止がどのタイミングで呼ばれたかを確認する
        #if DEBUG
        Self.logger.debug("stopBGM called; currentBGMNumber=\(self.currentBGMNumber), isPlaying=\(self.bgmPlayer?.isPlaying ?? false)")
        #endif
        // BGMを停止する際は、フェード処理と固定ループ設定も解除する
        bgmFadeTimer?.invalidate()
        bgmFadeTimer = nil
        isBGM2LockedPermanently = false
        AudioPlayback.stop(bgmPlayer)
        bgmPlayer = nil
        currentBGMNumber = 0
    }

    /// 残り12枚になった時点でBGM2へ移行し、以後はBGM2だけをループする
    /// BGM1が再生中なら指定秒数をかけて音量を下げ、終了後にBGM2へ切り替える。
    func switchToBGM2Permanently(fadeOutDuration: TimeInterval = 3.0) {
        // 同じ条件が重複して通知されても、切り替え処理を再実行しない
        guard !isBGM2LockedPermanently else { return }
        isBGM2LockedPermanently = true

        bgmFadeTimer?.invalidate()
        bgmFadeTimer = nil

        // BGM2が既に流れている場合は、フェードせずBGM2の無限ループに固定する
        if currentBGMNumber == 2, let player = bgmPlayer, player.isPlaying {
            AudioPlayback.performOnPlaybackQueue { player.numberOfLoops = -1 }
            return
        }

        // BGM1が流れていない場合は、直ちにBGM2を開始する
        guard currentBGMNumber == 1,
              let player = bgmPlayer,
              player.isPlaying,
              fadeOutDuration > 0 else {
            AudioPlayback.stop(bgmPlayer)
            bgmPlayer = nil
            currentBGMNumber = 2
            playCurrentBGM()
            return
        }

        let startingVolume = player.volume
        let fadeStartDate = Date()

        // 音量を一定間隔で少しずつ下げ、指定秒数後にBGM2へ切り替える
        bgmFadeTimer = Timer.scheduledTimer(
            withTimeInterval: 0.05,
            repeats: true
        ) { [weak self, weak player] timer in
            guard let self, let player else {
                timer.invalidate()
                return
            }
            guard self.bgmPlayer === player,
                  self.isBGM2LockedPermanently else {
                timer.invalidate()
                return
            }

            let elapsed = Date().timeIntervalSince(fadeStartDate)
            let progress = min(max(elapsed / fadeOutDuration, 0), 1)
            AudioPlayback.setVolume(startingVolume * Float(1 - progress), on: player)

            if progress >= 1 {
                self.finishBGM2Transition(from: player)
            }
        }
    }

    /// BGM1のフェードが終わったときに、永久ループするBGM2を開始する
    private func finishBGM2Transition(from previousPlayer: AVAudioPlayer) {
        bgmFadeTimer?.invalidate()
        bgmFadeTimer = nil

        // 古いプレイヤーからの完了通知が新しいBGMに影響しないよう確認する
        guard bgmPlayer === previousPlayer else { return }

        AudioPlayback.stop(previousPlayer)
        bgmPlayer = nil
        currentBGMNumber = 2
        playCurrentBGM()
    }

    /// 現在のBGM番号に対応するData Setを再生する
    private func playCurrentBGM() {
        let assetName: String

        switch currentBGMNumber {
        case 1:
            assetName = "shiritoriBGM1"

        case 2:
            assetName = "shiritoriBGM2"

        default:
            return
        }

        #if DEBUG
        Self.logger.debug("requesting asset: \(assetName, privacy: .public)")
        #endif
        guard let asset = NSDataAsset(name: assetName) else {
            Self.logger.error("ERROR: NSDataAsset not found: \(assetName, privacy: .public)")
            return
        }
        #if DEBUG
        Self.logger.debug("asset loaded: \(assetName, privacy: .public), bytes=\(asset.data.count)")
        #endif

        do {
            let player = try AVAudioPlayer(data: asset.data)
            #if DEBUG
            Self.logger.debug("AVAudioPlayer created: \(assetName, privacy: .public), duration=\(player.duration)")
            #endif
            player.volume = backgroundMusicVolume

            // 切り替え条件成立後のBGM2は、音源終了時に戻らず無限ループさせる
            if currentBGMNumber == 2 && isBGM2LockedPermanently {
                player.numberOfLoops = -1
            }

            // BGM1のみ、試験的に1.1倍速で再生する。BGM2は通常速度を維持する
            if currentBGMNumber == 1 {
                player.enableRate = true
                player.rate = 1.1
            }
            
            player.delegate = self
            bgmPlayer = player
            #if DEBUG
            let requestedBGMNumber = currentBGMNumber
            #endif
            AudioPlayback.performOnPlaybackQueue {
                #if DEBUG
                let started = AudioPlayback.prepareAndPlayOnPlaybackQueue(
                    player,
                    assetName: assetName
                )
                Self.logger.debug("playback prepared and started=\(started), number=\(requestedBGMNumber), isPlaying=\(player.isPlaying)")
                #else
                AudioPlayback.prepareAndPlayOnPlaybackQueue(player, assetName: assetName)
                #endif
            }
            #if DEBUG
            Self.logger.debug("playback request queued: \(assetName, privacy: .public), number=\(requestedBGMNumber)")
            #endif

            #if DEBUG
            // 診断専用：再生開始後も再生位置・音量・出力先が正常か確認する。
            // 再生処理やゲーム動作そのものは変更しない。
            for delay: TimeInterval in [2.0, 5.0] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak player] in
                    guard let self, let player else {
                        Self.logger.debug("after \(delay)s: player released")
                        return
                    }

                    let ownsPlayer = self.bgmPlayer === player
                    let session = AVAudioSession.sharedInstance()
                    let outputs = session.currentRoute.outputs
                        .map { "\($0.portType.rawValue):\($0.portName)" }
                        .joined(separator: ", ")

                    Self.logger.debug("after \(delay)s: currentTime=\(player.currentTime), duration=\(player.duration), volume=\(player.volume), isPlaying=\(player.isPlaying), managerOwnsPlayer=\(ownsPlayer), systemOutputVolume=\(session.outputVolume), outputs=[\(outputs, privacy: .private)]")
                }
            }
            #endif
        } catch {
            Self.logger.error("ERROR creating BGM player for \(assetName, privacy: .public): \(error.localizedDescription, privacy: .private)")
            bgmPlayer = nil
        }
    }

    /// BGM1またはBGM2の再生終了時に、次のBGMへ切り替える
    func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        DispatchQueue.main.async { [weak self, weak player] in
            guard let self, let player else { return }
            self.handleAudioPlayerDidFinishPlaying(player, successfully: flag)
        }
    }

    private func handleAudioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        #if DEBUG
        Self.logger.debug("didFinishPlaying success=\(flag), currentNumber=\(self.currentBGMNumber), currentPlayerMatches=\(player === self.bgmPlayer)")
        #endif
        guard player === bgmPlayer else {
            return
        }

        // BGM2固定モード中はBGM1へ戻さない
        if isBGM2LockedPermanently {
            if currentBGMNumber == 1 {
                // フェード中にBGM1が自然終了した場合は、BGM2へ即時移行する
                finishBGM2Transition(from: player)
            } else if currentBGMNumber == 2 {
                // 万一BGM2の終了通知が来ても、BGM2を再び開始する
                playCurrentBGM()
            }
            return
        }

        // 通常時はBGM1 → BGM2 → BGM1 の順番で繰り返す
        if currentBGMNumber == 1 {
            currentBGMNumber = 2
        } else {
            currentBGMNumber = 1
        }

        playCurrentBGM()
    }
}
