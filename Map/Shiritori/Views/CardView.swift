//
//  CardView.swift
//  shiritori
//
//  Created by cmStudent on 2026/10/01.
//

import SwiftUI

// 1枚のカード表示を担当する
struct CardView: View {

    // 表示するカード
    let card: Card

    // 現在選択されているカードかどうか
    let isSelected: Bool

    // CPUが現在スキャンしているカードかどうか
    let isCPUScanning: Bool

    // カードがタップされたときに呼び出す処理
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 取得済みカードは完全に黒表示する
                if card.isCleared {
                    Color.black
                } else {
                    // カード画像を表示する
                    Image(card.imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(4)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .background(Color.black)
            .overlay(
                Rectangle()
                    .stroke(
                        (isSelected || isCPUScanning) ? Color.orange : Color.white,
                        lineWidth: (isSelected || isCPUScanning) ? 4 : 2
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(card.isCleared)
    }
}
