//
//  CardData2.swift
//  試練ステージ専用カードデータ候補
//
// 注意：候補ファイル。XcodeのBuild・Simulator確認前に正式採用しない。

import Foundation

struct CardData2 {
    static let cards: [Card] = [
        Card(id: UUID(), imageName: "card2_01", vocabularies: [
            Vocabulary(word: "しょくぱん", displayWord: "しょくぱん", type: .normal),
            Vocabulary(word: "とーすと", displayWord: "とーすと", type: .english),
            Vocabulary(word: "ばたー", displayWord: "ばたー", type: .rare),
            Vocabulary(word: "やきたて", displayWord: "やきたて", type: .rare),
            Vocabulary(word: "ぶれっど", displayWord: "ぶれっど", type: .rare),
            Vocabulary(word: "きつねいろ", displayWord: "きつねいろ", type: .surprise),
            Vocabulary(word: "こんがり", displayWord: "こんがり", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_02", vocabularies: [
            Vocabulary(word: "やさい", displayWord: "やさい", type: .normal),
            Vocabulary(word: "とまと", displayWord: "とまと", type: .english),
            Vocabulary(word: "なつやさい", displayWord: "なつやさい", type: .rare),
            Vocabulary(word: "りこぴん", displayWord: "りこぴん", type: .rare),
            Vocabulary(word: "みにとまと", displayWord: "みにとまと", type: .surprise),
            Vocabulary(word: "あかなす", displayWord: "あかなす", type: .surprise),
            Vocabulary(word: "ぽもどーろ", displayWord: "ぽもどーろ", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_03", vocabularies: [
            Vocabulary(word: "くるま", displayWord: "くるま", type: .normal),
            Vocabulary(word: "とらくたー", displayWord: "とらくたー", type: .english),
            Vocabulary(word: "じゅうき", displayWord: "じゅうき", type: .rare),
            Vocabulary(word: "こううんき", displayWord: "こううんき", type: .rare),
            Vocabulary(word: "のりもの", displayWord: "のりもの", type: .surprise),
            Vocabulary(word: "さぎょうしゃ", displayWord: "さぎょうしゃ", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_04", vocabularies: [
            Vocabulary(word: "ぬの", displayWord: "ぬの", type: .normal),
            Vocabulary(word: "たおる", displayWord: "たおる", type: .english),
            Vocabulary(word: "てぬぐい", displayWord: "てぬぐい", type: .rare),
            Vocabulary(word: "ふぇいすたおる", displayWord: "ふぇいすたおる", type: .rare),
            Vocabulary(word: "ばすたおる", displayWord: "ばすたおる", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_05", vocabularies: [
            Vocabulary(word: "ほうせき", displayWord: "ほうせき", type: .normal),
            Vocabulary(word: "るびー", displayWord: "るびー", type: .english),
            Vocabulary(word: "こうぎょく", displayWord: "こうぎょく", type: .rare),
            Vocabulary(word: "ぴじょんぶらっど", displayWord: "ぴじょんぶらっど", type: .rare),
            Vocabulary(word: "たからもの", displayWord: "たからもの", type: .surprise),
            Vocabulary(word: "きらきら", displayWord: "きらきら", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_06", vocabularies: [
            Vocabulary(word: "おかし", displayWord: "おかし", type: .normal),
            Vocabulary(word: "びすけっと", displayWord: "びすけっと", type: .english),
            Vocabulary(word: "やきがし", displayWord: "やきがし", type: .rare),
            Vocabulary(word: "がれっと", displayWord: "がれっと", type: .rare),
            Vocabulary(word: "くっきー", displayWord: "くっきー", type: .surprise),
            Vocabulary(word: "さぶれ", displayWord: "さぶれ", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_07", vocabularies: [
            Vocabulary(word: "くるま", displayWord: "くるま", type: .normal),
            Vocabulary(word: "とらっく", displayWord: "とらっく", type: .english),
            Vocabulary(word: "かもつしゃ", displayWord: "かもつしゃ", type: .rare),
            Vocabulary(word: "うんそうしゃ", displayWord: "うんそうしゃ", type: .rare),
            Vocabulary(word: "のりもの", displayWord: "のりもの", type: .surprise),
            Vocabulary(word: "おおがたしゃ", displayWord: "おおがたしゃ", type: .surprise),
            Vocabulary(word: "はいたつしゃ", displayWord: "はいたつしゃ", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_08", vocabularies: [
            Vocabulary(word: "おいわい", displayWord: "おいわい", type: .normal),
            Vocabulary(word: "くらっかー", displayWord: "くらっかー", type: .english),
            Vocabulary(word: "ぱーてぃくらっかー", displayWord: "ぱーてぃくらっかー", type: .rare),
            Vocabulary(word: "いべんとくらっかー", displayWord: "いべんとくらっかー", type: .rare),
            Vocabulary(word: "しゅくふく", displayWord: "しゅくふく", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_09", vocabularies: [
            Vocabulary(word: "しゃしんき", displayWord: "しゃしんき", type: .normal),
            Vocabulary(word: "かめら", displayWord: "かめら", type: .english),
            Vocabulary(word: "さつえいき", displayWord: "さつえいき", type: .rare),
            Vocabulary(word: "いちがんれふ", displayWord: "いちがんれふ", type: .rare),
            Vocabulary(word: "でじかめ", displayWord: "でじかめ", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_10", vocabularies: [
            Vocabulary(word: "あかり", displayWord: "あかり", type: .normal),
            Vocabulary(word: "らいと", displayWord: "らいと", type: .english),
            Vocabulary(word: "しょうめい", displayWord: "しょうめい", type: .rare),
            Vocabulary(word: "とうこうき", displayWord: "とうこうき", type: .rare),
            Vocabulary(word: "でんとう", displayWord: "でんとう", type: .surprise),
            Vocabulary(word: "すぽっとらいと", displayWord: "すぽっとらいと", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_11", vocabularies: [
            Vocabulary(word: "こうどう", displayWord: "こうどう", type: .normal),
            Vocabulary(word: "とんねる", displayWord: "とんねる", type: .english),
            Vocabulary(word: "てつどうとんねる", displayWord: "てつどうとんねる", type: .rare),
            Vocabulary(word: "れーる", displayWord: "れーる", type: .rare),
            Vocabulary(word: "せんろ", displayWord: "せんろ", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_12", vocabularies: [
            Vocabulary(word: "むしめがね", displayWord: "むしめがね", type: .normal),
            Vocabulary(word: "るーぺ", displayWord: "るーぺ", type: .english),
            Vocabulary(word: "かくだいきょう", displayWord: "かくだいきょう", type: .rare),
            Vocabulary(word: "はんどるーぺ", displayWord: "はんどるーぺ", type: .rare),
            Vocabulary(word: "とつれんず", displayWord: "とつれんず", type: .surprise),
            Vocabulary(word: "てもちるーぺ", displayWord: "てもちるーぺ", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_13", vocabularies: [
            Vocabulary(word: "ふらっとぺだる", displayWord: "ふらっとぺだる", type: .normal),
            Vocabulary(word: "ぺだる", displayWord: "ぺだる", type: .english),
            Vocabulary(word: "とうめん", displayWord: "とうめん", type: .rare),
            Vocabulary(word: "あしかけ", displayWord: "あしかけ", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_14", vocabularies: [
            Vocabulary(word: "くちべに", displayWord: "くちべに", type: .normal),
            Vocabulary(word: "るーじゅ", displayWord: "るーじゅ", type: .english),
            Vocabulary(word: "りっぷぐろす", displayWord: "りっぷぐろす", type: .rare),
            Vocabulary(word: "けしょうひん", displayWord: "けしょうひん", type: .rare),
            Vocabulary(word: "べに", displayWord: "べに", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_15", vocabularies: [
            Vocabulary(word: "みかくにんひこうぶったい", displayWord: "みかくにんひこうぶったい", type: .normal),
            Vocabulary(word: "ゆーふぉー", displayWord: "ゆーふぉー", type: .english),
            Vocabulary(word: "あぶだくしょん", displayWord: "あぶだくしょん", type: .rare),
            Vocabulary(word: "うちゅうせん", displayWord: "うちゅうせん", type: .rare),
            Vocabulary(word: "ぷらもでる", displayWord: "ぷらもでる", type: .surprise),
            Vocabulary(word: "そらとぶえんばん", displayWord: "そらとぶえんばん", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_16", vocabularies: [
            Vocabulary(word: "くだもの", displayWord: "くだもの", type: .normal),
            Vocabulary(word: "おれんじ", displayWord: "おれんじ", type: .english),
            Vocabulary(word: "かんきつるい", displayWord: "かんきつるい", type: .rare),
            Vocabulary(word: "だいだい", displayWord: "だいだい", type: .rare),
            Vocabulary(word: "ねーぶる", displayWord: "ねーぶる", type: .rare),
            Vocabulary(word: "ぶらっどおれんじ", displayWord: "ぶらっどおれんじ", type: .rare),
            Vocabulary(word: "みかん", displayWord: "みかん", type: .surprise),
            Vocabulary(word: "きのみ", displayWord: "きのみ", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_17", vocabularies: [
            Vocabulary(word: "すてっかー", displayWord: "すてっかー", type: .normal),
            Vocabulary(word: "しーる", displayWord: "しーる", type: .english),
            Vocabulary(word: "だくとてーぷ", displayWord: "だくとてーぷ", type: .rare),
            Vocabulary(word: "びにーるてーぷ", displayWord: "びにーるてーぷ", type: .rare),
            Vocabulary(word: "らべる", displayWord: "らべる", type: .rare),
            Vocabulary(word: "てーぷ", displayWord: "てーぷ", type: .rare),
            Vocabulary(word: "がむてーぷ", displayWord: "がむてーぷ", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_18", vocabularies: [
            Vocabulary(word: "かいてんばん", displayWord: "かいてんばん", type: .normal),
            Vocabulary(word: "るーれっと", displayWord: "るーれっと", type: .english),
            Vocabulary(word: "ぎゃんぶる", displayWord: "ぎゃんぶる", type: .rare)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_19", vocabularies: [
            Vocabulary(word: "ぷれいんぐかーど", displayWord: "ぷれいんぐかーど", type: .normal),
            Vocabulary(word: "とらんぷ", displayWord: "とらんぷ", type: .english),
            Vocabulary(word: "でっき", displayWord: "でっき", type: .rare),
            Vocabulary(word: "はーと", displayWord: "はーと", type: .rare),
            Vocabulary(word: "せぶん", displayWord: "せぶん", type: .rare),
            Vocabulary(word: "かーど", displayWord: "かーど", type: .surprise),
            Vocabulary(word: "なな", displayWord: "なな", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_20", vocabularies: [
            Vocabulary(word: "おくりもの", displayWord: "おくりもの", type: .normal),
            Vocabulary(word: "ぷれぜんと", displayWord: "ぷれぜんと", type: .english),
            Vocabulary(word: "ぎふと", displayWord: "ぎふと", type: .rare),
            Vocabulary(word: "らっぴんぐ", displayWord: "らっぴんぐ", type: .rare),
            Vocabulary(word: "りぼん", displayWord: "りぼん", type: .surprise),
            Vocabulary(word: "ごほうび", displayWord: "ごほうび", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_21", vocabularies: [
            Vocabulary(word: "いりぐち", displayWord: "いりぐち", type: .normal),
            Vocabulary(word: "どあ", displayWord: "どあ", type: .english),
            Vocabulary(word: "でぐち", displayWord: "でぐち", type: .rare),
            Vocabulary(word: "げんかん", displayWord: "げんかん", type: .rare),
            Vocabulary(word: "のぶ", displayWord: "のぶ", type: .surprise),
            Vocabulary(word: "ひらきど", displayWord: "ひらきど", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_22", vocabularies: [
            Vocabulary(word: "こおりがし", displayWord: "こおりがし", type: .normal),
            Vocabulary(word: "あいす", displayWord: "あいす", type: .english),
            Vocabulary(word: "じぇらーと", displayWord: "じぇらーと", type: .rare),
            Vocabulary(word: "らくとあいす", displayWord: "らくとあいす", type: .rare),
            Vocabulary(word: "すいーつ", displayWord: "すいーつ", type: .rare),
            Vocabulary(word: "そるべ", displayWord: "そるべ", type: .rare),
            Vocabulary(word: "おやつ", displayWord: "おやつ", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_23", vocabularies: [
            Vocabulary(word: "ひょうじょうきょうぎ", displayWord: "ひょうじょうきょうぎ", type: .normal),
            Vocabulary(word: "すけーと", displayWord: "すけーと", type: .english),
            Vocabulary(word: "ぶれーど", displayWord: "ぶれーど", type: .rare),
            Vocabulary(word: "えっじ", displayWord: "えっじ", type: .rare),
            Vocabulary(word: "あいすすけーと", displayWord: "あいすすけーと", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_24", vocabularies: [
            Vocabulary(word: "ゆうしょうはい", displayWord: "ゆうしょうはい", type: .normal),
            Vocabulary(word: "とろふぃー", displayWord: "とろふぃー", type: .english),
            Vocabulary(word: "しょうはい", displayWord: "しょうはい", type: .rare),
            Vocabulary(word: "ちゃんぴおんかっぷ", displayWord: "ちゃんぴおんかっぷ", type: .rare),
            Vocabulary(word: "かっぷ", displayWord: "かっぷ", type: .surprise)
        ], isCleared: false),
        Card(id: UUID(), imageName: "card2_25", vocabularies: [
            Vocabulary(word: "ぱん", displayWord: "ぱん", type: .normal),
            Vocabulary(word: "いーすと", displayWord: "いーすと", type: .english),
            Vocabulary(word: "ろーるぱん", displayWord: "ろーるぱん", type: .rare),
            Vocabulary(word: "ぶれっど", displayWord: "ぶれっど", type: .rare),
            Vocabulary(word: "やきたて", displayWord: "やきたて", type: .surprise),
            Vocabulary(word: "きつねいろ", displayWord: "きつねいろ", type: .surprise),
            Vocabulary(word: "こんがり", displayWord: "こんがり", type: .surprise)
        ], isCleared: false)
    ]
}
