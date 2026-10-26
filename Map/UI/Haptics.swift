import CoreHaptics
import UIKit

/// 振動(触覚フィードバック)の出口。設定でオフのとき、または端末が振動に対応していないときは何もしない。
///
/// iPadにはTaptic Engineがないため、`isSupported` はfalseになり、どの呼び出しも何も起こさない。
/// 振動を鳴らす処理は、直接 `UIImpactFeedbackGenerator` などを呼ばず、必ずここを通す。
enum Haptics {
    /// この端末が振動に対応しているか(iPhoneはtrue、iPadとSimulatorはfalse)。
    static var isSupported: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    /// 設定がオンで、かつ端末が対応している。
    private static var isActive: Bool {
        HapticsSettings.isEnabled() && isSupported
    }

    /// 衝撃(移動・壁への衝突・攻撃など)
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1.0) {
        guard isActive else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred(intensity: intensity)
    }

    /// 通知(敵との遭遇などの警告)
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isActive else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    /// 選択(しりとりでカードを選んだ時)
    static func selection() {
        guard isActive else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    /// 設定画面でスイッチをオンにした時に、振動の強さを確かめるための試し振動。
    static func preview() {
        impact(.medium, intensity: 0.8)
    }
}
