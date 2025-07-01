import SwiftUI

public struct RemoteStack<Payload: TemplateParameters, Content: View>: View {
    struct Context {
        let kind: RemoteKind
        let payload: Payload
    }

    private let context: Context

    @Environment(\.remoteContainer)
    private var remoteContainer

    @ViewBuilder
    private let content: Content
    @State
    private var template: String?

    public var body: some View {
        content
            .onReceive(remoteContainer.$templates) { templates in
                template = templates[context.kind]
            }
    }

    public init(kind: RemoteKind, payload: Payload, @ViewBuilder content: () -> Content) {
        self.context = .init(kind: kind, payload: payload)
        self.content = content()
    }
}
