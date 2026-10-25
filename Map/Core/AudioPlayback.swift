import AVFoundation
import Foundation
import OSLog

/// Map/Audioに置く音源と拡張子の対応をここに集約する。
enum AudioResource: Hashable {
    case titleBGM
    case explorationBGM
    case trialBGM
    case templeBGM
    case caveBGM
    case hellBGM
    case forestMansionBGM
    case normalBattleBGM
    case gargoyleBattleBGM
    case gameOver
    case gameClear
    case doorOpen
    case shiritoriEnemyFall
    case itemFound
    case chestOpen
    case movement
    case wallCollision
    case enemyDefeat
    case battleAttack
    case slimeCounterattack
    case skeletonCounterattack
    case gargoyleCounterattack
    case battleEscape

    var name: String {
        switch self {
        case .titleBGM: return "タイトルBGM"
        case .explorationBGM: return "探索BGM"
        case .trialBGM: return "試練の迷宮BGM"
        case .templeBGM: return "古代神殿BGM"
        case .caveBGM: return "水晶洞窟BGM"
        case .hellBGM: return "地獄の回廊BGM"
        case .forestMansionBGM: return "森の洋館BGM"
        case .normalBattleBGM: return "通常戦闘BGM"
        case .gargoyleBattleBGM: return "ガーゴイル戦闘BGM"
        case .gameOver: return "ゲームオーバー"
        case .gameClear: return "レトロなゲームクリア音"
        case .doorOpen: return "ドアを開ける1"
        case .shiritoriEnemyFall: return "しりとり敵撃破"
        case .itemFound: return "アイテム発見"
        case .chestOpen: return "宝箱を開ける"
        case .movement: return "移動音"
        case .wallCollision: return "壁衝突音"
        case .enemyDefeat: return "敵撃破"
        case .battleAttack: return "戦闘攻撃"
        case .slimeCounterattack: return "スライム反撃"
        case .skeletonCounterattack: return "スケルトン反撃"
        case .gargoyleCounterattack: return "ガーゴイル反撃"
        case .battleEscape: return "戦闘逃走"
        }
    }

    var fileExtension: String {
        switch self {
        case .titleBGM, .explorationBGM, .normalBattleBGM, .gargoyleBattleBGM:
            return "m4a"
        case .trialBGM, .templeBGM, .caveBGM, .hellBGM, .forestMansionBGM, .gameClear, .doorOpen, .itemFound, .chestOpen,
             .battleAttack, .slimeCounterattack, .skeletonCounterattack, .gargoyleCounterattack:
            return "mp3"
        case .gameOver, .shiritoriEnemyFall, .movement, .wallCollision, .enemyDefeat,
             .battleEscape:
            return "wav"
        }
    }

    var fileName: String { "\(name).\(fileExtension)" }
}

