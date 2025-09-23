// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XCTest

final class xcode_uikit_swiftUITests: XCTestCase {

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false

    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
  }

  @MainActor
  func testLifecycleEvents() throws {
    let app = XCUIApplication()
    app.launch()
    let button = app.buttons["Get Lifecycle Events"].firstMatch
    XCTAssertTrue(button.waitForExistence(timeout: 5))
    button.tap()

    let expectedStartEvents = [
      "applicationDidFinishLaunchingWithOptions", "flutterViewDidConnect",
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
      "applicationDidFinishLaunchingWithOptions", "flutterViewDidConnect",
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
