import SwiftUI

struct LoadModifier: ViewModifier {
    var action: (() -> Void)?

    @State
    private var isLoaded = false

    func body(content: Content) -> some View {
        content.onAppear {
            if !isLoaded {
                isLoaded = true
                action?()
            }
        }
    }
}

extension View {
    func onLoad(perform action: (() -> Void)? = nil) -> some View {
        modifier(LoadModifier(action: action))
    }
}
