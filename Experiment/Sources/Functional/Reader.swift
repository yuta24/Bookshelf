public struct Reader<Environment, Output> {
    private let closure: (Environment) async throws -> Output

    public init(_ closure: @escaping (Environment) async throws -> Output) {
        self.closure = closure
    }

    public func run(_ environment: Environment) async throws -> Output {
        try await closure(environment)
    }
}
