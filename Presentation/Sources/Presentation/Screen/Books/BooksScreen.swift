import SwiftUI
import ComposableArchitecture
import Inject
import Nuke
import NukeUI
import BookModel
import GenreModel
import BookCore

struct BooksScreen: View {
    struct Main: View {
        @Bindable
        var store: StoreOf<BooksFeature>

        var body: some View {
            ScrollView(showsIndicators: false) {
                if !store.news.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            ForEach(store.news.prefix(5)) { book in
                                SearchingBookView(book: book)
                                    .contentShape(Rectangle())
                                    .padding(4)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(4)
                                    .onTapGesture {
                                        store.send(.screen(.onBookTapped(book)))
                                    }
                            }
                        }
                    } header: {
                        LabeledContent {
                            Button(
                                action: {},
                                label: { Text("more") }
                            )
                        } label: {
                            Text("new_release")
                                .font(.headline)
                        }
                    }
                }

                Spacer().frame(height: 16)

                if !store.sales.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            ForEach(store.sales.prefix(5)) { book in
                                SearchingBookView(book: book)
                                    .contentShape(Rectangle())
                                    .padding(4)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(4)
                                    .onTapGesture {
                                        store.send(.screen(.onBookTapped(book)))
                                    }
                            }
                        }
                    } header: {
                        LabeledContent {
                            Button(
                                action: {},
                                label: { Text("more") }
                            )
                        } label: {
                            Text("well_selling")
                                .font(.headline)
                        }
                    }
                }
            }
            .refreshable { store.send(.screen(.onRefresh)) }
        }
    }

    @Bindable
    var store: StoreOf<BooksFeature>

    @ObserveInjection
    var inject

    var body: some View {
        NavigationStack {
            ZStack {
                Main(store: store)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("screen.title.books"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker(selection: $store.genre.sending(\.screen.genreSelected)) {
                            ForEach(store.genres, id: \.self) { genre in
                                Text("\(genre.name)")
                            }
                        } label: {}
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } label: {
                        Text(store.genre.name)
                    }
                }
            }
            .sheet(item: $store.scope(state: \.destination?.book, action: \.destination.book)) { store in
                BookScreen(store: store)
                    .presentationDetents(store.book.caption?.isEmpty ?? true ? [.medium] : [.medium, .large])
            }
        }
        .task { store.send(.screen(.task)) }
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
        registered = book.registered
    }
}
