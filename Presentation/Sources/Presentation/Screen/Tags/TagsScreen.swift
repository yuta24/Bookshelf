import SwiftUI
import ComposableArchitecture
import Inject
import BookCore

struct TagsScreen: View {
    @Bindable
    var store: StoreOf<TagsFeature>

    @ObserveInjection
    var inject

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.tags) { tag in
                    LabeledContent {
                        Image(systemName: "checkmark").opacity(store.selected.contains(tag) ? 1 : 0)
                    } label: {
                        Text("\(tag.name)")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        store.send(.screen(.onSelected(tag)))
                    }
                    .swipeActions {
                        Button(
                            action: { store.send(.screen(.onDeleteTapped(tag))) },
                            label: { Text("button.title.delete") }
                        )
                        .tint(.red)
                    }
                }
            }
            .listStyle(.plain)
            .task { store.send(.screen(.task)) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        action: { store.send(.screen(.onCloseTapped)) },
                        label: { Image(systemName: "xmark") }
                    )
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(
                        action: { store.send(.screen(.onAddTapped)) },
                        label: { Text("button.title.add") }
                    )
                }
            }
            .navigationTitle(.init("screen.title.tags"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("alert.title.enter_tag", isPresented: $store.isAddPresented.sending(\.screen.add.onDismissed)) {
            TextField("tag.screen.register_placeholder", text: $store.text.sending(\.screen.add.onTextChanged))
            Button(
                action: { store.send(.screen(.add(.onCancelTapped))) },
                label: { Text("button.title.cancel") }
            )
            Button(
                action: { store.send(.screen(.add(.onAddTapped))) },
                label: { Text("button.title.add_tag") }
            )
        }
        .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
        .enableInjection()
    }
}
