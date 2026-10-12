# ダンジョンゲーム＋しりとりゲーム 統合版（実装成果物）

## 変更方針
- ダンジョンゲームのXcodeプロジェクトを土台にしています。
- アプリアイコンはダンジョンゲームの既存 `AppIcon` を使用します。
- 元ZIPは変更せず、統合用コピーにのみ変更を加えています。
- しりとり側の独立した `@main` とルート `ContentView` は統合ターゲットへ持ち込まず、ダンジョン側の起動入口を維持します。
- しりとりの `GameManager` / `GameState` / `StartView` は型名衝突を避けるため、統合コピー内で `ShiritoriGameManager` / `ShiritoriGameState` / `ShiritoriStartView` に変更しています。画面は `ShiritoriGameView` として呼び出します。
- しりとりのアセットは別の `ShiritoriAssets.xcassets` にまとめ、`AppIcon` と `AccentColor` の重複だけは取り込んでいません。ダンジョン側の既存アイコン・アクセントカラーを残しています。

## 統合フロー
1. ダンジョンの既存スタート画面からプレイ開始
2. 鍵を取得してゴールの扉を開く
3. 扉の既存音声が終了したら、しりとりの既存プロローグへ遷移
4. プロローグの `typingDuration = 15.0` と `transitionDelay = 2.0` は維持
5. しりとりの勝利後、最終メッセージ全文表示後に3秒待機し、ダンジョンの既存クリア画面へ遷移
6. しりとりの敗北後、敗北メッセージ全文表示と敗北BGM開始後に3秒待機し、ダンジョンのスタート画面へ戻る
7. 特殊エンディングは最後のメッセージまで順番に表示してから3秒待機する。最終セリフに既存の2秒保持を重ねないよう、最終セリフの保持は統合側の3秒待機に置き換えています。

## 主な変更ファイル
- `Map/Core/AppFlow.swift` — ダンジョンクリア後の遷移先と、しりとり結果後の遷移を追加
- `Map/UI/ContentView.swift` — しりとりプロローグ／ゲーム画面を表示する分岐を追加
- `Map/Shiritori/Views/ShiritoriStartView.swift` — プロローグ終了時に統合側へ通知する接続を追加。文言と表示時間は維持
- `Map/Shiritori/Views/GameView.swift` — 最終演出後の結果通知と3秒待機を追加
- `Map/Shiritori/Game/ShiritoriGameManager.swift`、`Map/Shiritori/Game/ShiritoriGameState.swift` およびしりとりソース内参照 — 型名衝突回避
- `Map/ShiritoriAssets.xcassets` — しりとりの既存画像・音声アセット

## 静的確認
- 統合コピー内のSwiftファイル48本を `swiftc -frontend -parse` で構文解析し、エラーなし。
- 統合ターゲット内のトップレベル型名重複を簡易スキャンし、重複なし。
- 2つのアセットカタログ間でアセット項目名の衝突なし。
- しりとり側の独立 `@main` ファイルは統合コピーへ含めていません。

## 未確認事項
- この作業環境に `xcodebuild` がないため、Xcodeの実ビルド、シミュレーター起動、実機動作、音声の実再生は未確認です。
- したがって、現時点では「ビルド成功」「動作確認済み」とは報告しません。Xcodeで開いて、ビルドと統合フローの実機／シミュレーター検証が必要です。


## ビルドエラー修正（2026-10-12）
- Xcode の `Multiple commands produce ... GameManager.stringsdata / GameState.stringsdata / StartView.stringsdata` を避けるため、しりとり側の3ファイルのファイル名を `ShiritoriGameManager.swift`、`ShiritoriGameState.swift`、`ShiritoriStartView.swift` に変更しました。型名の変更に加え、ファイル名も区別します。
- この修正はソース内容の追加変更ではなく、統合ターゲット内の生成物名の衝突回避を目的としています。Xcode 実ビルドはこの環境では実行できないため、修正後のビルド結果は未確認です。
