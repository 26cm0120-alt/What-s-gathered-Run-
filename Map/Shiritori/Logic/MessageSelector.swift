//
//  MessageSelector.swift
//  shiritori
//  
//  Phase 15：メッセージ・リアクション
//

import Foundation

// プレイヤー取得時・CPU取得時に表示するメッセージを選択する
struct MessageSelector {

    // プレイヤーがカードを取得したときのリアクション
    static func playerMessage(for vocabulary: Vocabulary) -> String {
        switch vocabulary.type {
        case .normal:
            return "ふむ、\(vocabulary.displayWord) か"

        case .english:
            return "ほほう、\(vocabulary.displayWord) か"

        case .surprise:
            return "むむむ！？ \(vocabulary.displayWord)・・・だと・・・？"

        case .rare:
            return "なんと、\(vocabulary.displayWord) と来たか。"
        }
    }

    // CPUがカードを取得したときのメッセージ候補
    static func cpuMessages(for vocabulary: Vocabulary) -> [String] {
        switch vocabulary.type {
        case .normal:
            return [
                "よし、\(vocabulary.displayWord) だ！",
                "まあ・・・ぶなんに \(vocabulary.displayWord) といこうか"
            ]

        case .english:
            return [
                "ふふふ・・・ \(vocabulary.displayWord) だ",
                "これならどうだ？ \(vocabulary.displayWord) だ！"
            ]

        case .surprise:
            return [
                "はっはっは、\(vocabulary.displayWord) という読み方もあるのだよ！"
            ]

        case .rare:
            return [
                "どうだ、\(vocabulary.displayWord) だ！参ったか！"
            ]
        }
    }

    // CPUメッセージを候補からランダムに1つ選ぶ
    static func randomCPUMessage(for vocabulary: Vocabulary) -> String {
        let messages = cpuMessages(for: vocabulary)
        return messages.randomElement() ?? ""
    }

    // CPUがカードを取得した後に、次に選べる文字を付けたメッセージを作成する
    static func cpuMessageWithNextPrompt(
        for vocabulary: Vocabulary,
        nextPrompt: Character?
    ) -> String {
        let baseMessage = randomCPUMessage(for: vocabulary)

        guard let nextPrompt else {
            return baseMessage
        }

        let promptText = KanaNormalizer.promptDisplayText(for: nextPrompt)
        return "\(baseMessage) 「\(promptText)」 から はじまるカードを選べ！"
    }
}
