//
//  KanaNormalizer.swift
//  shiritori
//
//  Created by cmStudent on 2026/10/01.
//
// しりとり判定用のかな正規化を行う
struct KanaNormalizer {

    // しりとり判定用に読み方を正規化する
    static func normalize(_ word: String) -> String {
        var characters = Array(word)

        // 末尾の長音記号「ー」を無視し、直前の文字を末尾として扱う
        while characters.last == "ー" {
            characters.removeLast()
        }

        let replacements: [Character: Character] = [
            // 小さいかなを通常のかなへ変換
            "ぁ": "あ",
            "ぃ": "い",
            "ぅ": "う",
            "ぇ": "え",
            "ぉ": "お",
            "ゃ": "や",
            "ゅ": "ゆ",
            "ょ": "よ",
            "っ": "つ",

            // 濁音を清音へ変換
            "が": "か",
            "ぎ": "き",
            "ぐ": "く",
            "げ": "け",
            "ご": "こ",
            "ざ": "さ",
            "じ": "し",
            "ず": "す",
            "ぜ": "せ",
            "ぞ": "そ",
            "だ": "た",
            "ぢ": "ち",
            "づ": "つ",
            "で": "て",
            "ど": "と",

            // 濁音・半濁音を清音へ変換
            "ば": "は",
            "び": "ひ",
            "ぶ": "ふ",
            "べ": "へ",
            "ぼ": "ほ",
            "ぱ": "は",
            "ぴ": "ひ",
            "ぷ": "ふ",
            "ぺ": "へ",
            "ぽ": "ほ"
        ]

        // 1文字ずつ正規化する
        return String(
            characters.map { replacements[$0] ?? $0 }
        )
    }

    // 正規化した読み方の先頭文字を返す
    static func firstCharacter(of word: String) -> Character? {
        normalize(word).first
    }

    // 正規化した読み方の末尾文字を返す
    static func lastCharacter(of word: String) -> Character? {
        normalize(word).last
    }

    // 正規化した読み方が「ん」で終わるかを判定する
    static func endsWithN(_ word: String) -> Bool {
        lastCharacter(of: word) == "ん"
    }

    // 次の文字として表示する候補を返す
    // しりとりの判定では清音・濁音・半濁音を同じ行として扱うため、画面にもすべて表示する
    static func promptCharacters(for character: Character) -> [Character] {
        switch character {
        case "か": return ["か", "が"]
        case "き": return ["き", "ぎ"]
        case "く": return ["く", "ぐ"]
        case "け": return ["け", "げ"]
        case "こ": return ["こ", "ご"]

        case "さ": return ["さ", "ざ"]
        case "し": return ["し", "じ"]
        case "す": return ["す", "ず"]
        case "せ": return ["せ", "ぜ"]
        case "そ": return ["そ", "ぞ"]

        case "た": return ["た", "だ"]
        case "ち": return ["ち", "ぢ"]
        case "つ": return ["つ", "づ"]
        case "て": return ["て", "で"]
        case "と": return ["と", "ど"]

        case "は": return ["は", "ば", "ぱ"]
        case "ひ": return ["ひ", "び", "ぴ"]
        case "ふ": return ["ふ", "ぶ", "ぷ"]
        case "へ": return ["へ", "べ", "ぺ"]
        case "ほ": return ["ほ", "ぼ", "ぽ"]

        default: return [character]
        }
    }

    // 次の文字候補を画面表示用の文字列へ変換する
    static func promptDisplayText(for character: Character) -> String {
        promptCharacters(for: character)
            .map(String.init)
            .joined(separator: "　")
    }
}
