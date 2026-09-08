// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XCTest

class RunnerUITests: XCTestCase {

  override func setUp() {
    continueAfterFailure = false
  }

  @MainActor
  func testColdStartUniversalLink() throws {
    guard #available(iOS 16.4, *) else {
      throw XCTSkip("app.open(url) is only available on iOS 16.4+")
    }

    let app = XCUIApplication()
    let url = URL(string: "https://flutter-dashboard.appspot.com/invalid_cold")!
    app.open(url)

    XCTAssertTrue(
      app.staticTexts["https://flutter-dashboard.appspot.com/invalid_cold"].waitForExistence(timeout: 10),
      "Cold start Universal Link deep link failed"
    )
    XCTAssertFalse(
      app.staticTexts["Home Page"].exists,
      "App remained on Home Page instead of navigating"
    )
  }

  @MainActor
  func testColdStartCustomScheme() throws {
    guard #available(iOS 16.4, *) else {
      throw XCTSkip("app.open(url) is only available on iOS 16.4+")
    }

    let app = XCUIApplication()
    let url = URL(string: "testscheme://flutter/custom_cold")!
    app.open(url)

    XCTAssertTrue(
      app.staticTexts["testscheme://flutter/custom_cold"].waitForExistence(timeout: 10),
      "Cold start Custom Scheme deep link failed"
    )
    XCTAssertFalse(
      app.staticTexts["Home Page"].exists,
      "App remained on Home Page instead of navigating"
    )
  }

  @MainActor
  func testWarmStartUniversalLink() throws {
    guard #available(iOS 16.4, *) else {
      throw XCTSkip("system.open(url) is only available on iOS 16.4+")
    }

    let app = XCUIApplication()
    app.launch()

    XCTAssertTrue(
      app.staticTexts["Home Page"].waitForExistence(timeout: 10),
      "Initial launch failed"
    )

    // Background the app before sending deep link to test warm start
    XCUIDevice.shared.press(.home)

    let url = URL(string: "https://flutter-dashboard.appspot.com/invalid_warm")!
    XCUIDevice.shared.system.open(url)

    XCTAssertTrue(
      app.staticTexts["https://flutter-dashboard.appspot.com/invalid_warm"].waitForExistence(timeout: 10),
      "Warm start Universal Link deep link failed"
    )
    XCTAssertFalse(
      app.staticTexts["Home Page"].exists,
      "App remained on Home Page instead of navigating"
    )
  }

  @MainActor
  func testWarmStartCustomScheme() throws {
    guard #available(iOS 16.4, *) else {
      throw XCTSkip("system.open(url) is only available on iOS 16.4+")
    }

    let app = XCUIApplication()
    app.launch()

    XCTAssertTrue(
      app.staticTexts["Home Page"].waitForExistence(timeout: 10),
      "Initial launch failed"
    )

    // Background the app before sending deep link to test warm start
    XCUIDevice.shared.press(.home)

    let url = URL(string: "testscheme://flutter/custom_warm")!
    XCUIDevice.shared.system.open(url)

    XCTAssertTrue(
      app.staticTexts["testscheme://flutter/custom_warm"].waitForExistence(timeout: 10),
      "Warm start Custom Scheme deep link failed"
    )
    XCTAssertFalse(
      app.staticTexts["Home Page"].exists,
      "App remained on Home Page instead of navigating"
    )
  }
}
