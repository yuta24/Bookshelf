import SwiftUI

public struct ComponentScope<Content: View, Style: Decodable>: View {
    public let container: ComponentContainer

    @ViewBuilder
    public let content: Component<Content, Style>

    public var body: some View {
        content
            .environment(\.container, container)
    }

    public init(container: ComponentContainer, @ViewBuilder content: () -> Component<Content, Style>) {
        self.container = container
        self.content = content()
    }
}
