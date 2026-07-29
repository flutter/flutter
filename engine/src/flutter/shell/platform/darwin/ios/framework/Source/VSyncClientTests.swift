// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Testing

@testable import InternalFlutterSwift

@MainActor
struct VSyncClientTests {
  let threadTaskRunner = TaskRunnerTestHelper.makeTaskRunner(withLabel: "VSyncClientTest")

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
  @Test func realDisplayLinkVsyncTimestampsCorrect() throws {
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
    let link = try #require(vsyncClient.displayLink)

    vsyncClient.onDisplayLink(link)

    // Since the display link is paused and has not delivered a frame yet, both timestamp and
    // targetTimestamp are 0.0. Verify the client synthesizes a valid target timestamp using the max
    // refresh rate.
    #expect(callbackStartTime > 0.0)
    #expect(abs((callbackTargetTime - callbackStartTime) - 1.0 / 60.0) <= 0.0001)
  }

  @Test func vsyncClientPreventsZeroRefreshRateDivision() throws {
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
    let link = try #require(vsyncClient.displayLink)

    vsyncClient.onDisplayLink(link)

    #expect(callbackStartTime > 0.0)
    // Should fallback to effectiveRefreshRate of 60.0.
    #expect(abs((callbackTargetTime - callbackStartTime) - 1.0 / 60.0) <= 0.0001)
    #expect(callbackTargetTime.isNaN == false)
    #expect(callbackTargetTime.isInfinite == false)
  }

  @Test func refreshRatePropertyFallsBackToDefaultWhenInvalid() {
    // Initialize with 0.0 to simulate invalid state.
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: 0.0
    ) { _, _ in }

    // Should return default rate (60.0).
    #expect(vsyncClient.refreshRate == 60.0)
  }

  @Test func setAllowPauseAfterVsyncCorrect() throws {
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: 60.0
    ) { _, _ in }
    let link = try #require(vsyncClient.displayLink)

    vsyncClient.allowPauseAfterVsync = false
    vsyncClient.await()
    vsyncClient.onDisplayLink(link)
    #expect(link.isPaused == false)

    vsyncClient.allowPauseAfterVsync = true
    vsyncClient.await()
    vsyncClient.onDisplayLink(link)
    #expect(link.isPaused)
  }

  @Test func setCorrectVariableRefreshRates() throws {
    let maxFrameRate: Double = 120.0
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: true,
      maxRefreshRate: maxFrameRate
    ) { _, _ in }
    let link = try #require(vsyncClient.displayLink)

    if #available(iOS 15.0, *) {
      #expect(abs(Double(link.preferredFrameRateRange.maximum) - maxFrameRate) <= 0.1)
      #expect(abs(Double(link.preferredFrameRateRange.preferred ?? 0) - maxFrameRate) <= 0.1)
      #expect(abs(Double(link.preferredFrameRateRange.minimum) - maxFrameRate / 2) <= 0.1)
    } else {
      #expect(abs(Double(link.preferredFramesPerSecond) - maxFrameRate) <= 0.1)
    }
  }

  @Test func doNotSetVariableRefreshRatesIfCADisableMinimumFrameDurationOnPhoneIsNotOn() throws {
    let maxFrameRate: Double = 120.0
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: maxFrameRate
    ) { _, _ in }
    let link = try #require(vsyncClient.displayLink)

    if #available(iOS 15.0, *) {
      #expect(abs(Double(link.preferredFrameRateRange.maximum)) <= 0.1)
      #expect(abs(Double(link.preferredFrameRateRange.preferred ?? 0)) <= 0.1)
      #expect(abs(Double(link.preferredFrameRateRange.minimum)) <= 0.1)
    } else {
      #expect(abs(Double(link.preferredFramesPerSecond)) <= 0.1)
    }
  }

  @Test func awaitAndPauseWillWorkCorrectly() throws {
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: 60.0
    ) { _, _ in }
    let link = try #require(vsyncClient.displayLink)

    #expect(link.isPaused)
    vsyncClient.await()
    #expect(link.isPaused == false)
    vsyncClient.pause()
    #expect(link.isPaused)
  }

  @Test func releasesLinkOnInvalidation() {
    weak var weakClient: VSyncClient?

    autoreleasepool {
      let vsyncSignal = DispatchSemaphore(value: 0)
      let client = VSyncClient(
        taskRunner: threadTaskRunner,
        isVariableRefreshRateEnabled: false,
        maxRefreshRate: 60.0
      ) { _, _ in
        vsyncSignal.signal()
      }
      weakClient = client

      threadTaskRunner.postTask {
        client.await()
      }

      #expect(vsyncSignal.wait(timeout: .now() + 1.0) == .success)

      client.invalidate()
    }

    let backgroundThreadFlushed = DispatchSemaphore(value: 0)
    threadTaskRunner.postTask {
      backgroundThreadFlushed.signal()
    }

    #expect(backgroundThreadFlushed.wait(timeout: .now() + 1.0) == .success)
    #expect(weakClient == nil)
  }

  @Test func deallocatesWithoutExplicitInvalidation() {
    weak var weakClient: VSyncClient?

    autoreleasepool {
      let client = VSyncClient(
        taskRunner: threadTaskRunner,
        isVariableRefreshRateEnabled: false,
        maxRefreshRate: 60.0
      ) { _, _ in }
      weakClient = client
    }

    #expect(weakClient == nil)
  }

  /// Verifies there is no retain cycle through the display-link → relay → client chain after
  /// the display server has taken ownership of the link. On iOS 27+, QuartzCore holds a
  /// `_CADisplayLinkAssertion` on registered links; a never-unpaused link may therefore
  /// outlive `VSyncClient` itself, which is expected.
  @Test func deallocatesAfterRegistrationCompletes() {
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
      let registered = DispatchSemaphore(value: 0)
      threadTaskRunner.postTask { registered.signal() }
      #expect(registered.wait(timeout: .now() + 1.0) == .success)
    }

    #expect(weakClient == nil)
  }
}
