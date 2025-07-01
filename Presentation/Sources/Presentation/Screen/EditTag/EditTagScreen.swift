import SwiftUI
import ComposableArchitecture
import Inject
import BookCore

struct EditTagScreen: View {
    let store: StoreOf<EditTagFeature>

    @ObserveInjection
    var inject

    var body: some View {
        NavigationStack {
            List {
                FlowLayout(alignment: .leading, spacing: 0) {
                    ForEach(store.items) { item in
                        HStack {
                            Text("\(item.tag.name)")
                                .font(.subheadline)
                                .foregroundStyle(item.selected ? Color(.label) : Color(.secondaryLabel))
                        }
                        .padding(.init(top: 2, leading: 8, bottom: 2, trailing: 8))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(item.selected ? Color(.label) : Color(.clear), lineWidth: 1)
                        )
                        .onTapGesture {
                            store.send(.screen(.onSelected(item)))
                        }
                        .padding(4)
                    }
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .task {
                store.send(.screen(.task))
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        action: { store.send(.screen(.onCloseTapped)) },
                        label: { Image(systemName: "xmark") }
                    )
                }
            }
            .navigationTitle(.init("screen.title.set_tag"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .enableInjection()
    }
}
