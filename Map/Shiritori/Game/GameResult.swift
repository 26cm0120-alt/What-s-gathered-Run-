//
//  GameResult.swift
//  shiritori
//
//  Phase 14：勝敗判定
//

// 勝敗の結果を表す
enum GameResult {
    // プレイヤー勝利
    case playerWinAllCards
    case playerWinNoCPUTarget
    case playerWinCPUN
    // 時間切れでも残り枚数が少ない場合、CPUが健闘を認める特別勝利
    case playerWinTimeoutMercy

    // プレイヤー敗北
    case playerLoseTimeout
    case playerLoseN
}
