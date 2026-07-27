// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XCTest

@testable import InternalFlutterSwift

class VSyncClientTest: XCTestCase {
  var threadTaskRunner: TaskRunner!

  override func setUp() {
    super.setUp()
    threadTaskRunner = TaskRunnerTestHelper.makeTaskRunner(withLabel: "VSyncClientTest")
  }

  override func tearDown() {
    threadTaskRunner = nil
    super.tearDown()
  }

  /// Verifies that the vsync client safely synthesizes a target timestamp when the display link's
  /// `targetTimestamp` is invalid (i.e. evaluates to 0.0).
  ///
  /// Apple's `CADisplayLink` documentation specifies:
  /// > "The targetTimestamp value is only valid after the display link has delivered at least one
  /// > frame. Before the first frame is delivered, or when the display link is paused, the value
  /// > of targetTimestamp is 0."
  ///
  /// Our vsync waiter operates on-demand in a request-and-pause cycle. This means every new frame
  /// sequence begins (e.g. in response to a gesture) with a paused-to-unpaused transition, causing
  /// the first callback to receive `targetTimestamp = 0.0`.
  ///
  /// Without a fallback, passing `targetTime = 0.0` downstream causes a negative presentation time
  /// when subtracted from the start time.
  ///
  /// This test passes a newly created, paused `CADisplayLink` (whose properties both evaluate to
  /// 0.0) and asserts that the client intercepts the invalid state and synthesizes a safe, positive
  /// next-frame target timestamp based on the display's maximum refresh rate.
  func testRealDisplayLinkVsyncTimestampsCorrect() {
    var callbackStartTime: CFTimeInterval = -1
    var callbackTargetTime: CFTimeInterval = -1
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: 60.0
    ) { startTime, targetTime in
      callbackStartTime = startTime
      callbackTargetTime = targetTime
    }
    let link = vsyncClient.displayLink!

    vsyncClient.onDisplayLink(link)

