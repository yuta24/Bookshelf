import Testing
import SwiftUI
import SnapshotTesting
import ComposableArchitecture
import BookModel
import BookCore
import Foundation
@testable import Presentation

@MainActor
struct DetailScreenSnapshotTests {
    @Test
    func detailScreenUnread() {
        let book = Book(
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
        )
        let shared = Shared(value: book)
        let store = Store(initialState: DetailFeature.State.make(book: shared)) {
            DetailFeature()
        }
        let view = DetailScreen(store: store)

        withSnapshotTesting(record: .failed) {
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.9, layout: .screen))
        }
    }

    @Test
    func detailScreenWithTags() {
        let book = Book(
            id: .init(),
            title: "iOS Development",
            author: "Jane Smith",
            price: 200,
            affiliateURL: nil,
            imageURL: URL(string: "https://example.com/ios.jpg")!,
            isbn: "9780987654321",
            publisher: "Mobile Press",
            caption: nil,
            salesAt: "2025-02-01",
            bought: true,
            note: "Great book",
            status: .read(.init()),
            createdAt: .init(),
            updatedAt: .init(),
            tags: [
                Tag(id: .init(), name: "Swift", createdAt: .init(), updatedAt: .init()),
                Tag(id: .init(), name: "iOS", createdAt: .init(), updatedAt: .init()),
            ]
        )
        let shared = Shared(value: book)
        let store = Store(initialState: DetailFeature.State.make(book: shared)) {
            DetailFeature()
        }
        let view = DetailScreen(store: store)

        withSnapshotTesting(record: .failed) {
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.9, layout: .screen))
        }
    }
}
