import SwiftUI
import ComposableArchitecture
import Inject
import PulseUI
import RemindModel
import SettingsCore
import UniformTypeIdentifiers
import BookModel
import DataClient

extension DayOfWeek {
    var key: String {
        switch self {
        case .sunday:
            "sunday"
        case .monday:
            "monday"
        case .tuesday:
            "tuesday"
        case .wednesday:
            "wednesday"
        case .thursday:
            "thursday"
        case .friday:
            "friday"
        case .saturday:
            "saturday"
        }
    }
}

extension Remind {
    var isEnabled: Bool {
        switch self {
        case .enabled:
            true
        case .disabled:
            false
        }
    }

    var dayOfWeek: DayOfWeek? {
        if case let .enabled(setting) = self {
            setting.dayOfWeek
        } else {
            nil
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter: DateFormatter = .init()
    formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "ha", options: 0, locale: .current)
    return formatter
}()

extension Remind.Setting {
    var dayOfWeekString: String {
        NSLocalizedString(dayOfWeek.key, comment: "")
    }

    var hourString: String {
        dateFormatter.string(from: DateComponents(calendar: .current, hour: hour).date!)
    }
}

struct SettingsScreen: View {
    @Bindable
    var store: StoreOf<SettingsFeature>

    @ObserveInjection
    var inject

    @State
    var isImporting: Bool = false
    @State
    var isExporting: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if !store.isMigrationCompleted {
                        Toggle(
                            isOn: $store.isSyncEnabled.sending(\.screen.syncEnabledChanged),
                            label: { Text("icloud_sync") }
                        )
                    }

                    if store.enableNotification {
                        Toggle(
                            isOn: $store.remind.isEnabled.sending(\.screen.remindEnabledChanged),
                            label: { Text("notifications") }
                        )
                    }

                    if case let .enabled(setting) = store.remind {
                        NavigationLink {
                            Form {
                                Picker(
                                    selection: .init(
                                        get: { store.remind.dayOfWeek! },
                                        set: { store.send(.screen(.dayOfWeekChanged($0))) }
                                    ),
                                    content: {
                                        ForEach(DayOfWeek.allCases, id: \.self) { dayOfWeek in
                                            Text(NSLocalizedString(dayOfWeek.key, comment: "")).tag(dayOfWeek)
                                        }
                                    },
                                    label: {}
                                )
                                .pickerStyle(.inline)
                            }
                        } label: {
                            LabeledContent {
                                Text("weekly_remind: \(setting.dayOfWeekString) \(setting.hourString)")
                            } label: {}
                        }
                    }
                }

                if let isPurchased = store.isPurchased, store.enablePurchase {
                    Section {
                        if isPurchased {
                            Label {
                                Text("Thank you for your support")
                            } icon: {
                                Image(systemName: "checkmark.circle")
                            }
                        } else {
                            Button {
                                store.send(.screen(.onSupportTapped))
                            } label: {
                                Text("support_app")
                            }
                        }
                    }
                }

                if !store.isMigrationCompleted {
                    Section {
                        Button {
                            store.send(.screen(.onMigrationTapped))
                        } label: {
                            Text("migration")
                        }
                    } header: {
                        Text("Data")
                    }
                }

                // データ管理セクション
                Section {
                    Button {
                        isExporting = true
                    } label: {
                        Label("export_data", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        isImporting = true
                    } label: {
                        Label("import_data", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("data_management")
                }

                Section {
                    Link("contact_us", destination: URL(string: "https://forms.gle/zqRXY74UU7WH9vf58")!)
                        .foregroundStyle(Color(.label))

                    HStack {
                        Text("version")

                        Spacer()

                        Text("\(store.version)(\(store.build))")
                    }
                } footer: {
                    Link("Supported by Rakuten Developers",
                         destination: URL(string: "https://webservice.rakuten.co.jp/")!)
                        .font(.caption)
                        .foregroundStyle(Color(.secondaryLabel))
                }

                if store.isProfileInstalled {
                    Section(
                        content: {
                            Button {
                                store.send(.screen(.onNetworkTapped))
                            } label: {
                                Text("Network")
                            }
                        },
                        header: {
                            Text("Developer")
                        }
                    )
                }
            }
            .navigationTitle(Text("screen.title.settings"))
            .sheet(item: $store.scope(state: \.destination?.support, action: \.destination.support), content: { store in
                SupportScreen(store: store).presentationDetents([.medium])
            })
            .sheet(item: $store.scope(state: \.destination?.migration, action: \.destination.migration), content: { store in
                MigrationScreen(store: store)
            })
            .sheet(
                isPresented: $store.isNetworkActived.sending(\.screen.onNetworkDismissed),
                content: {
                    NavigationStack {
                        ConsoleView()
                    }
                }
            )
        }
        .task { store.send(.screen(.task)) }
        .onLoad { store.send(.screen(.onLoad)) }
        .fileExporter(
            isPresented: $isExporting,
            document: store.exportData.map { ExportableDocument(exportData: $0) },
            contentType: .plainText,
            onCompletion: { result in
                switch result {
                case .success:
                    break
                case .failure:
                    break
                }
            }
        )
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.plainText],
            onCompletion: { result in
                switch result {
                case let .success(url):
                    store.send(.screen(.onImportTapped(url)))
                case .failure:
                    break
                }
            }
        )
        .subscriptionStatusTask(for: store.groupID) { state in
            store.send(.screen(.onSubscriptionStatusTask(state.value ?? [])))
        }
        .enableInjection()
    }
}

private struct ExportableDocument: FileDocument {
    enum Constant {
        static let encoder: JSONEncoder = {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return encoder
        }()

        static let decoder: JSONDecoder = {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return decoder
        }()
    }

    static let readableContentTypes: [UTType] = [.plainText]

    var exportData: ExportData

    init(exportData: ExportData) {
        self.exportData = exportData
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw DataExportError.invalidData
        }

        self.exportData = try Constant.decoder.decode(ExportData.self, from: data)
    }

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        let data = try Constant.encoder.encode(exportData)
        return .init(regularFileWithContents: data)
    }
}
