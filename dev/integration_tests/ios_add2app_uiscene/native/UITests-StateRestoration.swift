// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XCTest

final class NativeUIKitSwiftExperimentUITests: XCTestCase {

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  @MainActor
  func testStateRestoration() throws {
    let app = XCUIApplication()
    app.launch()

    let button = app.buttons["Next Page"].firstMatch
    XCTAssertTrue(button.waitForExistence(timeout: 5))
    button.tap()

    // Suspend the app and the stop it, then on next launch the state should be restored.
    // See https://developer.apple.com/documentation/uikit/restoring-your-app-s-state?#Test-state-restoration-on-a-device
    XCUIDevice.shared.press(.home)
    app.wait(for: XCUIApplication.State.runningBackgroundSuspended, timeout: 5)
    app.terminate()

    app.launch()
    let nextPageTitle = app.otherElements["Flutter Demo Second Page"].firstMatch
    XCTAssertTrue(nextPageTitle.waitForExistence(timeout: 5))
  }
}
