import Foundation

public struct AffineTraversal<Whole, Part> {
    public let tryGet: (Whole) -> Part?
    public let trySet: (Part) -> (Whole) -> Whole?
}

public extension AffineTraversal {
    func tryModify(_ transform: @escaping (Part) -> Part) -> (Whole) -> Whole? {
        { whole in
            self.tryGet(whole)
                .map(transform)
                .flatMap { self.trySet($0)(whole) }
        }
    }

    func then<SubPart>(_ other: AffineTraversal<Part, SubPart>) -> AffineTraversal<Whole, SubPart> {
        .init { whole in
            self.tryGet(whole).flatMap(other.tryGet)
        } trySet: { sub in
            { whole in
                self.tryGet(whole)
                    .flatMap { other.trySet(sub)($0) }
                    .flatMap { self.trySet($0)(whole) }
            }
        }
    }
}
