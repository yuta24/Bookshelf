import Testing
import SwiftUI
import SnapshotTesting
import ComposableArchitecture
import BookModel
import StatisticsCore
import OrderedCollections
import Foundation
@testable import Presentation

@MainActor
struct StatisticsScreenSnapshotTests {
    @Test
    func statisticsScreenEmpty() {
        let store = Store(initialState: StatisticsFeature.State.make()) {
            StatisticsFeature()
        }
        let view = StatisticsScreen(store: store)

        withSnapshotTesting(record: .failed) {
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.9, layout: .screen))
        }
    }

    @Test
    func statisticsScreenWithData() {
        var state = StatisticsFeature.State.make()
        let books: IdentifiedArrayOf<Book> = .init(uniqueElements: [
            Book(
                id: .init(),
                title: "Book 1",
                author: "Author 1",
                price: 100,
                affiliateURL: nil,
                imageURL: URL(string: "https://example.com/1.jpg")!,
                isbn: "9781234567890",
                publisher: "Publisher 1",
                caption: nil,
                salesAt: "2025-01-01",
                bought: true,
                note: "",
                status: .read(.init()),
                createdAt: .init(),
                updatedAt: .init(),
                tags: []
            ),
        ])
        let empty: IdentifiedArrayOf<Book> = []
        state.books = OrderedDictionary(uniqueKeysWithValues: [(1, books), (2, empty), (3, empty), (4, empty), (5, empty), (6, empty), (7, empty), (8, empty), (9, empty), (10, empty), (11, empty), (12, empty)])
        let store = Store(initialState: state) {
            StatisticsFeature()
        }
        let view = StatisticsScreen(store: store)

        withSnapshotTesting(record: .failed) {
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.9, layout: .screen))
        }
    }
}
