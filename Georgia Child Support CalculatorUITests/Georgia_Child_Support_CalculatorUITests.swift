//
//  Georgia_Child_Support_CalculatorUITests.swift
//  Georgia Child Support CalculatorUITests
//
//  Created by Rajib Singh on 4/26/26.
//

import XCTest

final class Georgia_Child_Support_CalculatorUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testLaunchShowsDefaultEstimate() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Child Support Calculator"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["finalPayment"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["finalPayment"].label, "$1,119")
        XCTAssertTrue(app.otherElements["childrenSpinner"].exists)
        XCTAssertTrue(app.buttons["2 children"].exists)
        XCTAssertTrue(app.buttons["parentingSchedulePicker"].exists)
        XCTAssertTrue(app.buttons["resetButton"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
