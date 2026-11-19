// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Testing

@testable import InternalFlutterSwift

@MainActor
@Suite struct DisplayLinkManagerTests {

  @Test func displayLinkManagerCanBeInstantiatedWithMockValues() {
    let manager = DisplayLinkManager(maxRefreshRateEnabled: true, refreshRate: 120.0)

    #expect(manager.maxRefreshRateEnabledOnIPhone)
    #expect(manager.displayRefreshRate == 120.0)
  }

  @Test func displayLinkManagerCanBeInstantiatedWithAlternateMockValues() {
    let manager = DisplayLinkManager(maxRefreshRateEnabled: false, refreshRate: 60.0)

    #expect(!manager.maxRefreshRateEnabledOnIPhone)
    #expect(manager.displayRefreshRate == 60.0)
  }

  @Test func sharedInstanceReturnsAValidValue() {
    // Verify that the production shared instance does not crash when accessed in test environment.
    let shared = DisplayLinkManager.shared

    #expect(shared.displayRefreshRate > 0.0)
  }

  @Test func settingDisplayRefreshRateIsReflectedByTheGetter() {
    let manager = DisplayLinkManager(maxRefreshRateEnabled: true, refreshRate: 60.0)
    #expect(manager.displayRefreshRate == 60.0)

    manager.displayRefreshRate = 120.0

    #expect(manager.displayRefreshRate == 120.0)
  }

  @Test func displayConfigurationNotificationsAreHandledWithoutCrashing() async {
    let shared = DisplayLinkManager.shared

    NotificationCenter.default.post(name: UIScreen.modeDidChangeNotification, object: UIScreen.main)
    NotificationCenter.default.post(name: .NSProcessInfoPowerStateDidChange, object: nil)
    NotificationCenter.default.post(
      name: ProcessInfo.thermalStateDidChangeNotification, object: nil)
    NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
    await withCheckedContinuation { continuation in
      DispatchQueue.main.async {
        continuation.resume()
      }
    }

    // UIScreen.main's reported refresh rate can't be swizzled from a test, so this only
    // confirms that the notification handlers run to completion without crashing or
    // deadlocking. The locking/storage behavior they rely on is covered directly by
    // settingDisplayRefreshRateIsReflectedByTheGetter above.
    #expect(shared.displayRefreshRate > 0.0)
  }
}
