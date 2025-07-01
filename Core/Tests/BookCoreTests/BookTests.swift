import XCTest
@testable import BookModel

final class BookTests: XCTestCase {
    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func test_isbn_convert_10() {
        let items: [(String, String)] = [
            ("978-4815607852", "4815607850"),
            ("978-4862761804", "4862761801"),
            ("978-4814400942", "4814400942"),
            ("978-4297113476", "4297113473"),
            ("978-4297145460", "4297145464"),
            ("978-4873115658", "4873115655"),
            ("978-4065369579", "4065369576"),
            ("978-4297142933", "4297142937"),
            ("978-4764960336", "4764960338"),
            ("978-4781702582", "4781702589"),
            ("978-4798067278", "479806727X"),
        ]

        for item in items {
            let isbn13 = Book.ISBN(rawValue: item.0)
            XCTAssertEqual(isbn13.convertTo10()?.rawValue, item.1)
        }
    }
}
