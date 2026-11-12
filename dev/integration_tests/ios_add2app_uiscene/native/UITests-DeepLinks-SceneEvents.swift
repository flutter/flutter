// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XCTest

final class NativeUIKitSwiftExperimentUITests: XCTestCase {

  override func setUp() {
    continueAfterFailure = false
  }

  @MainActor
  func testColdStartUniversalLink() throws {
    guard #available(iOS 16.4, *) else {
      throw XCTSkip("app.open(url) is only available on iOS 16.4+")
    }

    let app = XCUIApplication()
    let url = URL(string: "https://flutter-dashboard.appspot.com/cold")!
    app.open(url)

    let button = app.buttons["Get Lifecycle Events"].firstMatch
    XCTAssertTrue(button.waitForExistence(timeout: 10))
    button.tap()

    let expectedEvents = [
      "applicationDidFinishLaunchingWithOptions",
      "sceneWillConnect",
      "url:https://flutter-dashboard.appspot.com/cold",
      "sceneWillEnterForeground",
      "sceneDidBecomeActive",
    ]
    let eventsPredicate = NSPredicate(
      format: "label == %@",
      expectedEvents.joined(separator: "\n")
    )
    let eventsElement = app.staticTexts.element(matching: eventsPredicate)
    if !eventsElement.waitForExistence(timeout: 5) {
      let allLabels = app.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: "\n---\n")
      XCTFail("Cold start Universal Link lifecycle sequence failed. Actual:\n\(allLabels)")
    }
  }

  @MainActor
  func testColdStartCustomScheme() throws {
    guard #available(iOS 16.4, *) else {
      throw XCTSkip("app.open(url) is only available on iOS 16.4+")
    }

    let app = XCUIApplication()
    let url = URL(string: "testscheme://flutter/cold")!
    app.open(url)

    let button = app.buttons["Get Lifecycle Events"].firstMatch
    XCTAssertTrue(button.waitForExistence(timeout: 10))
    button.tap()

    let expectedEvents = [
      "applicationDidFinishLaunchingWithOptions",
      "sceneWillConnect",
      "url:testscheme://flutter/cold",
      "sceneWillEnterForeground",
      "sceneDidBecomeActive",
    ]
    let eventsPredicate = NSPredicate(
      format: "label == %@",
      expectedEvents.joined(separator: "\n")
    )
    let eventsElement = app.staticTexts.element(matching: eventsPredicate)
    if !eventsElement.waitForExistence(timeout: 5) {
      let allLabels = app.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: "\n---\n")
      XCTFail("Cold start Custom Scheme lifecycle sequence failed. Actual:\n\(allLabels)")
    }
  }

  @MainActor
  func testWarmStartUniversalLink() throws {
    guard #available(iOS 16.4, *) else {
      throw XCTSkip("system.open(url) is only available on iOS 16.4+")
    }

    let app = XCUIApplication()
    app.launch()

    let button = app.buttons["Get Lifecycle Events"].firstMatch
    XCTAssertTrue(button.waitForExistence(timeout: 10))

    // Background the app before sending deep link to test warm start
    XCUIDevice.shared.press(.home)

    let url = URL(string: "https://flutter-dashboard.appspot.com/warm")!
    XCUIDevice.shared.system.open(url)

    XCTAssertTrue(button.waitForExistence(timeout: 10))
    button.tap()

    let expectedEvents = [
      "applicationDidFinishLaunchingWithOptions",
      "sceneWillConnect",
      "sceneWillEnterForeground",
      "sceneDidBecomeActive",
      "sceneWillResignActive",
      "sceneDidEnterBackground",
      "sceneWillEnterForeground",
      "sceneContinueUserActivity",
      "url:https://flutter-dashboard.appspot.com/warm",
      "sceneDidBecomeActive",
    ]
    let eventsPredicate = NSPredicate(
      format: "label == %@",
      expectedEvents.joined(separator: "\n")
    )
    let eventsElement = app.staticTexts.element(matching: eventsPredicate)
    if !eventsElement.waitForExistence(timeout: 5) {
      let allLabels = app.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: "\n---\n")
      XCTFail("Warm start Universal Link lifecycle sequence failed. Actual:\n\(allLabels)")
    }
  }

  @MainActor
  func testWarmStartCustomScheme() throws {
    guard #available(iOS 16.4, *) else {
      throw XCTSkip("system.open(url) is only available on iOS 16.4+")
    }

    let app = XCUIApplication()
    app.launch()

    let button = app.buttons["Get Lifecycle Events"].firstMatch
    XCTAssertTrue(button.waitForExistence(timeout: 10))

    // Background the app before sending deep link to test warm start
    XCUIDevice.shared.press(.home)

    let url = URL(string: "testscheme://flutter/warm")!
    XCUIDevice.shared.system.open(url)

    XCTAssertTrue(button.waitForExistence(timeout: 10))
    button.tap()

    let expectedEvents = [
      "applicationDidFinishLaunchingWithOptions",
      "sceneWillConnect",
      "sceneWillEnterForeground",
      "sceneDidBecomeActive",
      "sceneWillResignActive",
      "sceneDidEnterBackground",
      "sceneOpenURLContexts",
      "url:testscheme://flutter/warm",
      "sceneWillEnterForeground",
      "sceneDidBecomeActive",
    ]
    let eventsPredicate = NSPredicate(
      format: "label == %@",
      expectedEvents.joined(separator: "\n")
    )
    let eventsElement = app.staticTexts.element(matching: eventsPredicate)
    if !eventsElement.waitForExistence(timeout: 5) {
      let allLabels = app.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: "\n---\n")
      XCTFail("Warm start Custom Scheme lifecycle sequence failed. Actual:\n\(allLabels)")
    }
  }
}
