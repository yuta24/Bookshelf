import Foundation

public class Session {
    public typealias Authenticator = (inout URLRequest) -> Void

    public static let `default`: Session = .init()

    private let session: URLSession
    private let loader: DataLoader

    public init(configuration: URLSessionConfiguration = .default) {
        self.loader = .init()
        self.session = .init(configuration: configuration, delegate: loader, delegateQueue: nil)
    }

    public func data(
        _ request: URLRequest,
        with authenticator: Authenticator? = nil,
        completion: @escaping (Result<Response<Data>, Error>) -> Void
    ) {
        var request = request
        authenticator?(&request)
        loader.load(request, using: session) { result in
            let result = result.map { Response<Data>(response: $0.1, value: $0.0) }
            completion(result)
        }
    }
}

public extension Session {
    func data(
        _ url: URL,
        with authenticator: Authenticator? = nil,
        completion: @escaping (Result<Response<Data>, Error>) -> Void
    ) {
        data(.init(url: url), with: authenticator, completion: completion)
    }
}
