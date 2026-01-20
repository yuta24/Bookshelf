public import DataClient
public import ShelfClient
public import TagClient
public import BookModel

import Foundation

public extension DataClient {
    static func generate(
        shelfClient: ShelfClient,
        tagClient: TagClient
    ) -> Self {
        .init(
            export: {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

                let books = try await shelfClient.fetchAll(nil)
                let tags = try await tagClient.fetchAll()

                let exportData = ExportData(books: books, tags: tags)
                return try encoder.encode(exportData)
            },
            import: { data in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                let exportData = try decoder.decode(ExportData.self, from: data)

                guard exportData.version == 1 else {
                    throw DataExportError.invalidVersion
                }

                var importedTagsCount = 0
                var importedBooksCount = 0

                // Import tags first (books reference tags)
                for tag in exportData.tags {
                    let exists = try? await tagClient.exists(tag.name)
                    if let exists = exists, !exists {
                        _ = try await tagClient.create(.init(name: tag.name))
                        importedTagsCount += 1
                    }
                }

                // Import books
                try await shelfClient.resume(exportData.books)
                importedBooksCount = exportData.books.count

                return ImportResult(
                    importedBooksCount: importedBooksCount,
                    importedTagsCount: importedTagsCount
                )
            }
        )
    }
}
