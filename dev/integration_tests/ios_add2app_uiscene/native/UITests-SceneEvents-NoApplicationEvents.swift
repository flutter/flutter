// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XCTest

final class NativeUIKitSwiftExperimentUITests: XCTestCase {

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  @MainActor
  func testLifecycleEvents() throws {
    let app = XCUIApplication()
    app.launch()
    let button = app.buttons["Get Lifecycle Events"].firstMatch
    XCTAssertTrue(button.waitForExistence(timeout: 5))
    button.tap()

    let expectedStartEvents = [
      "sceneWillConnect",
      "sceneWillEnterForeground", "sceneDidBecomeActive",
    ]
    let startEventsPredicate = NSPredicate(
      format: "label == %@",
      expectedStartEvents.joined(separator: "\n")
    )
    let startEventsElement = app.staticTexts.element(
      matching: startEventsPredicate
    )
    XCTAssertTrue(startEventsElement.waitForExistence(timeout: 5))

    // Background the app, then reactivate it and check the events again
    XCUIDevice.shared.press(.home)
    app.activate()
    XCTAssertTrue(button.waitForExistence(timeout: 5))
    button.tap()

    let expectedEventsAfterBackgroundAndReactivate = [
      "sceneWillConnect",
      "sceneWillEnterForeground", "sceneDidBecomeActive",
      "sceneWillResignActive", "sceneDidEnterBackground",
      "sceneWillEnterForeground", "sceneDidBecomeActive",
    ]
    let backgroundEventsPredicate = NSPredicate(
      format: "label == %@",
      expectedEventsAfterBackgroundAndReactivate.joined(separator: "\n")
    )
    let backgroundEventsElement = app.staticTexts.element(
      matching: backgroundEventsPredicate
    )
    XCTAssertTrue(backgroundEventsElement.waitForExistence(timeout: 5))
  }
}