/// ゲーム音声の端末設定と再生失敗の記録をまとめる。
enum AudioPlayback {
    /// 通常のゲーム内BGMと効果音の音量。設定画面のスライダーで変更でき、未設定時は0.5。
    static var backgroundMusicVolume: Float { AudioVolumeSettings.backgroundMusic }
    static var soundEffectVolume: Float { AudioVolumeSettings.soundEffect }
    /// 戦闘BGM専用の音量。BGM音量に連動する(未設定時は0.3)。
    static var encounterMusicVolume: Float { AudioVolumeSettings.encounterMusic }

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "DungeonGame",
        category: "Audio"
    )

    /// AVAudioSession の有効化と AVAudioPlayer の再生開始を UI スレッドから分離する。
    private static let playbackQueue = DispatchQueue(label: "DungeonGame.AudioPlayback")
    private static var isCategoryConfigured = false
    private static var isSessionActive = false
    private static var interruptionObserver: NSObjectProtocol?

    /// 消音スイッチや画面ロックに従うゲーム向け音声カテゴリを設定する。
    static func configureForDeviceSettings() {
        performOnPlaybackQueue {
            _ = ensureSessionIsReadyOnPlaybackQueue()
        }
    }

    /// 音声処理を共通の直列キューへ送る。Shiritori側のプレイヤープールも同じキューを使う。
    static func performOnPlaybackQueue(_ operation: @escaping () -> Void) {
        playbackQueue.async(execute: operation)
    }

    /// 音声セッションの準備を終えてから再生する。呼び出し元は共通キュー上であること。
    @discardableResult
    static func prepareAndPlayOnPlaybackQueue(
        _ player: AVAudioPlayer,
        for resource: AudioResource
    ) -> Bool {
        prepareAndPlayOnPlaybackQueue(player, assetName: resource.fileName)
    }

    /// 共通対応表に登録されていないShiritori Asset Catalog音源を再生する。
    @discardableResult
    static func prepareAndPlayOnPlaybackQueue(
        _ player: AVAudioPlayer,
        assetName: String
    ) -> Bool {
        dispatchPrecondition(condition: .onQueue(playbackQueue))
        guard ensureSessionIsReadyOnPlaybackQueue() else { return false }
        guard player.prepareToPlay() else {
            logger.error("音源の再生準備に失敗しました: \(assetName, privacy: .public)")
            return false
        }
        guard player.play() else {
            logger.error("音源の再生開始に失敗しました: \(assetName, privacy: .public)")
            return false
        }
        return true
    }

    private static func ensureSessionIsReadyOnPlaybackQueue() -> Bool {
        dispatchPrecondition(condition: .onQueue(playbackQueue))
        let session = AVAudioSession.sharedInstance()
        installInterruptionObserverIfNeeded(for: session)

        if !isCategoryConfigured {
            do {
                try session.setCategory(.soloAmbient)
                isCategoryConfigured = true
            } catch {
                logger.error("音声セッションの設定に失敗しました: \(error.localizedDescription, privacy: .public)")
                return false
            }
        }

        if !isSessionActive {
            do {
                // iOSでは非同期activate APIが利用できないため、専用キューで同期APIを呼ぶ。
                try session.setActive(true)
                isSessionActive = true
            } catch {
                logger.error("音声セッションの有効化に失敗しました: \(error.localizedDescription, privacy: .public)")
                return false
            }
        }
        return true
    }

    private static func installInterruptionObserverIfNeeded(for session: AVAudioSession) {
        guard interruptionObserver == nil else { return }
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: nil
        ) { _ in
            performOnPlaybackQueue {
                // 通話などで中断された後は、次の再生要求時にセッションを再有効化する。
                isSessionActive = false
            }
        }
    }

    /// 対応表から音源を読み込み、取得に失敗した場合は記録する。準備と再生は専用キューで行う。
    static func makePlayer(for resource: AudioResource) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resource.name, withExtension: resource.fileExtension) else {
            logger.error("音源ファイルが見つかりません: \(resource.fileName, privacy: .public)")
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = soundEffectVolume
            return player
        } catch {
            logger.error("音源の読み込みに失敗しました: \(resource.fileName, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// 再生開始に失敗した場合は記録する。
    static func play(
        _ player: AVAudioPlayer,
        for resource: AudioResource,
        onFailure: (() -> Void)? = nil
    ) {
        performOnPlaybackQueue {
            guard prepareAndPlayOnPlaybackQueue(player, for: resource) else {
                if let onFailure {
                    DispatchQueue.main.async(execute: onFailure)
                }
                return
            }
        }
    }

    /// 再生停止も同じキューに並べ、再生開始との競合を避ける。
    static func stop(_ player: AVAudioPlayer?) {
        guard let player else { return }
        performOnPlaybackQueue { player.stop() }
    }

    /// 再生中プレイヤーの音量変更を共通キューに並べる。
    static func setVolume(_ volume: Float, on player: AVAudioPlayer) {
        performOnPlaybackQueue { player.volume = volume }
    }

    /// 再生中のデコードエラーを記録する。
    static func logDecodeError(for resource: AudioResource, error: Error?) {
        if let error {
            logger.error("音源のデコードに失敗しました: \(resource.fileName, privacy: .public): \(error.localizedDescription, privacy: .public)")
        } else {
            logger.error("音源のデコードに失敗しました: \(resource.fileName, privacy: .public)")
        }
    }
}

/// AVAudioPlayerのデコードエラーを記録する。呼び出し側でプレイヤーと一緒に保持する。
final class AudioPlaybackErrorDelegate: NSObject, AVAudioPlayerDelegate {
    private let resource: AudioResource

    init(resource: AudioResource) {
        self.resource = resource
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        AudioPlayback.logDecodeError(for: resource, error: error)
    }
}

/// 効果音プレイヤーを保持し、同じ音が連続したら先頭から再生し直す。
final class SoundEffectController {
    private var players: [AudioResource: AVAudioPlayer] = [:]
    private var delegates: [AudioResource: AudioPlaybackErrorDelegate] = [:]

    func play(_ resource: AudioResource, rate: Float = 1.0) {
        AudioPlayback.performOnPlaybackQueue { [weak self] in
            guard let self else { return }
            let player: AVAudioPlayer
            if let retainedPlayer = self.players[resource] {
                retainedPlayer.stop()
                retainedPlayer.currentTime = 0
                // 設定画面で変更された効果音の音量を、再利用するプレイヤーにも反映する。
                retainedPlayer.volume = AudioPlayback.soundEffectVolume
                player = retainedPlayer
            } else {
                guard let newPlayer = AudioPlayback.makePlayer(for: resource) else { return }
                let delegate = AudioPlaybackErrorDelegate(resource: resource)
                newPlayer.volume = AudioPlayback.soundEffectVolume
                newPlayer.delegate = delegate
                self.players[resource] = newPlayer
                self.delegates[resource] = delegate
                player = newPlayer
            }
            // 再生速度をAVAudioPlayerの許容範囲内に制限する。
            player.enableRate = true
            player.rate = min(max(rate, 0.5), 2.0)
            AudioPlayback.prepareAndPlayOnPlaybackQueue(player, for: resource)
        }
    }
}
