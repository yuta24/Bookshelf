import Foundation
import Sharing
import ComposableArchitecture
import BookModel
import GenreModel

extension SharedKey where Self == AppStorageKey<Layout> {
    static var layout: Self {
        appStorage("display:layout")
    }
}

extension SharedKey where Self == FileStorageKey<Genre> {
    static var genre: Self {
        fileStorage(.applicationSupportDirectory.appending(component: "genre.txt"))
    }
}

extension SharedKey where Self == InMemoryKey<IdentifiedArrayOf<Book>> {
    static var books: Self {
        inMemory("books")
    }
}
