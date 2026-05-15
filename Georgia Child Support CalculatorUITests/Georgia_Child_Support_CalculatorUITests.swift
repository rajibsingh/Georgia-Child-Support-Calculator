import XCTest

final class Georgia_Child_Support_CalculatorUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsAppNameAndControls() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Working Numbers"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["childrenSelector"].exists)
        XCTAssertTrue(app.buttons["2 children"].exists)
        XCTAssertTrue(app.buttons["resetButton"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
