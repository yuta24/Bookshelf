import SwiftUI
import ComposableArchitecture
import Inject
import Nuke
import NukeUI
import BookModel
import BookCore

struct BookScreen: View {
    @Bindable
    var store: StoreOf<BookFeature>

    @ObserveInjection
    var inject

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    SearchingBookView(book: store.book)

                    if let caption = store.book.caption {
                        Text(caption)
                            .font(.subheadline)
                    }
                }
                .padding(4)
                .background(Color(.systemBackground))
                .cornerRadius(4)
                .padding(.horizontal)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("screen.title.detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let registered = store.book.registered, !registered {
                    ToolbarItem(placement: .primaryAction) {
                        Button(
                            action: { store.send(.screen(.onRegisterTapped)) },
                            label: { Text("button.title.register") }
                        )
                    }
                }
            }
        }
        .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
        .enableInjection()
    }
}

private extension SearchingBookView {
    init(book: SearchingBook) {
        title = book.title
        author = book.author
        imageURL = book.imageURL
        publisher = book.publisher
        registered = nil
    }
}
