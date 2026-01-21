import SwiftUI
import ComposableArchitecture
import Inject
import PulseUI
import RemindModel
import SettingsCore
import DataManagementCore
import UniformTypeIdentifiers
import BookModel

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
                        store.send(.screen(.onDataManagementTapped))
                    } label: {
                        Label("data_management", systemImage: "folder.badge.gearshape")
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
            .sheet(item: $store.scope(state: \.destination?.dataManagement, action: \.destination.dataManagement), content: { store in
                DataManagementScreen(store: store)
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
        .subscriptionStatusTask(for: store.groupID) { state in
            store.send(.screen(.onSubscriptionStatusTask(state.value ?? [])))
        }
        .enableInjection()
    }
}
