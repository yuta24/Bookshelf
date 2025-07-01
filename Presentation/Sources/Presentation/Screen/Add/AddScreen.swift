import SwiftUI
import ComposableArchitecture
import Inject
import Nuke
import NukeUI
import BookModel
import BookCore

private struct Custom: View {
    struct ColumnContent: View {
        let item: SearchingBook
        let onDelete: () -> Void

        var body: some View {
            LazyImage(url: item.imageURL) { state in
                if let image = state.image {
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Color.gray
                }
            }
            .frame(width: 90, height: 120)
            .overlay(alignment: .topTrailing) {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 12, height: 12)
                        .font(.body.weight(.bold))
                        .foregroundStyle(Color(.white))
                        .padding(8)
                        .background(Color(.black))
                        .clipShape(Circle())
                        .offset(x: 12, y: -12)
                }
            }
            .padding(4)
        }
    }

    let store: StoreOf<AddFeature>

    var body: some View {
        ScrollView(.horizontal) {
            LazyHGrid(rows: [GridItem(.fixed(20))]) {
                ForEach(store.picks) { book in
                    ColumnContent(item: book) {
                        store.send(.screen(.onDelete(book)))
                    }
                }
            }
        }
    }
}

struct AddScreen: View {
    struct Search: View {
        @Bindable
        var store: StoreOf<AddFeature>

        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color(.systemGray))
                    .frame(width: 20, height: 20)

                TextField(
                    "add.screen.search.placeholder",
                    text: $store.text.sending(\.screen.textChanged)
                )
                .font(.callout)
                .foregroundStyle(store.text.isEmpty ? Color(.systemGray) : Color(.label))

                if !store.text.isEmpty {
                    Button {
                        store.send(.screen(.onClearTapped))
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(.systemGray))
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .padding(8)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.horizontal)
        }
    }

    struct Control: View {
        let store: StoreOf<AddFeature>

        var body: some View {
            Button {
                store.send(.screen(.onRegisterTapped))
            } label: {
                Label("button.title.register", systemImage: "plus")
                    .foregroundStyle(Color(.white))
                    .padding(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .background(store.isRegisterEnabled ? Color(.tintColor) : Color(.gray))
                    .clipShape(Capsule())
            }
            .disabled(!store.isRegisterEnabled)

            Button {
                store.send(.screen(.onCustomTapped))
            } label: {
                Label("\(store.picks.count)", systemImage: "book.closed")
                    .foregroundStyle(Color(.white))
                    .padding(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .background(store.isRegisterEnabled ? Color(.tintColor) : Color(.gray))
                    .clipShape(Capsule())
            }
            .disabled(!store.isRegisterEnabled)
            .offset(x: -120, y: 0)
        }
    }

    @Bindable
    var store: StoreOf<AddFeature>

    @ObserveInjection
    var inject

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Search(store: store)
                    .padding(.vertical, 4)

                ZStack {
                    ScrollView {
                        ForEach(store.items) { item in
                            SearchingBookView(item: item)
                                .contentShape(Rectangle())
                                .padding(3)
                                .background(Color(.systemBackground))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(
                                            item.selected ? Color(.tintColor) : Color(.clear), lineWidth: 4
                                        )
                                }
                                .cornerRadius(4)
                                .onTapGesture {
                                    store.send(.screen(.onSelected(item.book)))
                                }
                        }
                        .padding(.horizontal)
                    }
                    .background(Color(.systemGroupedBackground))
                    .safeAreaInset(edge: .bottom) {
                        Spacer().frame(height: 54)
                    }

                    ZStack {
                        Control(store: store)
                    }
                    .frame(maxHeight: .infinity, alignment: Alignment(horizontal: .center, vertical: .bottom))
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationDestination(
                item: $store.scope(state: \.destination?.scan, action: \.destination.scan),
                destination: { store in
                    ScanScreen(store: store)
                }
            )
            .navigationTitle(Text("screen.title.register_book"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        action: { store.send(.screen(.onCloseTapped)) },
                        label: { Image(systemName: "xmark") }
                    )
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(
                        action: { store.send(.screen(.onCameraTapped)) },
                        label: { Image(systemName: "camera") }
                    )
                }
            }
            .onSubmit(of: .text) {
                store.send(.screen(.onSubmitted))
            }
            .sheet(isPresented: $store.isCustomActived.sending(\.screen.onCustomDismissed)) {
                NavigationStack {
                    Custom(store: store)
                        .navigationTitle(.init("screen.title.selected"))
                        .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.height(200)])
            }
        }
        .task { store.send(.screen(.task)) }
        .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
        .enableInjection()
    }
}

private extension SearchingBookView {
    init(item: AddFeature.Item) {
        title = item.book.title
        author = item.book.author
        imageURL = item.book.imageURL
        publisher = item.book.publisher
        registered = item.book.registered
    }
}
