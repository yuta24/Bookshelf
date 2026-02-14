import Testing
import SwiftUI
import SnapshotTesting
import ComposableArchitecture
import BookModel
import BookCore
import Foundation
@testable import Presentation

@MainActor
struct BooksScreenSnapshotTests {
    @Test
    func booksScreenEmpty() {
        let store = Store(initialState: BooksFeature.State.make()) {
            BooksFeature()
        }
        let view = BooksScreen(store: store)

        withSnapshotTesting(record: .failed) {
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.9, layout: .screen))
        }
    }

    @Test
    func booksScreenWithData() {
        var state = BooksFeature.State.make()
        state.news = .init(uniqueElements: [
            SearchingBook(
                title: "New Swift Book",
                author: "Author A",
                price: 100,
                affiliateURL: nil,
                imageURL: URL(string: "https://example.com/a.jpg")!,
                isbn: "9781234567890",
                publisher: "Publisher A",
                caption: nil,
                salesAt: "2025-01-01",
                registered: false
            ),
        ])
        state.sales = .init(uniqueElements: [
            SearchingBook(
                title: "Best Selling iOS",
                author: "Author B",
                price: 200,
                affiliateURL: nil,
                imageURL: URL(string: "https://example.com/b.jpg")!,
                isbn: "9780987654321",
                publisher: "Publisher B",
                caption: nil,
                salesAt: "2025-02-01",
                registered: false
            ),
        ])
        let store = Store(initialState: state) {
            BooksFeature()
        }
        let view = BooksScreen(store: store)

        withSnapshotTesting(record: .failed) {
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.9, layout: .screen))
        }
    }
}
