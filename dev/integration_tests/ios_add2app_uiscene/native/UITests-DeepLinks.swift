// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XCTest

final class NativeUIKitSwiftExperimentUITests: XCTestCase {

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  @MainActor
  func testDeepLinks() throws {
    guard #available(iOS 16.4, *) else {
      throw XCTSkip("app.open(url) is only available on iOS 16.4+")
    }

    var app = XCUIApplication()
    app.launch()
    let button = app.buttons["Get Lifecycle Events"].firstMatch
    XCTAssertTrue(button.waitForExistence(timeout: 10))

    // 1. Warm start Universal Link
    var url = URL(string: "https://flutter-dashboard.appspot.com/warm")!
    app.open(url)
    XCTAssertTrue(button.waitForExistence(timeout: 10))
    button.tap()

    let warmText = app.staticTexts.element(
      matching: NSPredicate(format: "label CONTAINS 'url:https://flutter-dashboard.appspot.com/warm'")
    )
    for _ in 0..<10 {
      if warmText.exists {
        break
      }
      button.tap()
      sleep(1)
    }
    XCTAssertTrue(warmText.exists, "Warm start Universal Link failed")
    let warmOccurrences = warmText.label.components(separatedBy: "url:https://flutter-dashboard.appspot.com/warm").count - 1
    XCTAssertEqual(warmOccurrences, 1, "Warm start Universal Link should be received exactly once")

    // 2. Cold start Universal Link
    app.terminate()
    app = XCUIApplication()
    url = URL(string: "https://flutter-dashboard.appspot.com/cold")!
    app.open(url)
    XCTAssertTrue(button.waitForExistence(timeout: 10))
    button.tap()

    let coldText = app.staticTexts.element(
      matching: NSPredicate(format: "label CONTAINS 'url:https://flutter-dashboard.appspot.com/cold'")
    )
    for _ in 0..<10 {
      if coldText.exists {
        break
      }
      button.tap()
      sleep(1)
    }
    XCTAssertTrue(coldText.exists, "Cold start Universal Link failed")
    let coldOccurrences = coldText.label.components(separatedBy: "url:https://flutter-dashboard.appspot.com/cold").count - 1
    XCTAssertEqual(coldOccurrences, 1, "Cold start Universal Link should be received exactly once")

    // 3. Warm start Custom Scheme
    url = URL(string: "testscheme://flutter/warm")!
    app.open(url)
    XCTAssertTrue(button.waitForExistence(timeout: 10))
    button.tap()

    let warmCustomText = app.staticTexts.element(
      matching: NSPredicate(format: "label CONTAINS 'url:testscheme://flutter/warm'")
    )
    for _ in 0..<10 {
      if warmCustomText.exists {
        break
      }
      button.tap()
      sleep(1)
    }
    XCTAssertTrue(warmCustomText.exists, "Warm start Custom Scheme failed")
    let warmCustomOccurrences = warmCustomText.label.components(separatedBy: "url:testscheme://flutter/warm").count - 1
    XCTAssertEqual(warmCustomOccurrences, 1, "Warm start Custom Scheme should be received exactly once")

    // 4. Cold start Custom Scheme
    app.terminate()
    app = XCUIApplication()
    url = URL(string: "testscheme://flutter/cold")!
    app.open(url)
    XCTAssertTrue(button.waitForExistence(timeout: 10))
    button.tap()

    let coldCustomText = app.staticTexts.element(
      matching: NSPredicate(format: "label CONTAINS 'url:testscheme://flutter/cold'")
    )
    for _ in 0..<10 {
      if coldCustomText.exists {
        break
      }
      button.tap()
      sleep(1)
    }
    XCTAssertTrue(coldCustomText.exists, "Cold start Custom Scheme failed")
    let coldCustomOccurrences = coldCustomText.label.components(separatedBy: "url:testscheme://flutter/cold").count - 1
    XCTAssertEqual(coldCustomOccurrences, 1, "Cold start Custom Scheme should be received exactly once")
  }
}
