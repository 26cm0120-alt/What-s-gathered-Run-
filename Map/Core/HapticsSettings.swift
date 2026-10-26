import Foundation

/// 振動(触覚フィードバック)の設定。設定画面のスイッチで変更し、UserDefaultsへ保存する。
enum HapticsSettings {
    /// 未設定時は、従来どおり振動させる。
    static let defaultEnabled = true

    static let enabledKey = "haptics.enabled"

    static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        guard defaults.object(forKey: enabledKey) != nil else { return defaultEnabled }
        return defaults.bool(forKey: enabledKey)
    }

    static func setEnabled(_ isEnabled: Bool, defaults: UserDefaults = .standard) {
        defaults.set(isEnabled, forKey: enabledKey)
    }
}
