public struct Prism<Whole, Part> {
    public let tryGet: (Whole) -> Part?
    public let inject: (Part) -> Whole

    public init(
        tryGet: @escaping (Whole) -> Part?,
        inject: @escaping (Part) -> Whole
    ) {
        self.tryGet = tryGet
        self.inject = inject
    }
}

public extension Prism {
    func tryModify(_ transform: @escaping (Part) -> Part) -> (Whole) -> Whole {
        { whole in
            self.tryGet(whole).map { self.inject(transform($0)) } ?? whole
        }
    }

    func then<SubPart>(_ other: Prism<Part, SubPart>) -> Prism<Whole, SubPart> {
        .init { whole in
            self.tryGet(whole).flatMap(other.tryGet)
        } inject: { sub in
            self.inject(other.inject(sub))
        }
    }
}
