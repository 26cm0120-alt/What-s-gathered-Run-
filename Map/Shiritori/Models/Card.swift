import Foundation

// ゲーム盤面上の1枚のカードを表す
struct Card: Identifiable {
    let id: UUID
    let imageName: String
    let vocabularies: [Vocabulary]
    var isCleared: Bool
}
