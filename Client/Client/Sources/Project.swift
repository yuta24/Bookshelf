import Foundation

struct Project {
    enum Kind {
        case debug
        case release
    }

    struct Subscription {
        let groupID: String
    }

    static var current: Project {
        switch Bundle.main.bundleIdentifier {
        case "com.bivre.bookshelf.develop":
            .debug
        case "com.bivre.bookshelf":
            .release
        default:
            fatalError()
        }
    }

    let kind: Kind
    let subscription: Subscription

    static let debug: Project = .init(
        kind: .debug,
        subscription: .init(groupID: "97F0329D")
    )
    static let release: Project = .init(
        kind: .release,
        subscription: .init(groupID: "21399339")
    )
}
