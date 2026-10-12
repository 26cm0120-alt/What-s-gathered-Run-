import SwiftUI

/// ギブアップの確認表示(仕様書§13.4、UI仕様書§15)。プレイ画面の上に重ねて表示する
struct GiveUpConfirmView: View {
    /// 「はい」が押されたときの処理(プレイを終了して、スタート画面へ戻る)
    let onYes: () -> Void
    /// 「いいえ」が押されたときの処理(確認を閉じて、プレイ画面に戻る)
    let onNo: () -> Void

    var body: some View {
        ZStack {
            // 表示中は他の操作を受け付けないように、画面全体を覆う
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("ギブアップしますか？")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    choiceButton("はい", onYes)
                    choiceButton("いいえ", onNo)
                }
                .frame(maxWidth: 320)
            }
            .padding()
        }
    }

    /// 「はい」「いいえ」のボタン(コマンドボタンと同じ様式)
    private func choiceButton(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(DungeonPressButtonStyle())
    }
}
