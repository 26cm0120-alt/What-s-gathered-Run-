import AVFoundation
import Foundation
import OSLog

/// Map/Audioに置く音源と拡張子の対応をここに集約する。
enum AudioResource: Hashable {
    case titleBGM
    case explorationBGM
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
    case battleCounterattack
    case battleEscape

    var name: String {
        switch self {
        case .titleBGM: return "タイトルBGM"
        case .explorationBGM: return "探索BGM"
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
        case .battleCounterattack: return "戦闘反撃"
        case .battleEscape: return "戦闘逃走"
        }
    }

    var fileExtension: String {
        switch self {
        case .titleBGM, .explorationBGM, .normalBattleBGM, .gargoyleBattleBGM:
            return "m4a"
        case .templeBGM, .caveBGM, .hellBGM, .forestMansionBGM, .gameClear, .doorOpen, .itemFound, .chestOpen:
            return "mp3"
        case .gameOver, .shiritoriEnemyFall, .movement, .wallCollision, .enemyDefeat, .battleAttack, .battleCounterattack, .battleEscape:
            return "wav"
        }
    }

    var fileName: String { "\(name).\(fileExtension)" }
}

/// ゲーム音声の端末設定と再生失敗の記録をまとめる。
enum AudioPlayback {
    /// 通常のゲーム内BGMと効果音の音量。
    static let backgroundMusicVolume: Float = 0.5
    static let soundEffectVolume: Float = 0.5
    /// 戦闘BGM専用の音量。
    static let encounterMusicVolume: Float = 0.3

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "DungeonGame",
        category: "Audio"
    )

    /// 消音スイッチや画面ロックに従うゲーム向け音声カテゴリを設定する。
    static func configureForDeviceSettings() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.soloAmbient)
        } catch {
            logger.error("音声セッションの設定に失敗しました: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// 対応表から音源を読み込み、再生準備に失敗した場合は記録する。
    static func makePlayer(for resource: AudioResource) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resource.name, withExtension: resource.fileExtension) else {
            logger.error("音源ファイルが見つかりません: \(resource.fileName, privacy: .public)")
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = soundEffectVolume
            guard player.prepareToPlay() else {
                logger.error("音源の再生準備に失敗しました: \(resource.fileName, privacy: .public)")
                return nil
            }
            return player
        } catch {
            logger.error("音源の読み込みに失敗しました: \(resource.fileName, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// 再生開始に失敗した場合は記録する。
    @discardableResult
    static func play(_ player: AVAudioPlayer, for resource: AudioResource) -> Bool {
        guard player.play() else {
            logger.error("音源の再生開始に失敗しました: \(resource.fileName, privacy: .public)")
            return false
        }
        return true
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

    func play(_ resource: AudioResource) {
        let player: AVAudioPlayer
        if let retainedPlayer = players[resource] {
            retainedPlayer.stop()
            retainedPlayer.currentTime = 0
            player = retainedPlayer
        } else {
            guard let newPlayer = AudioPlayback.makePlayer(for: resource) else { return }
            let delegate = AudioPlaybackErrorDelegate(resource: resource)
            newPlayer.volume = AudioPlayback.soundEffectVolume
            newPlayer.delegate = delegate
            players[resource] = newPlayer
            delegates[resource] = delegate
            player = newPlayer
        }
        AudioPlayback.play(player, for: resource)
    }
}
