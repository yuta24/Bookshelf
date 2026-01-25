import SwiftUI
import ComposableArchitecture
import Inject
import Nuke
import NukeUI
import BookModel
import BookCore
import PreReleaseNotificationModel

private extension DetailFeature.Status {
    var key: LocalizedStringKey {
        switch self {
        case .unread:
            "reading_status.unread"
        case .reading:
            "reading_status.reading"
        case .read:
            "reading_status.read"
        }
    }
}

private extension Book.Status {
    var view: DetailFeature.Status {
        switch self {
        case .unread:
            .unread
        case .reading:
            .reading
        case .read:
            .read
        }
    }
}

struct DetailScreen: View {
    struct Info: View {
        let store: StoreOf<DetailFeature>

        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                LazyImage(url: store.book.imageURL) { state in
                    if let image = state.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Color.gray
                    }
                }
                .frame(width: 90, height: 120)

                VStack(alignment: .leading, spacing: 8) {
                    Text(store.book.title.rawValue)
                        .font(.headline)

                    VStack(alignment: .leading) {
                        Text(store.book.author.rawValue)
                            .font(.caption)
                        Text(store.book.publisher.rawValue)
                            .font(.caption)
                    }

                    Text(store.book.salesAt.rawValue)
                        .font(.caption)
                }
            }
        }
    }

    @Bindable
    var store: StoreOf<DetailFeature>

    @ObserveInjection
    var inject

    var body: some View {
        List {
            Section {
                Info(store: store)
            }

            Section {
                Toggle(
                    isOn: $store.book.bought.sending(\.screen.boughtChanged),
                    label: { Text("bought") }
                )

                VStack(alignment: .leading, spacing: 8) {
                    Picker(selection: $store.book.status.view.sending(\.screen.statusChanged)) {
                        ForEach(DetailFeature.Status.allCases, id: \.self) { status in
                            Text(status.key).tag(status)
                        }
                        .pickerStyle(.menu)
                    } label: {
                        Text("status")
                    }

                    if case let .read(date) = store.book.status {
                        DatePicker(
                            selection: .init(
                                get: { store.book.status.readAt ?? date },
                                set: { store.send(.screen(.readAtChanged($0))) }
                            ),
                            displayedComponents: .date
                        ) {
                            Text("reading_status.read_at")
                        }
                    }
                }

                if store.book.tags.isEmpty {
                    VStack {
                        Text("tag")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        store.send(.screen(.onTagTapped))
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("tag")

                        FlowLayout(alignment: .leading, spacing: 0) {
                            ForEach(store.book.tags) { tag in
                                HStack {
                                    Text("\(tag.name)")
                                        .font(.footnote.bold())
                                        .foregroundStyle(Color(.secondaryLabel))
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        store.send(.screen(.onTagTapped))
                    }
                }
            }

            if store.book.canReceivePreReleaseNotification {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("発売前通知", systemImage: "bell")
                                .font(.headline)
                            Spacer()
                            if store.preReleaseNotification != nil {
                                Button("停止") {
                                    store.send(.screen(.disablePreReleaseNotification))
                                }
                                .foregroundStyle(.red)
                            } else {
                                Button("設定") {
                                    store.send(.screen(.enablePreReleaseNotification))
                                }
                            }
                        }

                        if store.preReleaseNotification == nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("通知タイミング")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Picker("通知タイミング", selection: $store.notificationTiming.sending(\.screen.notificationTimingChanged)) {
                                    ForEach(PreReleaseNotification.NotificationTiming.allCases, id: \.self) { timing in
                                        Text(timing.title).tag(timing)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("通知設定済み")
                                    .font(.subheadline)
                                    .foregroundStyle(.green)

                                if let notification = store.preReleaseNotification {
                                    Text("\(DateFormatter.dateOnly.string(from: notification.notificationDate))に通知予定")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    TextField(
                        "no_note",
                        text: $store.book.note.rawValue.sending(\.screen.noteChanged),
                        axis: .vertical
                    )
                    .lineLimit(nil)
                    .font(.body)
                }
            }

            Section {
                Button {
                    store.send(.screen(.onDeleteTapped))
                } label: {
                    Label("button.title.delete_book", systemImage: "trash")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(Text("screen.title.detail"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        store.send(.screen(.refreshImage))
                    } label: {
                        Label("Refresh Image", systemImage: "arrow.triangle.2.circlepath")
                    }

                    if let url = store.state.book.url {
                        ShareLink(item: url, label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        })
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        })
        .task { store.send(.screen(.task)) }
        .sheet(item: $store.scope(state: \.destination?.edit, action: \.destination.edit), content: { store in
            EditTagScreen(store: store).presentationDetents([.medium])
        })
        .confirmationDialog($store.scope(state: \.confirmation, action: \.confirmationDialog))
        .alert($store.scope(state: \.alert, action: \.alert))
        .enableInjection()
    }
}

private extension Book {
    var url: URL? {
        guard let isbn = isbn.convertTo10() else { return nil }
        return URL(string: "https://www.amazon.co.jp/dp/\(isbn.rawValue)")
    }
}

private extension DateFormatter {
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
