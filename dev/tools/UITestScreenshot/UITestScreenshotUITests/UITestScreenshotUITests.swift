// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XCTest

final class UITestScreenshotUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let mainScreenScreenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: mainScreenScreenshot)
        attachment.name = "Screenshot"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