    // Since the display link is paused and has not delivered a frame yet, both timestamp and
    // targetTimestamp are 0.0. Verify the client synthesizes a valid target timestamp using the max
    // refresh rate.
    XCTAssertGreaterThan(callbackStartTime, 0.0)
    XCTAssertEqual(callbackTargetTime - callbackStartTime, 1.0 / 60.0, accuracy: 0.0001)
  }

  func testVsyncClientPreventsZeroRefreshRateDivision() {
    var callbackStartTime: CFTimeInterval = -1
    var callbackTargetTime: CFTimeInterval = -1
    // Initialize with maxRefreshRate = 0.0 to simulate uninitialized/zero max refresh rate.
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: 0.0
    ) { startTime, targetTime in
      callbackStartTime = startTime
      callbackTargetTime = targetTime
    }
    let link = vsyncClient.displayLink!

    vsyncClient.onDisplayLink(link)

    XCTAssertGreaterThan(callbackStartTime, 0.0)
    // Should fallback to effectiveRefreshRate of 60.0.
    XCTAssertEqual(callbackTargetTime - callbackStartTime, 1.0 / 60.0, accuracy: 0.0001)
    XCTAssertFalse(callbackTargetTime.isNaN)
    XCTAssertFalse(callbackTargetTime.isInfinite)
  }

  func testRefreshRatePropertyFallsBackToDefaultWhenInvalid() {
    // Initialize with 0.0 to simulate invalid state.
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: 0.0
    ) { _, _ in }

    // Should return default rate (60.0).
    XCTAssertEqual(vsyncClient.refreshRate, 60.0)
  }

  func testSetAllowPauseAfterVsyncCorrect() {
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: 60.0
    ) { _, _ in }
    let link = vsyncClient.displayLink!

    vsyncClient.allowPauseAfterVsync = false
    vsyncClient.await()
    vsyncClient.onDisplayLink(link)
    XCTAssertFalse(link.isPaused)

    vsyncClient.allowPauseAfterVsync = true
    vsyncClient.await()
    vsyncClient.onDisplayLink(link)
    XCTAssertTrue(link.isPaused)
  }

  func testSetCorrectVariableRefreshRates() {
    let maxFrameRate: Double = 120.0
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: true,
      maxRefreshRate: maxFrameRate
    ) { _, _ in }
    let link = vsyncClient.displayLink!

    if #available(iOS 15.0, *) {
      XCTAssertEqual(Double(link.preferredFrameRateRange.maximum), maxFrameRate, accuracy: 0.1)
      XCTAssertEqual(
        Double(link.preferredFrameRateRange.preferred ?? 0), maxFrameRate, accuracy: 0.1)
      XCTAssertEqual(Double(link.preferredFrameRateRange.minimum), maxFrameRate / 2, accuracy: 0.1)
    } else {
      XCTAssertEqual(Double(link.preferredFramesPerSecond), maxFrameRate, accuracy: 0.1)
    }
  }

  func testDoNotSetVariableRefreshRatesIfCADisableMinimumFrameDurationOnPhoneIsNotOn() {
    let maxFrameRate: Double = 120.0
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: maxFrameRate
    ) { _, _ in }
    let link = vsyncClient.displayLink!

    if #available(iOS 15.0, *) {
      XCTAssertEqual(Double(link.preferredFrameRateRange.maximum), 0, accuracy: 0.1)
      XCTAssertEqual(Double(link.preferredFrameRateRange.preferred ?? 0), 0, accuracy: 0.1)
      XCTAssertEqual(Double(link.preferredFrameRateRange.minimum), 0, accuracy: 0.1)
    } else {
      XCTAssertEqual(Double(link.preferredFramesPerSecond), 0, accuracy: 0.1)
    }
  }

  func testAwaitAndPauseWillWorkCorrectly() {
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: 60.0
    ) { _, _ in }
    let link = vsyncClient.displayLink!

    XCTAssertTrue(link.isPaused)
    vsyncClient.await()
    XCTAssertFalse(link.isPaused)
    vsyncClient.pause()
    XCTAssertTrue(link.isPaused)
  }

  func testReleasesLinkOnInvalidation() {
    let threadTaskRunner = TaskRunnerTestHelper.makeTaskRunner(withLabel: "FlutterVSyncClientTest")
    weak var weakClient: VSyncClient?

    autoreleasepool {
      let vsyncExpectation = expectation(description: "vsync")
      let client = VSyncClient(
        taskRunner: threadTaskRunner,
        isVariableRefreshRateEnabled: false,
        maxRefreshRate: 60.0
      ) { _, _ in
        vsyncExpectation.fulfill()
      }
      weakClient = client

      threadTaskRunner.postTask {
        client.await()
      }

      waitForExpectations(timeout: 1.0, handler: nil)

      client.invalidate()
    }

    let backgroundThreadFlushed = expectation(description: "Background thread flushed")
    threadTaskRunner.postTask {
      backgroundThreadFlushed.fulfill()
    }

    waitForExpectations(timeout: 1.0, handler: nil)
    XCTAssertNil(weakClient)
  }

  func testDeallocatesWithoutExplicitInvalidation() {
    let threadTaskRunner = TaskRunnerTestHelper.makeTaskRunner(withLabel: "VSyncClientTest")
    weak var weakClient: VSyncClient?

    autoreleasepool {
      let client = VSyncClient(
        taskRunner: threadTaskRunner,
        isVariableRefreshRateEnabled: false,
        maxRefreshRate: 60.0
      ) { _, _ in }
      weakClient = client
    }

    XCTAssertNil(weakClient)
  }

  /// Verifies there is no retain cycle through the display-link → relay → client chain after
  /// the display server has taken ownership of the link. On iOS 27+, QuartzCore holds a
  /// `_CADisplayLinkAssertion` on registered links; a never-unpaused link may therefore
  /// outlive `VSyncClient` itself, which is expected.
  func testDeallocatesAfterRegistrationCompletes() {
    let threadTaskRunner = TaskRunnerTestHelper.makeTaskRunner(withLabel: "VSyncClientTest")
    weak var weakClient: VSyncClient?

    autoreleasepool {
      let client = VSyncClient(
        taskRunner: threadTaskRunner,
        isVariableRefreshRateEnabled: false,
        maxRefreshRate: 60.0
      ) { _, _ in }

      weakClient = client

      // Registration is dispatched to the task runner in init. Post a barrier task after it
      // so we know registration has completed before deinit fires.
      let registerExpectation = expectation(description: "Wait for display link registration")
      threadTaskRunner.postTask { registerExpectation.fulfill() }
      waitForExpectations(timeout: 1.0, handler: nil)
    }

    XCTAssertNil(weakClient)
  }
}
