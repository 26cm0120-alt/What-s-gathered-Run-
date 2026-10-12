import AVFoundation
import Foundation
import OSLog

/// ゲーム音声の端末設定と再生失敗の記録をまとめる。
enum AudioPlayback {
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
    static func makePlayer(named resourceName: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "mp3") else {
            logger.error("音源ファイルが見つかりません: \(resourceName, privacy: .public).mp3")
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            guard player.prepareToPlay() else {
                logger.error("音源の再生準備に失敗しました: \(resourceName, privacy: .public).mp3")
                return nil
            }
            return player
        } catch {
            logger.error("音源の読み込みに失敗しました: \(resourceName, privacy: .public).mp3: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// 再生開始に失敗した場合は記録する。
    @discardableResult
    static func play(_ player: AVAudioPlayer, named resourceName: String) -> Bool {
        guard player.play() else {
            logger.error("音源の再生開始に失敗しました: \(resourceName, privacy: .public).mp3")
            return false
        }
        return true
    }

    /// 再生中のデコードエラーを記録する。
    static func logDecodeError(for resourceName: String, error: Error?) {
        if let error {
            logger.error("音源のデコードに失敗しました: \(resourceName, privacy: .public).mp3: \(error.localizedDescription, privacy: .public)")
        } else {
            logger.error("音源のデコードに失敗しました: \(resourceName, privacy: .public).mp3")
        }
    }
}

/// AVAudioPlayerのデコードエラーを記録する。呼び出し側でプレイヤーと一緒に保持する。
final class AudioPlaybackErrorDelegate: NSObject, AVAudioPlayerDelegate {
    private let resourceName: String

    init(resourceName: String) {
        self.resourceName = resourceName
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        AudioPlayback.logDecodeError(for: resourceName, error: error)
    }
}
