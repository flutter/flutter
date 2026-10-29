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

    // Unmigrated plugins receive applicationDidFinishLaunchingWithOptions twice on cold start:
    // once during plugin registration with FlutterEngine, and once when FlutterAppDelegate forwards it.
    let expectedEvents = [
      "applicationDidFinishLaunchingWithOptions",
      "applicationDidFinishLaunchingWithOptions",
      "url:https://flutter-dashboard.appspot.com/cold",
      "applicationWillEnterForeground",
      "applicationDidBecomeActive",
    ]
    let eventsPredicate = NSPredicate(
      format: "label == %@",
      expectedEvents.joined(separator: "\n")
    )
    let eventsElement = app.staticTexts.element(matching: eventsPredicate)
    if !eventsElement.waitForExistence(timeout: 5) {
      let allLabels = app.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: "\n---\n")
      XCTFail("Cold start Universal Link fallback lifecycle sequence failed. Actual:\n\(allLabels)")
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

    // Unmigrated plugins receive applicationDidFinishLaunchingWithOptions twice on cold start:
    // once during plugin registration with FlutterEngine, and once when FlutterAppDelegate forwards it.
    let expectedEvents = [
      "applicationDidFinishLaunchingWithOptions",
      "applicationDidFinishLaunchingWithOptions",
      "url:testscheme://flutter/cold",
      "applicationWillEnterForeground",
      "applicationDidBecomeActive",
    ]
    let eventsPredicate = NSPredicate(
      format: "label == %@",
      expectedEvents.joined(separator: "\n")
    )
    let eventsElement = app.staticTexts.element(matching: eventsPredicate)
    if !eventsElement.waitForExistence(timeout: 5) {
      let allLabels = app.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: "\n---\n")
      XCTFail("Cold start Custom Scheme fallback lifecycle sequence failed. Actual:\n\(allLabels)")
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

    // On warm start, the app was already launched so applicationDidFinishLaunchingWithOptions
    // is only logged once. The deep link resumes the backgrounded app via scene continuation.
    let expectedEvents = [
      "applicationDidFinishLaunchingWithOptions",
      "applicationWillEnterForeground",
      "applicationDidBecomeActive",
      "applicationWillResignActive",
      "applicationDidEnterBackground",
      "applicationWillEnterForeground",
      "applicationContinueUserActivity",
      "url:https://flutter-dashboard.appspot.com/warm",
      "applicationDidBecomeActive",
    ]
    let eventsPredicate = NSPredicate(
      format: "label == %@",
      expectedEvents.joined(separator: "\n")
    )
    let eventsElement = app.staticTexts.element(matching: eventsPredicate)
    if !eventsElement.waitForExistence(timeout: 5) {
      let allLabels = app.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: "\n---\n")
      XCTFail("Warm start Universal Link fallback lifecycle sequence failed. Actual:\n\(allLabels)")
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

    // On warm start, applicationDidFinishLaunchingWithOptions was only logged once during initial launch.
    // The custom scheme deep link resumes the backgrounded app via openURL.
    let expectedEvents = [
      "applicationDidFinishLaunchingWithOptions",
      "applicationWillEnterForeground",
      "applicationDidBecomeActive",
      "applicationWillResignActive",
      "applicationDidEnterBackground",
      "applicationOpenURL",
      "url:testscheme://flutter/warm",
      "applicationWillEnterForeground",
      "applicationDidBecomeActive",
    ]
    let eventsPredicate = NSPredicate(
      format: "label == %@",
      expectedEvents.joined(separator: "\n")
    )
    let eventsElement = app.staticTexts.element(matching: eventsPredicate)
    if !eventsElement.waitForExistence(timeout: 5) {
      let allLabels = app.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: "\n---\n")
      XCTFail("Warm start Custom Scheme fallback lifecycle sequence failed. Actual:\n\(allLabels)")
    }
  }
}
