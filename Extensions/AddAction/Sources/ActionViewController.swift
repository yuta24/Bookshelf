import Combine
import UIKit
import SwiftUI
import MobileCoreServices
import UniformTypeIdentifiers
import SwiftSoup
import Infrastructure
import BookModel
import ShelfClient
import ShelfClientLive
import SearchClient
import SearchClientLive
import MigrationCore
import SQLiteData

@MainActor
final class ActionViewModel: ObservableObject {
    struct NotFound: Error {}

    struct FailureReason {
        var message: LocalizedStringKey
    }

    var completion: (() -> Void)?

    @Published
    private(set) var book: SearchingBook?
    @Published
    private(set) var reason: FailureReason?

    private let session: URLSession = .shared
    private let search: SearchClient = .generate(.shared)
    private let shelfClient: ShelfClient
    private let persistence: PersistenceController = .shared

    private var task: Task<Void, Never>?

    init() {
        // swiftlint:disable:next force_cast
        let appGroupsName = Bundle.main.object(forInfoDictionaryKey: "AppGroupsName") as! String

        let database = try! createDatabase(id: appGroupsName, with: .default)

        let migrationClient = MigrationClient.generate(
            persistence: persistence,
            grdbDatabase: database,
            appGroupIdentifier: appGroupsName
        )

        let isMigrationCompleted = migrationClient.isCompleted()

        self.shelfClient = isMigrationCompleted
            ? .generateGRDB(database)
            : .generate(persistence)
    }

    func onReceive(_ url: URL) {
        // TODO: Check domain

        task = .detached { [weak self, search] in
            do {
                let htmlString = try String(contentsOf: url)
                let document = try parse(htmlString)

                let detail = try document.select("div#detailBullets_feature_div")
                guard let li = try detail.select("li:contains(ISBN-13)").first() else {
                    throw NotFound()
                }
                guard let raw = try li.children().first()?.children().last()?.text().trimmingCharacters(in: .whitespacesAndNewlines) else {
                    throw NotFound()
                }

                let isbn = raw.filter(\.isNumber)

                let (books, _) = try await search.search(.isbn(isbn))

                if let book = books.first {
                    await MainActor.run { [weak self] in
                        self?.book = book
                    }
                } else {
                    await MainActor.run { [weak self] in
                        self?.reason = .init(message: LocalizedStringKey("error.message.not_found"))
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.reason = .init(message: LocalizedStringKey("error.message.not_found"))
                }
            }
        }
    }

    func onRegister() {
        guard let book else { return }
        task = .init { [shelfClient, completion] in
            do {
                _ = try await shelfClient.create(book)
                completion?()
            } catch {
                // TODO: Error handling
            }
        }
    }
}

struct ActionView: View {
    struct ItemView: View {
        let book: SearchingBook

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AsyncImage(url: book.imageURL)

                    Text(book.title)
                        .font(.headline)

                    VStack(alignment: .leading) {
                        Text(book.author)
                            .font(.callout)
                        Text(book.publisher)
                            .font(.callout)
                        Text(book.price, format: .currency(code: "JPY"))
                            .font(.callout)
                    }
                }
                .padding()
            }
        }
    }

    @ObservedObject
    var model: ActionViewModel

    var body: some View {
        Group {
            if let book = model.book {
                VStack {
                    ItemView(book: book)

                    Spacer()

                    Button {
                        model.onRegister()
                    } label: {
                        Label("button.title.register", systemImage: "plus")
                            .foregroundStyle(Color(.white))
                            .padding(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .background(Color(.tintColor))
                            .clipShape(Capsule())
                    }
                    .padding()
                }
            } else if let reason = model.reason {
                Text(reason.message)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background {
            Color(.systemGroupedBackground)
        }
    }
}

final class ActionViewController: UIViewController {
    @IBOutlet
    private var contentView: UIView!

    private let model: ActionViewModel = .init()

    override func viewDidLoad() {
        super.viewDidLoad()

        model.completion = { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: [])
        }

        let controller = UIHostingController(rootView: ActionView(model: model))
        addChild(controller)
        contentView.addSubview(controller.view)
        controller.didMove(toParent: self)

        controller.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: controller.view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
        ])

        for item in extensionContext!.inputItems as! [NSExtensionItem] {
            for provider in item.attachments! {
                guard provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) else {
                    break
                }

                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, _ in
                    guard let url = item as? URL else { return }

                    self?.model.onReceive(url)
                }
            }
        }
    }

    @IBAction
    func cancel() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        extensionContext!.completeRequest(returningItems: [])
    }
}
