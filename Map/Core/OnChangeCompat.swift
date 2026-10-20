import SwiftUI

/// iOS 17以降は新しい`.onChange`を使い、iOS 16では互換処理で変更前後の値を渡す。
private struct OnChangeCompatModifier<Value: Equatable>: ViewModifier {
    let value: Value
    let action: (Value, Value) -> Void

    @State private var previousValue: Value

    init(value: Value, action: @escaping (Value, Value) -> Void) {
        self.value = value
        self.action = action
        _previousValue = State(initialValue: value)
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.onChange(of: value) { oldValue, newValue in
                action(oldValue, newValue)
            }
        } else {
            content.onChange(of: value) { newValue in
                let oldValue = previousValue
                previousValue = newValue
                action(oldValue, newValue)
            }
        }
    }
}

extension View {
    /// 値が変わったとき、iOS 16でも変更前後の値を受け取る。
    func onChangeCompat<Value: Equatable>(
        of value: Value,
        perform action: @escaping (Value, Value) -> Void
    ) -> some View {
        modifier(OnChangeCompatModifier(value: value, action: action))
    }
}
