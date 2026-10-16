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

    var body: some View {
        VStack(spacing: 4) {

            // PLAYER用の表示領域
            Text("PLAYER")
                .font(DungeonTypography.maruMonica(size: 12))
                .foregroundStyle(.white)
                .frame(height: 36)

            // PLAYER TIMEを表示する
            HStack {
                Text("PLAYER TIME")

                Spacer()

                Text("\(playerTime)")
            }
            .font(DungeonTypography.maruMonica(size: 16))
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
