// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XCTest

class RunnerUITests: XCTestCase {

    @available(iOS 16.4, *)
    func testDeepLinks() throws {
        var app = XCUIApplication()
        // Pre-warm the app and simulator caches so the initial launch does not exceed
        // FlutterEngine's 3.0s first-frame deadline.
        app.launch()
        app.terminate()

        // Cold start HTTPS
        app = XCUIApplication()
        var url = URL(string: "https://flutter-dashboard.appspot.com/invalid_cold")!
        app.open(url)

        XCTAssertTrue(app.staticTexts["https://flutter-dashboard.appspot.com/invalid_cold"].waitForExistence(timeout: 10), "Cold start HTTPS deep link failed")

        // Warm start HTTPS
        url = URL(string: "https://flutter-dashboard.appspot.com/invalid_warm")!
        app.open(url)
        XCTAssertTrue(app.staticTexts["https://flutter-dashboard.appspot.com/invalid_warm"].waitForExistence(timeout: 10), "Warm start HTTPS deep link failed")

        app.terminate()

        // Cold start custom scheme
        app = XCUIApplication()
        url = URL(string: "testscheme://flutter/custom_cold")!
        app.open(url)
        XCTAssertTrue(app.staticTexts["testscheme://flutter/custom_cold"].waitForExistence(timeout: 10), "Cold start custom scheme deep link failed")

        // Warm start custom scheme
        url = URL(string: "testscheme://flutter/custom_warm")!
        app.open(url)
        XCTAssertTrue(app.staticTexts["testscheme://flutter/custom_warm"].waitForExistence(timeout: 10), "Warm start custom scheme deep link failed")
    }
}
