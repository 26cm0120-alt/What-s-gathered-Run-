//
//  HeaderView.swift
//  shiritori
//
//  Phase16：画面上部の情報表示
//

import SwiftUI

// 残り枚数と次の要求文字を表示する
struct HeaderView: View {

    // まだ取得されていないカードの枚数
    let remainingCardCount: Int

    // 次に必要な文字
    let currentPrompt: Character?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("残り枚数")
                Text("\(remainingCardCount)枚")
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("次の文字")
                Text(nextPromptText)
            }
        }
        .font(DungeonTypography.maruMonica(size: 13))
        .foregroundStyle(.white)
    }

    // 現在の要求文字から、接続可能な清音・濁音・半濁音を表示する
    private var nextPromptText: String {
        guard let currentPrompt else {
            return "-"
        }

        return KanaNormalizer.promptDisplayText(for: currentPrompt)
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        HeaderView(
            remainingCardCount: 25,
            currentPrompt: "は"
        )
        .padding()
    }
}
