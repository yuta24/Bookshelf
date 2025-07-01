import Foundation

public struct Response<Value> {
    public let response: URLResponse
    public let value: Value
}

public extension Response {
    func map<NewValue>(_ transform: (Value) -> NewValue) -> Response<NewValue> {
        .init(response: response, value: transform(value))
    }
}

public extension Response where Value == Data {
    func decode<NewValue: Decodable>(_ type: NewValue.Type, using decoder: JSONDecoder) throws -> Response<NewValue> {
        try .init(response: response, value: decoder.decode(type, from: value))
    }
}
