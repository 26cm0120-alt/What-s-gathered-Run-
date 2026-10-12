//
//  CPUScanState.swift
//  shiritori
//
//  Created by cmStudent on 2026/10/02.
//

// CPUスキャン演出の状態を表す
struct CPUScanState {

    // CPUスキャン中かどうか
    let isScanning: Bool

    // 現在スキャンしているカードの盤面上の位置
    // 0〜24を使用し、左上から右下の行優先で管理する
    let currentIndex: Int?

    // CPUスキャン開始時の初期状態
    static let idle = CPUScanState(
        isScanning: false,
        currentIndex: nil
    )

    // 指定したマスをスキャン中の状態を作る
    static func scanning(index: Int) -> CPUScanState {
        CPUScanState(
            isScanning: true,
            currentIndex: index
        )
    }
}
