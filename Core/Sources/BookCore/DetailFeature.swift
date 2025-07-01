public import Foundation

public import ComposableArchitecture

public import BookModel
public import PreReleaseNotificationModel
public import PreReleaseNotificationClient

import CasePaths
import FeatureFlags
import WidgetUpdater
import AnalyticsClient
import ShelfClient
import SearchClient
import Updater

@Reducer
public struct DetailFeature: Sendable {
    public enum Status: String, CaseIterable, Sendable {
        case unread
        case reading
        case read
    }

    @Reducer
    public struct Destination: Sendable {
        public enum State: Equatable, Sendable {
            case edit(EditTagFeature.State)
        }

        public enum Action: Sendable {
            case edit(EditTagFeature.Action)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: \.edit, action: \.edit) {
                EditTagFeature()
            }
        }
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        @Shared(.books)
        public var books: IdentifiedArrayOf<Book> = []

        @Shared
        public var book: Book

        public var preReleaseNotification: PreReleaseNotification?
        public var notificationTiming: PreReleaseNotification.NotificationTiming = .oneDayBefore

        @Presents
        public var destination: Destination.State?
        @Presents
        public var confirmation: ConfirmationDialogState<Action.ConfirmationDialogAction>?

        public static func make(book: Shared<Book>) -> State {
            .init(book: book)
        }
    }

    @CasePathable
    public enum Action: Sendable {
        @CasePathable
        public enum BooksAction: Sendable {
            case update(Book)
            case updated(Book)
            case remove(Book.ID)
            case removed(Book.ID)
        }

        @CasePathable
        public enum ConfirmationDialogAction: Equatable, Sendable {
            case onDeleteTapped
            case onCancelTapped
        }

        @CasePathable
        public enum ScreenAction: Sendable {
            case task
            case boughtChanged(Bool)
            case statusChanged(Status)
            case readAtChanged(Date)
            case noteChanged(String)
            case onTagTapped
            case onDeleteTapped
            case refreshImage
            case notificationTimingChanged(PreReleaseNotification.NotificationTiming)
            case enablePreReleaseNotification
            case disablePreReleaseNotification
            case preReleaseNotificationLoaded(PreReleaseNotification?)
        }

        case books(BooksAction)
        case destination(PresentationAction<Destination.Action>)
        case confirmationDialog(PresentationAction<ConfirmationDialogAction>)
        case screen(ScreenAction)
    }

    @Dependency(AnalyticsClient.self)
    var analyticsClient
    @Dependency(ShelfClient.self)
    var shelfClient
    @Dependency(SearchClient.self)
    var searchClient
    @Dependency(FeatureFlags.self)
    var featureFlags
    @Dependency(WidgetUpdater.self)
    var widgetUpdater
    @Dependency(PreReleaseNotificationClient.self)
    var preReleaseNotificationClient
    @Dependency(\.date)
    var date
    @Dependency(\.dismiss)
    var dismiss

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .books(.update(book)):
                return .run { send in
                    let book = try await shelfClient.update(book)
                    await send(.books(.updated(book)))
                }
            case .books(.updated):
                return .run { _ in
                    await widgetUpdater.setNeedNotify()
                }
            case let .books(.remove(id)):
                return .run { send in
                    try await shelfClient.delete(id)
                    await send(.books(.removed(id)))
                }
            case let .books(.removed(id)):
                state.$books.withLock { $0.remove(id: id) }
                analyticsClient.log(event: .books(.removed))
                return .run { _ in
                    await widgetUpdater.setNeedNotify()
                    await dismiss()
                }
            case .destination(.presented(.edit)):
                return .none
            case .destination(.dismiss):
                state.destination = nil
                return .none
            case .confirmationDialog(.presented(.onDeleteTapped)):
                state.confirmation = nil
                return .send(.books(.remove(state.book.id)))
            case .confirmationDialog(.presented(.onCancelTapped)):
                state.confirmation = nil
                return .none
            case .confirmationDialog:
                return .none
            case .screen(.task):
                state.$book.withLock { $0.tags.sort(by: { $0.name < $1.name }) }
                return .run { [bookId = state.book.id] send in
                    let notification = await preReleaseNotificationClient.fetch(bookId)
                    await send(.screen(.preReleaseNotificationLoaded(notification)))
                }
            case let .screen(.boughtChanged(bought)):
                state.$book.withLock { $0.bought = bought }
                return .send(.books(.update(state.book)))
            case let .screen(.statusChanged(status)):
                state.$book.withLock { $0.status = switch status {
                case .unread:
                    .unread
                case .reading:
                    .reading
                case .read:
                    .read(date.now)
                }
                }
                return .send(.books(.update(state.book)))
            case let .screen(.readAtChanged(date)):
                state.$book.withLock { $0.status = .read(date) }
                return .send(.books(.update(state.book)))
            case let .screen(.noteChanged(note)):
                state.$book.withLock { $0.note.rawValue = note }
                return .send(.books(.update(state.book)))
            case .screen(.onTagTapped):
                state.destination = .edit(.init(book: state.$book, items: []))
                return .none
            case .screen(.onDeleteTapped):
                state.confirmation = .init(
                    titleVisibility: .visible,
                    title: { .init("confirm.delete_book") },
                    actions: {
                        ButtonState(role: .cancel, action: .onCancelTapped, label: { .init("button.title.cancel") })
                        ButtonState(role: .destructive, action: .onDeleteTapped, label: { .init("button.title.delete") })
                    }
                )
                return .none
            case .screen(.refreshImage):
                return .run { [book = state.book] send in
                    let (books, _) = try await searchClient.search(.isbn(book.isbn.rawValue))
                    if let searchingBook = books.first {
                        var updatedBook = book
                        updatedBook.imageURL = searchingBook.imageURL
                        let book = try await shelfClient.update(updatedBook)
                        await send(.books(.update(book)))
                    }
                }
            case let .screen(.notificationTimingChanged(timing)):
                state.notificationTiming = timing
                return .none
            case .screen(.enablePreReleaseNotification):
                guard let notification = PreReleaseNotification.create(
                    for: state.book,
                    timing: state.notificationTiming
                ) else {
                    return .none
                }
                state.preReleaseNotification = notification
                return .run { _ in
                    await preReleaseNotificationClient.add(notification)
                }
            case .screen(.disablePreReleaseNotification):
                state.preReleaseNotification = nil
                return .run { [bookId = state.book.id] _ in
                    await preReleaseNotificationClient.remove(bookId)
                }
            case let .screen(.preReleaseNotificationLoaded(notification)):
                state.preReleaseNotification = notification
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) { Destination() }
    }
}
