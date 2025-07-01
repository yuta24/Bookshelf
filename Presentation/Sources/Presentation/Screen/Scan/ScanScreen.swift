import SwiftUI
import ComposableArchitecture
import Inject
import Nuke
import NukeUI
import BookModel
import BookCore
import Scanner

struct ScanScreen: View {
    struct Item: View {
        let item: SearchingBook

        var body: some View {
            HStack(alignment: .top) {
                LazyImage(url: item.imageURL) { state in
                    if let image = state.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Color.gray
                    }
                }
                .frame(width: 90, height: 120)

                VStack(alignment: .leading) {
                    Text(item.title).font(.headline)
                        .lineLimit(3)
                    Text(item.author).font(.body)
                        .lineLimit(1)
                    Text(item.publisher).font(.body)
                        .lineLimit(1)
                    Text(item.price, format: .currency(code: "JPY")).font(.callout)
                }

                Spacer()
            }
        }
    }

    @Bindable
    var store: StoreOf<ScanFeature>

    @ObserveInjection
    var inject

    var body: some View {
        WithViewStore(store) { state in
            state
        } content: { viewStore in
            ScrollView {
                ScanView(onCaptured: { text in
                    viewStore.send(.screen(.captureChanged(text)))
                })
                .cornerRadius(4)
                .frame(height: 180)
                .padding()

                VStack(alignment: .leading, spacing: 8) {
                    Text("screen.message.scan_book")
                        .font(.headline)

                    Text("screen.message.caption.scan_book")
                        .font(.caption)
                }
                .padding()

                if let item = viewStore.item {
                    Item(item: item)
                        .onTapGesture {
                            viewStore.send(.screen(.onSelected(item)))
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .padding(.horizontal)

                    Button {
                        viewStore.send(.screen(.onRescanTapped))
                    } label: {
                        Text("button.title.rescan")
                    }
                    .padding()
                }
            }
            .navigationTitle(.init("screen.title.scan_book"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
        .enableInjection()
    }
}
