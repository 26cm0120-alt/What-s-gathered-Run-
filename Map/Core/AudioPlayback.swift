import AVFoundation
import Foundation
import OSLog

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

    /// バンドルから音源を読み込み、再生準備に失敗した場合は記録する。
    static func makePlayer(named resourceName: String, withExtension fileExtension: String = "mp3") -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: fileExtension) else {
            logger.error("音源ファイルが見つかりません: \(resourceName, privacy: .public).\(fileExtension, privacy: .public)")
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = soundEffectVolume
            guard player.prepareToPlay() else {
                logger.error("音源の再生準備に失敗しました: \(resourceName, privacy: .public).\(fileExtension, privacy: .public)")
                return nil
            }
            return player
        } catch {
            logger.error("音源の読み込みに失敗しました: \(resourceName, privacy: .public).\(fileExtension, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// 再生開始に失敗した場合は記録する。
    @discardableResult
    static func play(_ player: AVAudioPlayer, named resourceName: String, withExtension fileExtension: String = "mp3") -> Bool {
        guard player.play() else {
            logger.error("音源の再生開始に失敗しました: \(resourceName, privacy: .public).\(fileExtension, privacy: .public)")
            return false
        }
        return true
    }

    /// 再生中のデコードエラーを記録する。
    static func logDecodeError(for resourceName: String, withExtension fileExtension: String = "mp3", error: Error?) {
        if let error {
            logger.error("音源のデコードに失敗しました: \(resourceName, privacy: .public).\(fileExtension, privacy: .public): \(error.localizedDescription, privacy: .public)")
        } else {
            logger.error("音源のデコードに失敗しました: \(resourceName, privacy: .public).\(fileExtension, privacy: .public)")
        }
    }
}

/// AVAudioPlayerのデコードエラーを記録する。呼び出し側でプレイヤーと一緒に保持する。
final class AudioPlaybackErrorDelegate: NSObject, AVAudioPlayerDelegate {
    private let resourceName: String
    private let fileExtension: String

    init(resourceName: String, fileExtension: String = "mp3") {
        self.resourceName = resourceName
        self.fileExtension = fileExtension
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        AudioPlayback.logDecodeError(for: resourceName, withExtension: fileExtension, error: error)
    }
}

/// 効果音プレイヤーを保持し、同じ音が連続したら先頭から再生し直す。
final class SoundEffectController {
    private var players: [String: AVAudioPlayer] = [:]
    private var delegates: [String: AudioPlaybackErrorDelegate] = [:]

    func play(named resourceName: String) {
        let player: AVAudioPlayer
        if let retainedPlayer = players[resourceName] {
            retainedPlayer.stop()
            retainedPlayer.currentTime = 0
            player = retainedPlayer
        } else {
            guard let newPlayer = AudioPlayback.makePlayer(named: resourceName, withExtension: "wav") else { return }
            let delegate = AudioPlaybackErrorDelegate(resourceName: resourceName, fileExtension: "wav")
            newPlayer.volume = AudioPlayback.soundEffectVolume
            newPlayer.delegate = delegate
            players[resourceName] = newPlayer
            delegates[resourceName] = delegate
            player = newPlayer
        }
        AudioPlayback.play(player, named: resourceName, withExtension: "wav")
    }
}
