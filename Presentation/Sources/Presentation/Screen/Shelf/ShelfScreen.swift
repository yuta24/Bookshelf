import SwiftUI
import ComposableArchitecture
import Inject
import Nuke
import NukeUI
import BookModel
import BookCore

extension BookCore.Layout {
    var icon: Image {
        switch self {
        case .list:
            Image(systemName: "rectangle.grid.1x2")
        case .grid:
            Image(systemName: "square.grid.3x2")
        }
    }

    var key: LocalizedStringKey {
        switch self {
        case .list:
            "shelf.screen.custom.list"
        case .grid:
            "shelf.screen.custom.grid"
        }
    }
}

private extension BookCore.Layout {
    func convert() -> BookGrid.Layout {
        switch self {
        case .list:
            .list
        case .grid:
            .grid
        }
    }
}

struct ShelfScreen: View {
    struct Control: View {
        let store: StoreOf<ShelfFeature>

        var body: some View {
            Button {
                store.send(.screen(.onAddTapped(store.text)))
            } label: {
                Label(store.text.isEmpty ? "button.title.add_book" : "button.title.add_book.text", systemImage: "plus")
                    .foregroundStyle(.white)
                    .padding(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .background(Color(.tintColor))
                    .clipShape(Capsule())
            }
            .padding()
        }
    }

    struct Main: View {
        @Bindable
        var store: StoreOf<ShelfFeature>

        @Environment(\.colorScheme)
        var colorScheme

        var body: some View {
            ScrollView {
                if !store.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(store.tags) { tag in
                                Text("\(tag.name)")
                                    .font(.subheadline)
                                    .padding(.init(top: 2, leading: 8, bottom: 2, trailing: 8))
                                    .background(
                                        colorScheme == .dark
                                            ? AnyView(Capsule(style: .continuous).stroke(Color(.label), lineWidth: 1))
                                            : AnyView(Capsule(style: .continuous).foregroundStyle(.white))
                                    )
                                    .onTapGesture {
                                        store.send(.screen(.onTagTapped(tag)))
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }

                BookGrid(layout: store.layout.convert(), books: store.items) { book, _ in
                    store.send(.screen(.onSelected(book)))
                }
            }
            .searchable(text: $store.text.sending(\.screen.onTextChanged))
            .refreshable { store.send(.screen(.onRefresh)) }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
                Spacer().frame(height: 72)
            }
        }
    }

    struct Top: ToolbarContent {
        @Bindable
        var store: StoreOf<ShelfFeature>

        @State
        var isImporting: Bool = false
        @State
        var isExporting: Bool = false

        var body: some ToolbarContent {
            if store.enableExport {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isExporting = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .fileExporter(isPresented: $isExporting, document: ExportableDocument(books: store.books), contentType: .plainText, onCompletion: { result in
                        switch result {
                        case .success:
                            break
                        case .failure:
                            break
                        }
                    })
                }
            }

            if store.enableImport {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isImporting = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .fileImporter(isPresented: $isImporting, allowedContentTypes: [.plainText], onCompletion: { result in
                        switch result {
                        case let .success(url):
                            store.send(.screen(.onImport(url)))
                        case .failure:
                            break
                        }
                    })
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                switch store.layout {
                case .list:
                    Button {
                        store.send(.screen(.onLayoutChanged(.grid)))
                    } label: {
                        Image(systemName: "square.grid.3x2")
                    }
                case .grid:
                    Button {
                        store.send(.screen(.onLayoutChanged(.list)))
                    } label: {
                        Image(systemName: "rectangle.grid.1x2")
                    }
                }
            }

            ToolbarItem(placement: .topBarLeading) {
                Button {
                    store.send(.screen(.onTagsTapped))
                } label: {
                    Image(systemName: "tag")
                }
            }
        }
    }

    @Bindable
    var store: StoreOf<ShelfFeature>

    @ObserveInjection
    var inject

    var body: some View {
        NavigationStack {
            ZStack {
                Main(store: store)

                Control(store: store)
                    .frame(maxHeight: .infinity, alignment: Alignment(horizontal: .center, vertical: .bottom))
            }
            .navigationDestination(
                item: $store.scope(state: \.destination?.detail, action: \.destination.detail),
                destination: { store in
                    DetailScreen(store: store)
                }
            )
            .navigationTitle(Text("screen.title.shelf"))
            .toolbar {
                Top(store: store)
            }
            .sheet(item: $store.scope(state: \.destination?.add, action: \.destination.add), content: { store in
                AddScreen(store: store)
            })
            .sheet(item: $store.scope(state: \.destination?.tags, action: \.destination.tags), content: { store in
                TagsScreen(store: store).presentationDetents([.medium])
            })
        }
        .task { store.send(.screen(.task)) }
        .onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)) { _ in
            store.send(.external(.onPersistentStoreRemoteChanged))
        }
        .enableInjection()
    }
}

import UniformTypeIdentifiers

private struct ExportableDocument: FileDocument {
    enum Constant {
        static let encoder: JSONEncoder = {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return encoder
        }()

        static let decoder: JSONDecoder = {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return decoder
        }()
    }

    static let readableContentTypes: [UTType] = [.plainText]

    var books: IdentifiedArrayOf<Book> = []

    init(books: IdentifiedArrayOf<Book>) {
        self.books = books
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            return
        }

        self.books = try Constant.decoder.decode(IdentifiedArrayOf<Book>.self, from: data)
    }

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        let data = try Constant.encoder.encode(books)
        return .init(regularFileWithContents: data)
    }
}
