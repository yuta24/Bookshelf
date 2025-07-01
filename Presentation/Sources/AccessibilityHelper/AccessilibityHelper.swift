import Foundation
import SwiftUI

public enum AccessibilityIdentifier {
    public enum Books {
        public enum Button: String {
            case addBook
        }

        case button(Button)
    }

    public enum AddBook {
        public enum Button: String {
            case close
        }

        case button(Button)
    }

    case books(Books)
    case addBook(AddBook)
}

public extension View {
    func accessibilityIdentifier(
        _ identifier: AccessibilityIdentifier
    ) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        switch identifier {
        case let .books(books):
            switch books {
            case let .button(button):
                accessibilityIdentifier("books_\(button.rawValue)")
            }
        case let .addBook(addBook):
            switch addBook {
            case let .button(button):
                accessibilityIdentifier("add_book_\(button.rawValue)")
            }
        }
    }
}
