import SwiftUI
import Charts
import ComposableArchitecture
import Inject
import StatisticsCore

private extension StatisticsFeature.Tab {
    var key: LocalizedStringKey {
        switch self {
        case .yearly:
            "yearly"
        case .insight:
            "insight"
        }
    }
}

private extension StatisticsFeature.Custom.Target {
    var key: LocalizedStringKey {
        switch self {
        case .created:
            "statistics.screen.custom.target.created"
        case .read:
            "statistics.screen.custom.target.read"
        }
    }
}

struct StatisticsScreen: View {
    enum Component {
        struct Year: View {
            let store: StoreOf<StatisticsFeature>

            var body: some View {
                ZStack {
                    HStack(spacing: 24) {
                        Button(
                            action: { store.send(.screen(.onPreviousTapped)) },
                            label: { Image(systemName: "chevron.backward") }
                        )
                        .disabled(!store.previousEnabled)

                        Text(store.current.formatted(.dateTime.year()))
                            .font(.title)

                        Button(
                            action: { store.send(.screen(.onNextTapped)) },
                            label: { Image(systemName: "chevron.forward") }
                        )
                        .disabled(!store.nextEnabled)
                    }

                    HStack {
                        Spacer()

                        Menu {
                            ForEach(StatisticsFeature.Custom.Target.allCases, id: \.self) { target in
                                Button {
                                    store.send(.screen(.custom(.onTargetSelected(target))))
                                } label: {
                                    Text(target.key)
                                }
                            }
                        } label: {
                            Text(store.custom.target.key)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }

        struct Graph: View {
            let state: StatisticsFeature.State

            var maxY: Int {
                let maxY = state.books.reduce(0) { partialResult, args in
                    max(partialResult, args.value.count)
                }

                return ((maxY / 10) + 1) * 10
            }

            var body: some View {
                VStack(spacing: 8) {
                    Chart {
                        ForEach(state.books.keys, id: \.self) { month in
                            BarMark(x: .value("Month", "\(month)"),
                                    y: .value("Count", state.books[month]?.count ?? 0))
                        }
                    }
                    .chartYScale(domain: 0 ... maxY)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                            AxisValueLabel()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
            }
        }
    }

    let store: StoreOf<StatisticsFeature>

    @ObserveInjection
    var inject
    @Environment(\.scenePhase)
    var scenePhase

    var body: some View {
        NavigationStack {
            VStack {
                Yearly(store: store)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("screen.title.statistics"))
        }
        .onAppear { store.send(.screen(.onAppear)) }
        .onChange(of: scenePhase) { _, newValue in
            if case .active = newValue {
                store.send(.external(.onActive))
            }
        }
        .enableInjection()
    }
}
