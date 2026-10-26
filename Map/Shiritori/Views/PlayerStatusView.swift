//
//  PlayerStatusView.swift
//  shiritori
//
//  Phase16：画面下部のPLAYER情報表示
//

import SwiftUI

// PLAYERとPLAYER TIMEを表示する
struct PlayerStatusView: View {

    // PLAYER TIMEの残り秒数
    let playerTime: Int

    // 文字の倍率(iPadで大きく表示するときに使う)
    var fontScale: CGFloat = 1

    // trueのとき、PLAYER TIMEと残り秒数を離さず、中央に並べて表示する(iPad用)
    var groupsTimeTogether: Bool = false

    var body: some View {
        VStack(spacing: 4) {

            // PLAYER用の表示領域
            Text("PLAYER")
                .font(DungeonTypography.maruMonica(size: 12 * fontScale))
                .foregroundStyle(.white)
                .frame(height: groupsTimeTogether ? 28 : 36 * fontScale)

            // PLAYER TIMEを表示する
            HStack(spacing: groupsTimeTogether ? 16 : 8) {
                Text("PLAYER TIME")

                if !groupsTimeTogether {
                    Spacer()
                }

                Text("\(playerTime)")
            }
            .font(DungeonTypography.maruMonica(size: 16 * fontScale))
            .foregroundStyle(.white)
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        PlayerStatusView(playerTime: 30)
            .padding()
    }
}
