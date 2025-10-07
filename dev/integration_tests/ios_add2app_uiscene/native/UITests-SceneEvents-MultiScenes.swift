// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XCTest

final class NativeUIKitSwiftExperimentUITests: XCTestCase {

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  @MainActor
  @available(iOS 26.0, *)
  func testMultipleScenes() throws {
    let app = XCUIApplication()
    app.terminate()
    app.launch()

    // Resize app so it's not full screen

    let springboardApp = XCUIApplication(
      bundleIdentifier: "com.apple.springboard"
    )
    let resizer = springboardApp.otherElements["resize-grabber"].firstMatch
    let start = resizer.coordinate(withNormalizedOffset: CGVectorMake(0, 0))
    let end = resizer.coordinate(withNormalizedOffset: CGVectorMake(-3, -3))
    start.press(forDuration: 1, thenDragTo: end)

    // Click button to create a new scene
    let createSceneButton = app.buttons["New Scene"].firstMatch
    XCTAssertTrue(createSceneButton.waitForExistence(timeout: 5))
    createSceneButton.tap()

    // Minimize one scene
    springboardApp.buttons[
      "window-controls:io.flutter.devicelab.xcode-uikit-swift"
    ].firstMatch.tap()
    springboardApp.buttons["Minimize-button"].firstMatch.tap()

    // Validate lifecycle events of original scene do not contain background event
    let buttons = app.buttons.matching(identifier: "Get Lifecycle Events")
    let originalSceneButton = buttons.element(boundBy: 1)
    originalSceneButton.tap()
    let expectedOriginalSceneEvents = [
      "sceneWillConnect",
      "sceneWillEnterForeground", "sceneDidBecomeActive",
      "sceneWillResignActive", "sceneDidBecomeActive",
      "sceneWillResignActive", "sceneDidBecomeActive",
    ]
    let originalSceneEventsPredicate = NSPredicate(
      format: "label == %@",
      expectedOriginalSceneEvents.joined(separator: "\n")
    )
    let originalSceneEvents = app.staticTexts.element(
      matching: originalSceneEventsPredicate
    )
    XCTAssertTrue(originalSceneEvents.waitForExistence(timeout: 5))

    // Reopen it
    springboardApp.icons["xcode_uikit_swift"].firstMatch.tap()
    let predicate = NSPredicate(format: "label CONTAINS 'xcode_uikit_swift'")
    let scenes = springboardApp.otherElements.matching(predicate)
    let newScene = scenes.element(boundBy: 0)
    let originalScene = scenes.element(boundBy: 1)
    newScene.tap()

    // Validate lifecycle events of new scene do contain background event
    let newSceneButton = buttons.element(boundBy: 0)
    XCTAssertTrue(newSceneButton.waitForExistence(timeout: 5))
    newSceneButton.tap()
    let expectedNewSceneEvents = [
      "sceneWillConnect",
      "sceneWillEnterForeground", "sceneDidBecomeActive",
      "sceneWillResignActive", "sceneDidEnterBackground",
      "sceneWillEnterForeground", "sceneDidBecomeActive",
    ]

    let newSceneEventsPredicate = NSPredicate(
      format: "label == %@",
      expectedNewSceneEvents.joined(separator: "\n")
    )
    let newSceneEvents = app.staticTexts.element(
      matching: newSceneEventsPredicate
    )
    XCTAssertTrue(newSceneEvents.waitForExistence(timeout: 5))
  }

  @MainActor
  func testLifecycleEvents() throws {
    let app = XCUIApplication()
    app.launch()
    let button = app.buttons["Get Lifecycle Events"].firstMatch
    XCTAssertTrue(button.waitForExistence(timeout: 5))
    button.tap()

    let expectedStartEvents = [
      "applicationDidFinishLaunchingWithOptions", "sceneWillConnect",
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
      "applicationDidFinishLaunchingWithOptions", "sceneWillConnect",
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
