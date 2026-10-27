import Foundation

// ランダムステージ専用の25枚のカードデータ
struct RandomShiritoriCardData {

    private static func vocabulary(_ word: String, type: WordType) -> Vocabulary {
        Vocabulary(word: word, displayWord: word, type: type)
    }

    static let cards: [Card] = [
        Card(id: UUID(), imageName: "card_001", vocabularies: [
            vocabulary("りんご", type: .normal),
            vocabulary("ふるーつ", type: .english),
            vocabulary("くだもの", type: .english),
            vocabulary("あかりんご", type: .rare),
            vocabulary("きのみ", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_002", vocabularies: [
            vocabulary("ごりら", type: .normal),
            vocabulary("しるばーばっく", type: .english),
            vocabulary("れいちょうるい", type: .rare),
            vocabulary("まうんてんごりら", type: .rare),
            vocabulary("るいじんえん", type: .rare),
            vocabulary("もりのてつがくしゃ", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_003", vocabularies: [
            vocabulary("らっぱ", type: .normal),
            vocabulary("とらんぺっと", type: .english),
            vocabulary("こるねっと", type: .rare),
            vocabulary("ぶらす", type: .rare),
            vocabulary("きんかんがっき", type: .surprise),
            vocabulary("ほーん", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_004", vocabularies: [
            vocabulary("はさみ", type: .normal),
            vocabulary("しざーず", type: .english),
            vocabulary("きりばさみ", type: .rare),
            vocabulary("たちばさみ", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_005", vocabularies: [
            vocabulary("みず", type: .normal),
            vocabulary("うぉーたー", type: .english),
            vocabulary("おひや", type: .rare),
            vocabulary("こっぷ", type: .rare),
            vocabulary("ぐらす", type: .rare),
            vocabulary("あくあ", type: .surprise),
            vocabulary("えいちつーおー", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_006", vocabularies: [
            vocabulary("すいか", type: .normal),
            vocabulary("うぉーたーめろん", type: .english),
            vocabulary("やさい", type: .rare),
            vocabulary("しましま", type: .surprise),
            vocabulary("たね", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_007", vocabularies: [
            vocabulary("かめ", type: .normal),
            vocabulary("たーとる", type: .english),
            vocabulary("とーたす", type: .english),
            vocabulary("りくがめ", type: .rare),
            vocabulary("みずがめ", type: .surprise),
            vocabulary("はちゅうるい", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_008", vocabularies: [
            vocabulary("めだか", type: .normal),
            vocabulary("らいすふぃっしゅ", type: .english),
            vocabulary("さかな", type: .rare),
            vocabulary("こざかな", type: .rare),
            vocabulary("ぎょるい", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_009", vocabularies: [
            vocabulary("かさ", type: .normal),
            vocabulary("ぱらそる", type: .english),
            vocabulary("あまがさ", type: .rare)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_010", vocabularies: [
            vocabulary("さる", type: .normal),
            vocabulary("もんきー", type: .english),
            vocabulary("えいぷ", type: .english),
            vocabulary("るいじんえん", type: .rare),
            vocabulary("ましら", type: .rare),
            vocabulary("れいちょうるい", type: .surprise),
            vocabulary("のざる", type: .surprise),
            vocabulary("やえん", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_011", vocabularies: [
            vocabulary("るーぺ", type: .normal),
            vocabulary("はんどるーぺ", type: .english),
            vocabulary("かくだいきょう", type: .rare),
            vocabulary("むしめがね", type: .rare),
            vocabulary("とつれんず", type: .surprise),
            vocabulary("てもちるーぺ", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_012", vocabularies: [
            vocabulary("へび", type: .normal),
            vocabulary("すねーく", type: .english),
            vocabulary("ばいぱー", type: .english),
            vocabulary("とぐろ", type: .rare),
            vocabulary("さーぺんと", type: .rare),
            vocabulary("み", type: .surprise),
            vocabulary("おろち", type: .surprise),
            vocabulary("だいじゃ", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_013", vocabularies: [
            vocabulary("ひこうき", type: .normal),
            vocabulary("ぷれーん", type: .english),
            vocabulary("えあばす", type: .rare),
            vocabulary("じぇっとき", type: .rare),
            vocabulary("こうくうき", type: .surprise),
            vocabulary("りょかくき", type: .surprise),
            vocabulary("かもつき", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_014", vocabularies: [
            vocabulary("きつね", type: .normal),
            vocabulary("ふぉっくす", type: .english),
            vocabulary("こぎつね", type: .rare),
            vocabulary("どうぶつ", type: .rare),
            vocabulary("ぬいぐるみ", type: .surprise),
            vocabulary("おすわり", type: .surprise),
            vocabulary("けもの", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_015", vocabularies: [
            vocabulary("ねこ", type: .normal),
            vocabulary("きゃっと", type: .english),
            vocabulary("こねこ", type: .rare),
            vocabulary("ぺっと", type: .rare),
            vocabulary("どうぶつ", type: .rare),
            vocabulary("おすわり", type: .surprise),
            vocabulary("ぬいぐるみ", type: .surprise),
            vocabulary("にゃんこ", type: .surprise),
            vocabulary("けもの", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_016", vocabularies: [
            vocabulary("こま", type: .normal),
            vocabulary("すぴん", type: .english),
            vocabulary("おもちゃ", type: .rare),
            vocabulary("いと", type: .rare),
            vocabulary("ひも", type: .rare),
            vocabulary("くるくる", type: .surprise),
            vocabulary("かいてん", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_017", vocabularies: [
            vocabulary("まつり", type: .normal),
            vocabulary("ふぇすてぃばる", type: .english),
            vocabulary("みこし", type: .rare),
            vocabulary("ちょうちん", type: .rare),
            vocabulary("おまつり", type: .rare),
            vocabulary("はっぴ", type: .rare),
            vocabulary("いせい", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_018", vocabularies: [
            vocabulary("りょうり", type: .normal),
            vocabulary("くっきんぐ", type: .english),
            vocabulary("ちょうり", type: .rare),
            vocabulary("しょくじ", type: .rare),
            vocabulary("めだまやき", type: .surprise),
            vocabulary("ごちそう", type: .surprise),
            vocabulary("ふらいぱん", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_019", vocabularies: [
            vocabulary("りす", type: .normal),
            vocabulary("すくわーれる", type: .english),
            vocabulary("きのみ", type: .rare),
            vocabulary("しっぽ", type: .rare),
            vocabulary("ぺっと", type: .rare),
            vocabulary("どうぶつ", type: .rare),
            vocabulary("ぬいぐるみ", type: .surprise),
            vocabulary("けもの", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_020", vocabularies: [
            vocabulary("すずめ", type: .normal),
            vocabulary("やちょう", type: .rare),
            vocabulary("ことり", type: .rare),
            vocabulary("どうぶつ", type: .rare),
            vocabulary("ちょうるい", type: .rare),
            vocabulary("えだ", type: .surprise),
            vocabulary("ぬいぐるみ", type: .surprise),
            vocabulary("つばさ", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_021", vocabularies: [
            vocabulary("めがね", type: .normal),
            vocabulary("あいうぇあ", type: .english),
            vocabulary("だてめがね", type: .rare),
            vocabulary("ろうがんきょう", type: .rare),
            vocabulary("ぐらす", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_022", vocabularies: [
            vocabulary("ねずみ", type: .normal),
            vocabulary("まうす", type: .english),
            vocabulary("らっと", type: .english),
            vocabulary("げっしるい", type: .rare),
            vocabulary("どぶねずみ", type: .rare),
            vocabulary("けもの", type: .surprise),
            vocabulary("のねずみ", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_023", vocabularies: [
            vocabulary("みみ", type: .normal),
            vocabulary("いやー", type: .english),
            vocabulary("ちょうかくき", type: .rare),
            vocabulary("がいじ", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_024", vocabularies: [
            vocabulary("みち", type: .normal),
            vocabulary("はいうぇい", type: .english),
            vocabulary("るーと", type: .english),
            vocabulary("うぇい", type: .english),
            vocabulary("どうろ", type: .rare),
            vocabulary("かいどう", type: .rare),
            vocabulary("こうどう", type: .surprise)
        ], isCleared: false),

        Card(id: UUID(), imageName: "card_025", vocabularies: [
            vocabulary("ちりとり", type: .normal),
            vocabulary("だすとぱん", type: .english)
        ], isCleared: false)
    ]
}
