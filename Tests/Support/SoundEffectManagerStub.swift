import Foundation

/// しりとり側のロジックテスト用。端末の音声・触覚出力だけを省略する。
/// 呼び出しの有無は検証せず、状態遷移と判定結果を実コードで確かめる。
final class SoundEffectManager {
    static let shared = SoundEffectManager()

    func playCardSelectionHaptic() {}
    func playCursor() {}
    func playSuccess() {}
    func playFailure() {}
    func startBGM() {}
    func stopBGM() {}
    func switchToBGM2Permanently(fadeOutDuration: TimeInterval = 3.0) {}
}
