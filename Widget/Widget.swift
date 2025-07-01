import SwiftData
import SwiftUI
import WidgetKit
import BookModel
import Charts
import Infrastructure
import Intents
import SearchClientLive
import ShelfClient
import ShelfClientLive

struct Provider: IntentTimelineProvider {
    let shelfClient: ShelfClient

    func placeholder(in _: Context) -> BooksEntry {
        BooksEntry(statistics: nil, readings: [], date: .init(), configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in _: Context, completion: @escaping (BooksEntry) -> Void) {
        let entry = BooksEntry(statistics: nil, readings: [], date: Date(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        Task {
            let date: Date = .init()
            let year = Calendar.current.component(.year, from: date)

            do {
                async let (unread, reading, read) = try await shelfClient.countAtYear(year)
                async let books = try await shelfClient.fetchAll(.status(.reading))
                let timeline = try await Timeline(
                    entries: [
                        BooksEntry(
                            statistics: .init(unread: unread, reading: reading, read: read),
                            readings: books.map { .init(id: $0.id, title: $0.title) }, date: date, configuration: configuration
                        ),
                    ],
                    policy: .atEnd
                )
                completion(timeline)
            } catch {
                completion(Timeline(entries: [], policy: .atEnd))
            }
        }
    }
}

struct BooksEntry: TimelineEntry {
    struct Statistics {
        let unread: Int
        let reading: Int
        let read: Int
    }

    struct Book_: Identifiable {
        let id: Book.ID
        let title: Book.Title
    }

    let statistics: Statistics?
    let readings: [Book_]
    let date: Date
    let configuration: ConfigurationIntent
}

struct StatisticsView: View {
    let statistics: BooksEntry.Statistics
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(date.formatted(.dateTime.year(.defaultDigits)))
                .bold()
                .frame(alignment: .topLeading)

            VStack(spacing: 6) {
                VStack(spacing: 4) {
                    VStack {
                        Text("Unread")
                            .font(.caption).bold()
                        Text("\(statistics.unread)")
                            .font(.callout)
                    }

                    VStack {
                        Text("Reading")
                            .font(.caption).bold()
                        Text("\(statistics.reading)")
                            .font(.callout)
                    }

                    VStack {
                        Text("Read")
                            .font(.caption).bold()
                        Text("\(statistics.read)")
                            .font(.callout)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.vertical)
    }
}

struct ReadingsView: View {
    let books: [BooksEntry.Book_]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reading books")
                .bold()
                .frame(alignment: .topLeading)

            if books.isEmpty {
                VStack(alignment: .leading) {
                    Text("No books found")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(books.prefix(3)) { book in
                        HStack {
                            Text(book.title.rawValue)
                                .font(.caption)
                                .lineLimit(1)
                                .padding(8)
                                .clipShape(Capsule())

                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .padding(.vertical)
    }
}

struct WidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        HStack(spacing: 0) {
            if let statistics = entry.statistics {
                StatisticsView(statistics: statistics, date: entry.date)
                    .padding(.horizontal)

                Divider().padding(.vertical)
            }

            ReadingsView(books: entry.readings)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.background, for: .widget)
    }
}

struct WidgetExt: Widget {
    let kind: String = "Widget"
    let persistence: PersistenceController = .shared

    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
            provider: Provider(shelfClient: .generate(persistence))
        ) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.systemMedium])
    }
}

struct Widget_Previews: PreviewProvider {
    static var previews: some View {
        WidgetEntryView(
            entry: BooksEntry(
                statistics: .init(unread: 123, reading: 24, read: 1234),
                readings: [
                    .init(id: .init(.init()), title: .init("Hoge")),
                    .init(id: .init(.init()), title: .init("Fuga")),
                    .init(id: .init(.init()), title: .init("Piyo")),
                ],
                date: Date(),
                configuration: ConfigurationIntent()
            )
        )
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
