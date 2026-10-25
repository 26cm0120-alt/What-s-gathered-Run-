import Foundation

/// BGMと効果音の音量設定。設定画面のスライダーで変更し、UserDefaultsへ保存する。
enum AudioVolumeSettings {
    /// 未設定時の音量(従来の固定値と同じ)。
    static let defaultVolume: Float = 0.5
    /// 戦闘BGMはBGM音量に対する比率で決める(初期値0.5のとき従来の0.3)。
    static let encounterMusicRatio: Float = 0.6

    static let backgroundMusicKey = "audio.backgroundMusicVolume"
    static let soundEffectKey = "audio.soundEffectVolume"

    /// 音量を0〜1に収める。数値でない値は初期値に戻す。
    static func clamped(_ volume: Float) -> Float {
        guard volume.isFinite else { return defaultVolume }
        return min(max(volume, 0), 1)
    }

    static func load(forKey key: String, defaults: UserDefaults = .standard) -> Float {
        guard defaults.object(forKey: key) != nil else { return defaultVolume }
        return clamped(defaults.float(forKey: key))
    }

    static func save(_ volume: Float, forKey key: String, defaults: UserDefaults = .standard) {
        defaults.set(clamped(volume), forKey: key)
    }

    static var backgroundMusic: Float { load(forKey: backgroundMusicKey) }
    static var soundEffect: Float { load(forKey: soundEffectKey) }
    static var encounterMusic: Float { clamped(backgroundMusic * encounterMusicRatio) }
}
