import Testing
import SwiftUI
import SnapshotTesting
import ComposableArchitecture
import BookModel
@testable import BookCore
import Foundation
@testable import Presentation

@MainActor
struct TagsScreenSnapshotTests {
    @Test
    func tagsScreenEmpty() {
        let store = Store(initialState: TagsFeature.State(tags: [], selected: [])) {
            TagsFeature()
        }
        let view = TagsScreen(store: store)

        withSnapshotTesting(record: .failed) {
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.9, layout: .screen))
        }
    }

    @Test
    func tagsScreenWithTags() {
        let tags: IdentifiedArrayOf<BookModel.Tag> = .init(uniqueElements: [
            BookModel.Tag(id: .init(), name: "Swift", createdAt: .init(), updatedAt: .init()),
            BookModel.Tag(id: .init(), name: "iOS", createdAt: .init(), updatedAt: .init()),
            BookModel.Tag(id: .init(), name: "SwiftUI", createdAt: .init(), updatedAt: .init()),
        ])
        let selected = [tags[0]]
        let store = Store(initialState: TagsFeature.State(tags: tags, selected: selected)) {
            TagsFeature()
        }
        let view = TagsScreen(store: store)

        withSnapshotTesting(record: .failed) {
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.9, layout: .screen))
        }
    }
}
