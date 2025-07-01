import Foundation

private extension CodingUserInfoKey {
    static let types: CodingUserInfoKey = .init(rawValue: "types")!
}

public class ComponentRegistry {
    struct NotRegistered: Error {}

    struct NotFound: Error {}

    let decoder: JSONDecoder

    private var types: [ComponentKind: Decodable.Type] = [:]

    init(decoder: JSONDecoder = .init()) {
        self.decoder = decoder
    }

    public func register(payload: (some Decodable).Type, for key: ComponentKind) {
        types[key] = payload
    }

    struct Container: Decodable {
        enum CodingKeys: CodingKey {
            case kind
            case payload
        }

        let kind: ComponentKind
        let payload: any Decodable

        init(from decoder: Decoder) throws {
            guard let types = decoder.userInfo[.types] as? [ComponentKind: Decodable.Type] else {
                throw NotRegistered()
            }

            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.kind = try container.decode(ComponentKind.self, forKey: .kind)

            guard let type = types[kind] else {
                throw NotRegistered()
            }

            self.payload = try container.decode(type, forKey: .payload)
        }
    }

    func decode(from data: Data) throws -> [ComponentKind: any Decodable] {
        decoder.userInfo[.types] = types
        let decoded = try decoder.decode([Container].self, from: data)
        return decoded.reduce(into: [:]) { partialResult, container in
            partialResult[container.kind] = container.payload
        }
    }
}
