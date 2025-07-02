import Testing
import SwiftUI
import SnapshotTesting
import ComposableArchitecture
import BookModel
import BookCore
@testable import Presentation

@MainActor
struct ShelfScreenSnapshotTests {
    @Test
    func shelfScreenEmpty() {
        let store = Store(initialState: ShelfFeature.State.make()) {
            ShelfFeature()
        }

        withSnapshotTesting {
            assertSnapshot(of: ShelfScreen(store: store), as: .image(perceptualPrecision: 0.95, layout: .screen))
        }
    }

    @Test
    func shelfScreenWithBooks() {
        let books = IdentifiedArrayOf<Book>(uniqueElements: [
            Book(
                id: .init(),
                title: "Swift Programming",
                author: "John Doe",
                price: 100,
                affiliateURL: nil,
                imageURL: URL(string: "https://example.com/swift.jpg")!,
                isbn: "9781234567890",
                publisher: "Tech Books",
                caption: nil,
                salesAt: "2025-01-01",
                bought: false,
                note: "",
                status: .unread,
                createdAt: .init(),
                updatedAt: .init(),
                tags: []
            ),
            Book(
                id: .init(),
                title: "iOS Development",
                author: "Jane Smith",
                price: 200,
                affiliateURL: nil,
                imageURL: URL(string: "https://example.com/swift.jpg")!,
                isbn: "9780987654321",
                publisher: "Mobile Press",
                caption: nil,
                salesAt: "2025-02-01",
                bought: false,
                note: "",
                status: .unread,
                createdAt: .init(),
                updatedAt: .init(),
                tags: []
            ),
            Book(
                id: .init(),
                title: "SwiftUI Essentials",
                author: "Bob Johnson",
                price: 300,
                affiliateURL: nil,
                imageURL: URL(string: "https://example.com/swift.jpg")!,
                isbn: "9781122334455",
                publisher: "UI Publishers",
                caption: nil,
                salesAt: "2025-03-01",
                bought: true,
                note: "",
                status: .unread,
                createdAt: .init(),
                updatedAt: .init(),
                tags: []
            ),
        ])

        let store = Store(initialState: ShelfFeature.State.make(books: books)) {
            ShelfFeature()
        }

        withSnapshotTesting {
            assertSnapshot(of: ShelfScreen(store: store), as: .image(perceptualPrecision: 0.95, layout: .screen))
        }
    }

    @Test
    func shelfScreenGridLayout() async throws {
        let books = IdentifiedArrayOf<Book>(uniqueElements: [
            Book(
                id: .init(),
                title: "Book 1",
                author: "Author 1",
                price: 100,
                affiliateURL: nil,
                imageURL: URL(string: "https://example.com/swift.jpg")!,
                isbn: "9781234567890",
                publisher: "Publisher 1",
                caption: nil,
                salesAt: "2025-01-01",
                bought: false,
                note: "",
                status: .unread,
                createdAt: .init(),
                updatedAt: .init(),
                tags: []
            ),
            Book(
                id: .init(),
                title: "Book 2",
                author: "Author 2",
                price: 200,
                affiliateURL: nil,
                imageURL: URL(string: "https://example.com/swift.jpg")!,
                isbn: "9780987654321",
                publisher: "Publisher 2",
                caption: nil,
                salesAt: "2025-02-01",
                bought: false,
                note: "",
                status: .unread,
                createdAt: .init(),
                updatedAt: .init(),
                tags: []
            ),
        ])

        let store = Store(initialState: ShelfFeature.State.make(books: books, layout: .grid)) {
            ShelfFeature()
        }

        withSnapshotTesting {
            assertSnapshot(of: ShelfScreen(store: store), as: .image(perceptualPrecision: 0.95, layout: .screen))
        }
    }
}
