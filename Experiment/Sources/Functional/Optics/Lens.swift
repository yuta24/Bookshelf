public struct Lens<Whole, Part> {
    public let get: (Whole) -> Part
    public let set: (Part) -> (Whole) -> Whole

    public init(
        get: @escaping (Whole) -> Part,
        set: @escaping (Part) -> (Whole) -> Whole
    ) {
        self.get = get
        self.set = set
    }
}

public extension Lens {
    func modify(_ transform: @escaping (Part) -> Part) -> (Whole) -> Whole {
        { whole in
            self.set(transform(self.get(whole)))(whole)
        }
    }

    func then<SubPart>(_ other: Lens<Part, SubPart>) -> Lens<Whole, SubPart> {
        .init { whole in
            other.get(self.get(whole))
        } set: { sub in
            { whole in
                self.set(other.set(sub)(self.get(whole)))(whole)
            }
        }
    }
}
