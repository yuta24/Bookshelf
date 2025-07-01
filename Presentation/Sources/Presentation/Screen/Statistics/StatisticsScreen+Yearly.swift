import SwiftUI
import ComposableArchitecture
import StatisticsCore

private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale.current
    return calendar
}()

extension StatisticsScreen {
    struct Yearly: View {
        let store: StoreOf<StatisticsFeature>

        var body: some View {
            VStack(spacing: 0) {
                Component.Year(store: store)

                Component.Graph(state: store.state)
                    .padding()

                Divider().padding(.horizontal)

                List {
                    ForEach(store.books.keys, id: \.self) { month in
                        Section {
                            let books = store.books[month] ?? []
                            if books.isEmpty {
                                Text("no_data")
                            } else {
                                ForEach(books) { book in
                                    Text(book.title.rawValue)
                                        .font(.subheadline)
                                }
                            }
                        } header: {
                            Text(calendar.monthSymbols[month - 1])
                                .font(.headline)
                        }
                    }
                }
            }
        }
    }
}
