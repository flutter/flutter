//
//  XcodeScreenshotUITests.swift
//  XcodeScreenshotUITests
//
//  Created by Victoria Ashworth on 10/10/23.
//

import XCTest

final class XcodeScreenshotUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let mainScreenScreenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: mainScreenScreenshot)
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
