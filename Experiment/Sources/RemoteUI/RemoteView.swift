import SwiftUI

public struct RemoteView<Payload: TemplateParameters>: View {
    struct Context {
        let kind: RemoteKind
        let payload: Payload
    }

    private let context: Context

    @Environment(\.remoteContainer)
    private var remoteContainer

    @State
    private var template: String?

    public var body: some View {
        Group {
            if let template {
                TemplateView(template: template, payload: context.payload)
                    .make()
            } else {
                EmptyView()
            }
        }
        .onReceive(remoteContainer.$templates) { templates in
            template = templates[context.kind]
        }
    }

    public init(kind: RemoteKind, payload: Payload) {
        self.context = .init(kind: kind, payload: payload)
    }
}
