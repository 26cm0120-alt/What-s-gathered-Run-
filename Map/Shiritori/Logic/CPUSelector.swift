//
//  CPUSelector.swift
//  shiritori
//
//  Created by cmStudent on 2026/10/02.
//

// CPUが選択するCardとVocabularyを自動決定する
struct CPUSelector {

    // CPUが選択するCardとVocabularyを決定する
    // 戻り値がnilの場合は、現在の要求文字に接続可能なカードが存在しない
    static func select(
        from cards: [Card],
        currentPrompt: Character
    ) -> (card: Card, vocabulary: Vocabulary)? {

        // 取得済みカードを除外し、未取得カードだけを候補にする
        let availableCards = cards.filter { !$0.isCleared }

        // 現在の要求文字に接続可能なVocabularyだけを集める
        let connectableCandidates: [(card: Card, vocabulary: Vocabulary)] =
            availableCards.flatMap { card in
                card.vocabularies.compactMap { vocabulary in
                    guard KanaNormalizer.firstCharacter(of: vocabulary.word) == currentPrompt else {
                        return nil
                    }

                    return (card: card, vocabulary: vocabulary)
                }
            }

        // 接続可能なカードがない場合は、CPUスキャンを行わず即勝利へ渡す
        guard !connectableCandidates.isEmpty else {
            return nil
        }

        // 「ん」で終わらない読みを優先する
        let nonNEndingCandidates = connectableCandidates.filter { candidate in
            !KanaNormalizer.endsWithN(candidate.vocabulary.word)
        }

        let prioritizedCandidates = nonNEndingCandidates.isEmpty
            ? connectableCandidates
            : nonNEndingCandidates

        // CPUの読み方の優先順位
        let priorities: [WordType] = [
            .normal,
            .english,
            .surprise,
            .rare
        ]

        // first(where:)を使い、同じ種類ならカード・読みの登録順を維持する
        for type in priorities {
            if let candidate = prioritizedCandidates.first(where: {
                $0.vocabulary.type == type
            }) {
                return candidate
            }
        }

        // 念のため、優先順位に該当しない読みがある場合は登録順の先頭を返す
        return prioritizedCandidates.first
    }
}
