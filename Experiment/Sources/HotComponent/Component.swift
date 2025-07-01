import SwiftUI

public struct ComponentKind: Hashable, Decodable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }
}

public struct Component<Content: View, Payload: Decodable>: View {
    public let kind: ComponentKind

    @ViewBuilder
    public let content: (Payload?) -> Content

    @Environment(\.container)
    var container

    @State
    var payload: Payload?

    public var body: some View {
        content(payload)
            .onReceive(container.$payloads) { payloads in
                payload = payloads[kind] as? Payload
            }
    }

    public init(kind: ComponentKind, payload _: Payload.Type, @ViewBuilder content: @escaping (Payload?) -> Content) {
        self.kind = kind
        self.content = content
    }
}
