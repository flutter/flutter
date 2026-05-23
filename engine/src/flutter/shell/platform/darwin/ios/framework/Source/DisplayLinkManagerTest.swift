// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XCTest

@testable import InternalFlutterSwift

class DisplayLinkManagerTest: XCTestCase {

  func testDisplayLinkManagerCanBeInstantiatedWithMockValues() {
    let manager = DisplayLinkManager(maxRefreshRateEnabled: true, refreshRate: 120.0)

    XCTAssertTrue(manager.maxRefreshRateEnabledOnIPhone)
    XCTAssertEqual(manager.displayRefreshRate, 120.0)
  }

  func testDisplayLinkManagerCanBeInstantiatedWithAlternateMockValues() {
    let manager = DisplayLinkManager(maxRefreshRateEnabled: false, refreshRate: 60.0)

    XCTAssertFalse(manager.maxRefreshRateEnabledOnIPhone)
    XCTAssertEqual(manager.displayRefreshRate, 60.0)
  }

  func testSharedInstanceReturnsAValidValue() {
    // Verify that the production shared instance does not crash when accessed in test environment.
    let shared = DisplayLinkManager.shared

    XCTAssertNotNil(shared)
    XCTAssertGreaterThan(shared.displayRefreshRate, 0.0)
  }

  func testUpdateCachedDisplayRefreshRateIsReflectedByTheGetter() {
    let manager = DisplayLinkManager(maxRefreshRateEnabled: true, refreshRate: 60.0)
    XCTAssertEqual(manager.displayRefreshRate, 60.0)

    manager.updateCachedDisplayRefreshRate(120.0)

    XCTAssertEqual(manager.displayRefreshRate, 120.0)
  }

  func testDisplayConfigurationNotificationsAreHandledWithoutCrashing() {
    let shared = DisplayLinkManager.shared
    let expectation = expectation(description: "Notification handlers ran on the main queue")

    NotificationCenter.default.post(name: UIScreen.modeDidChangeNotification, object: UIScreen.main)
    NotificationCenter.default.post(name: .NSProcessInfoPowerStateDidChange, object: nil)
    NotificationCenter.default.post(
      name: ProcessInfo.thermalStateDidChangeNotification, object: nil)
    NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
    DispatchQueue.main.async { expectation.fulfill() }
    wait(for: [expectation], timeout: 1.0)

    // UIScreen.main's reported refresh rate can't be swizzled from a test, so this only
    // confirms that the notification handlers run to completion without crashing or
    // deadlocking. The locking/storage behavior they rely on is covered directly by
    // testUpdateCachedDisplayRefreshRateIsReflectedByTheGetter above.
    XCTAssertGreaterThan(shared.displayRefreshRate, 0.0)
  }
}
