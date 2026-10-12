//
//  VocabularySelector.swift
//  shiritori
//
//  Created by cmStudent on 2026/10/01.
//

// プレイヤーが使用する読み方を自動決定する
struct VocabularySelector {

    // プレイヤーの読み方を自動決定する
    static func select(
        from vocabularies: [Vocabulary],
        currentPrompt: Character
    ) -> Vocabulary? {

        guard !vocabularies.isEmpty else {
            return nil
        }

        // 現在の要求文字に接続できる読みだけを優先対象にする
        let connectableVocabularies = vocabularies.filter { vocabulary in
            KanaNormalizer.firstCharacter(of: vocabulary.word) == currentPrompt
        }

        // 接続可能な読みがある場合は、その中から選択する
        // 接続可能な読みがない場合は、カード内の全読みから選択する
        let candidates = connectableVocabularies.isEmpty
            ? vocabularies
            : connectableVocabularies

        // 「ん」で終わらない読みを優先する
        let nonNEndingVocabularies = candidates.filter { vocabulary in
            !KanaNormalizer.endsWithN(vocabulary.word)
        }

        // 「ん」で終わらない読みがある場合は、その中から選択する
        // すべて「ん」で終わる場合は、その中から選択して敗北判定へ渡す
        let prioritizedCandidates = nonNEndingVocabularies.isEmpty
            ? candidates
            : nonNEndingVocabularies

        // 読みの種類の優先順位を適用する
        let priorities: [WordType] = [
            .rare,
            .surprise,
            .english,
            .normal
        ]

        // first(where:)を使い、同じ種類なら登録順をそのまま維持する
        for type in priorities {
            if let vocabulary = first(of: type, in: prioritizedCandidates) {
                return vocabulary
            }
        }

        // 念のため、優先順位に該当しない読みがある場合は登録順の先頭を返す
        return prioritizedCandidates.first
    }

    // 指定した種類の読みを登録順で最初に取得する
    private static func first(
        of type: WordType,
        in vocabularies: [Vocabulary]
    ) -> Vocabulary? {
        vocabularies.first { vocabulary in
            switch (vocabulary.type, type) {
            case (.rare, .rare),
                 (.surprise, .surprise),
                 (.english, .english),
                 (.normal, .normal):
                return true
            default:
                return false
            }
        }
    }
}
