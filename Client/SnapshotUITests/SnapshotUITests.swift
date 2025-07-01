import XCTest

@MainActor
class SnapshotUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    override func tearDownWithError() throws {}

    func test_take_screenshots_01() {
        snapshot("01-books")
    }

    func test_take_screenshots_02() {
        app.buttons["書籍の登録"].tap()

        sleep(1)

        snapshot("02-search")
    }

    func test_take_screenshots_03() {
        app.tabBars["タブバー"].buttons["振り返り"].tap()

        snapshot("03-statistics")
    }
}
