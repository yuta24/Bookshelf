import Testing
import SwiftUI
import SnapshotTesting
import ComposableArchitecture
import BookModel
import BookCore
import Foundation
@testable import Presentation

@MainActor
struct AddScreenSnapshotTests {
    @Test
    func addScreenEmpty() {
        let store = Store(initialState: AddFeature.State.make()) {
            AddFeature()
        }
        let view = AddScreen(store: store)

        withSnapshotTesting(record: .failed) {
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.9, layout: .screen))
        }
    }

    @Test
    func addScreenWithSearchText() {
        let store = Store(initialState: AddFeature.State.make(text: "Swift")) {
            AddFeature()
        }
        let view = AddScreen(store: store)

        withSnapshotTesting(record: .failed) {
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.9, layout: .screen))
        }
    }
}
