import SwiftUI
import UIKit

/// iPad(縦向き固定・11インチ想定)の画面枠に使う寸法の定義。
///
/// iPadでは、画面全体をそのまま使える横長すぎない「仮想キャンバス」(幅700pt・高さ1000pt以上)に
/// 各画面を描き、画面の幅と高さに合わせて等倍率で拡大する。11インチ(834×1194pt)では約1.19倍で、
/// 左右に余白を作らず画面いっぱいに表示する。各画面はこのキャンバスの大きさに合わせて、
/// `IPadLayoutMetrics.isPad` のときだけiPad向けの配置に切り替える。
enum IPadLayoutMetrics {
    /// 仮想キャンバスの基準の幅(pt)
    static let designWidth: CGFloat = 700
    /// 仮想キャンバスの基準の高さ(pt)
    static let designHeight: CGFloat = 1000

    /// 画面サイズに対する拡大倍率。幅・高さのどちらか厳しい方に合わせる。
    static func scale(for size: CGSize) -> CGFloat {
        guard size.width > 0, size.height > 0 else { return 1 }
        return max(0.1, min(size.width / designWidth, size.height / designHeight))
    }

    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    // MARK: - 画面ごとのiPad向け寸法

    /// タイトル画面の中身の最大幅
    static var startContentWidth: CGFloat { isPad ? 520 : 360 }
    /// 探索・戦闘画面で、ダンジョン画面の下に3列(キャラクター・状況とHP・マップ)を並べる段の高さ
    static let infoPanelHeight: CGFloat = 290
    /// 3列のうち、左のキャラクター列の幅
    static let characterColumnWidth: CGFloat = 180
    /// 3列のうち、右のマップ列の幅
    static let mapColumnWidth: CGFloat = 190
    /// 中央列の上に置く、ステージ名の欄の高さ(右列の鍵の欄も同じ高さ)
    static let stageTitleHeight: CGFloat = 40
    /// 中央列の下に置く、フリック案内の欄の高さ
    static let flickPanelHeight: CGFloat = 84
    /// 3列の下に置く、タイマー・ギブアップの段の高さ
    static let footerRowHeight: CGFloat = 48
    /// ステータス欄・余白など、ダンジョン画面以外の縦方向の合計(ダンジョン画面を正方形に収めるために使う)
    static var playViewNonDungeonHeight: CGFloat {
        infoPanelHeight + footerRowHeight + 8 * 2 + 16 + 12
    }
}

/// 画面全体を、端末に合わせた枠で包む。
/// - iPhone: 何も変えず、そのまま表示する。
/// - iPad: 仮想キャンバスに描いて等倍率で拡大し、画面いっぱいに表示する。
struct DeviceAdaptiveContainer<Content: View>: View {
    private let content: () -> Content

    /// ソフトウェアキーボードの最終フレーム(画面座標)
    @State private var keyboardFrame: CGRect = .zero

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        if IPadLayoutMetrics.isPad {
            iPadBody
        } else {
            content()
        }
    }

    private var iPadBody: some View {
        GeometryReader { geometry in
            let scale = IPadLayoutMetrics.scale(for: geometry.size)
            // 拡大後に画面ぴったりになるよう、キャンバスの幅と高さは画面サイズ÷倍率で決める。
            let canvasWidth = geometry.size.width / scale
            let canvasHeight = geometry.size.height / scale
            let keyboardOverlap = keyboardOverlapHeight(screenHeight: geometry.size.height)
            // ステータスバー・ホームインジケータ分の余白(OS側の回避は全体で止めているため、ここで渡す)。
            let topInset = geometry.safeAreaInsets.top / scale
            let bottomInset = max(geometry.safeAreaInsets.bottom, keyboardOverlap) / scale

            ZStack {
                DungeonBackground()

                content()
                    // 各画面から見たセーフエリア。背景はこの外側まで広がり、文字や操作部は内側に収まる。
                    .safeAreaInset(edge: .top, spacing: 0) {
                        Color.clear.frame(height: topInset)
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        Color.clear.frame(height: bottomInset)
                    }
                    .frame(width: canvasWidth, height: canvasHeight)
                    .clipped()
                    .scaleEffect(scale)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .animation(.easeOut(duration: 0.25), value: keyboardOverlap)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        // キーボードでキャンバスの拡大率が変わらないよう、画面サイズは常に全体で測る。
        .ignoresSafeArea(.all)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            keyboardFrame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardFrame = .zero
        }
    }

    /// 画面の下端に固定されたキーボードが画面に重なっている高さ。
    /// フローティングキーボードや非表示のときは0を返す。
    private func keyboardOverlapHeight(screenHeight: CGFloat) -> CGFloat {
        guard keyboardFrame.height > 0, keyboardFrame.maxY >= screenHeight - 1 else { return 0 }
        return max(0, screenHeight - keyboardFrame.minY)
    }
}
