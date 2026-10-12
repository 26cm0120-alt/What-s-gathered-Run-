//
//  CardBoardView.swift
//  shiritori
//
//  Created by cmStudent on 2026/10/01.
//

import SwiftUI

// 25枚のカードを5×5で配置する
struct CardBoardView: View {

    // ゲーム盤面のカード
    let cards: [Card]

    // 現在選択されているカードのID
    let selectedCardID: UUID?

    // CPUが現在スキャンしているカードの番号
    // nilの場合はCPUスキャン中ではない
    let cpuScanIndex: Int?

    // カードがタップされたときに呼び出す処理
    let onCardTap: (UUID) -> Void

    // 5列を均等に配置する
    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 4),
        count: 5
    )

    var body: some View {
        LazyVGrid(
            columns: columns,
            spacing: 4
        ) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                CardView(
                    card: card,
                    isSelected: selectedCardID == card.id,
                    isCPUScanning: isCPUScanning(at: index),
                    onTap: {
                        onCardTap(card.id)
                    }
                )
            }
        }
        .padding(4)
    }

    // 現在のカードがCPUスキャン位置にあるか判定する
    private func isCPUScanning(at index: Int) -> Bool {
        return cpuScanIndex == index
    }
}
