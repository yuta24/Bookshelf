import SwiftUI
import Inject
import NukeUI
import ComposableArchitecture
import BookModel
import HotComponent

struct BookGrid: View {
    enum Layout: Equatable, CaseIterable {
        case list
        case grid
    }

    enum TapReason: Equatable, CaseIterable {
        case select
        case delete
    }

    var layout: Layout
    var books: [Book]
    var action: (Book, TapReason) -> Void

    @ObserveInjection
    var inject

    var body: some View {
        LazyVGrid(
            columns: layout == .list
                ? [.init(.flexible())] : [.init(.flexible()), .init(.flexible()), .init(.flexible())],
            spacing: 12
        ) {
            ForEach(books) { book in
                BookView(book: book, imageOnly: layout == .grid)
                    .contentShape(Rectangle())
                    .padding(4)
                    .background(Color(.systemBackground))
                    .cornerRadius(4)
                    .onTapGesture {
                        action(book, .select)
                    }
            }
            .padding(.horizontal)
        }
        .animation(.default, value: layout)
        .enableInjection()
    }
}

private extension BookView {
    init(book: Book, imageOnly: Bool) {
        title = book.title.rawValue
        author = book.author.rawValue
        imageURL = book.imageURL
        publisher = book.publisher.rawValue
        self.imageOnly = imageOnly
    }
}
