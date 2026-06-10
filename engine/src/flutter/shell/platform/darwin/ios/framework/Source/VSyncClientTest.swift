// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Testing

@testable import InternalFlutterSwift

@Suite struct VSyncClientTests {
  private let threadTaskRunner: TaskRunner

  init() {
    threadTaskRunner = TaskRunnerTestHelper.makeTaskRunner(withLabel: "VSyncClientTest")
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
  @Test func realDisplayLinkVsyncTimestampsCorrect() {
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
    #expect(callbackStartTime > 0.0)
    #expect(abs(callbackTargetTime - callbackStartTime - 1.0 / 60.0) < 0.0001)
  }

  @Test func vsyncClientPreventsZeroRefreshRateDivision() {
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

    #expect(callbackStartTime > 0.0)
    // Should fallback to effectiveRefreshRate of 60.0.
    #expect(abs(callbackTargetTime - callbackStartTime - 1.0 / 60.0) < 0.0001)
    #expect(!callbackTargetTime.isNaN)
    #expect(!callbackTargetTime.isInfinite)
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

  @Test func setAllowPauseAfterVsyncCorrect() {
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: 60.0
    ) { _, _ in }
    let link = vsyncClient.displayLink!

    vsyncClient.allowPauseAfterVsync = false
    vsyncClient.await()
    vsyncClient.onDisplayLink(link)
    #expect(!link.isPaused)

    vsyncClient.allowPauseAfterVsync = true
    vsyncClient.await()
    vsyncClient.onDisplayLink(link)
    #expect(link.isPaused)
  }

  @Test func setCorrectVariableRefreshRates() {
    let maxFrameRate: Double = 120.0
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: true,
      maxRefreshRate: maxFrameRate
    ) { _, _ in }
    let link = vsyncClient.displayLink!

    if #available(iOS 15.0, *) {
      #expect(abs(Double(link.preferredFrameRateRange.maximum) - maxFrameRate) < 0.1)
      #expect(abs(Double(link.preferredFrameRateRange.preferred ?? 0) - maxFrameRate) < 0.1)
      #expect(abs(Double(link.preferredFrameRateRange.minimum) - maxFrameRate / 2) < 0.1)
    } else {
      #expect(abs(Double(link.preferredFramesPerSecond) - maxFrameRate) < 0.1)
    }
  }

  @Test func doNotSetVariableRefreshRatesIfCADisableMinimumFrameDurationOnPhoneIsNotOn() {
    let maxFrameRate: Double = 120.0
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: maxFrameRate
    ) { _, _ in }
    let link = vsyncClient.displayLink!

    if #available(iOS 15.0, *) {
      #expect(abs(Double(link.preferredFrameRateRange.maximum)) < 0.1)
      #expect(abs(Double(link.preferredFrameRateRange.preferred ?? 0)) < 0.1)
      #expect(abs(Double(link.preferredFrameRateRange.minimum)) < 0.1)
    } else {
      #expect(abs(Double(link.preferredFramesPerSecond)) < 0.1)
    }
  }

  @Test func awaitAndPauseWillWorkCorrectly() {
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: 60.0
    ) { _, _ in }
    let link = vsyncClient.displayLink!

    #expect(link.isPaused)
    vsyncClient.await()
    #expect(!link.isPaused)
    vsyncClient.pause()
    #expect(link.isPaused)
  }

  @Test func releasesLinkOnInvalidation() async {
    let threadTaskRunner = TaskRunnerTestHelper.makeTaskRunner(withLabel: "FlutterVSyncClientTest")
    weak var weakClient: VSyncClient?

    var client: VSyncClient?

    await withCheckedContinuation { continuation in
      autoreleasepool {
        client = VSyncClient(
          taskRunner: threadTaskRunner,
          isVariableRefreshRateEnabled: false,
          maxRefreshRate: 60.0
        ) { _, _ in
          continuation.resume()
        }
        weakClient = client

        threadTaskRunner.postTask {
          client?.await()
        }
      }
    }

    autoreleasepool {
      client?.invalidate()
      client = nil
    }

    await withCheckedContinuation { continuation in
      threadTaskRunner.postTask {
        continuation.resume()
      }
    }

    #expect(weakClient == nil)
  }

  @Test func deallocatesWithoutExplicitInvalidation() {
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

    #expect(weakClient == nil)
  }

  /// Verifies that when `VSyncClient` is deallocated, and its display link is successfully
  /// invalidated and deallocated on the thread where it was created.
  ///
  /// Since `deinit` can run on an arbitrary thread, calling `CADisplayLink.invalidate()` directly
  /// from `deinit` violates Apple's thread-affinity contract (invalidation must happen on the
  /// registering thread). If this fails, the run loop will strongly retain and leak both the
  /// display link and the relay.
  @MainActor
  @Test func displayLinkIsDeallocatedOnTaskRunnerThread() async {
    let threadTaskRunner = TaskRunnerTestHelper.makeTaskRunner(withLabel: "VSyncClientTest")
    weak var weakClient: VSyncClient?
    weak var weakDisplayLink: CADisplayLink?

    var client: VSyncClient?
    autoreleasepool {
      client = VSyncClient(
        taskRunner: threadTaskRunner,
        isVariableRefreshRateEnabled: false,
        maxRefreshRate: 60.0
      ) { _, _ in }

      weakClient = client
      weakDisplayLink = client?.displayLink
    }

    // Ensure the display link is added to the run loop on the task runner thread.
    await withCheckedContinuation { continuation in
      threadTaskRunner.postTask {
        continuation.resume()
      }
    }

    // Deallocate on the main (test) thread. deinit calls invalidate(), which must post the
    // invalidation task to the task runner.
    autoreleasepool {
      client = nil
    }
    #expect(weakClient == nil)

    // Flush the task runner queue to ensure invalidation executes on the task runner thread.
    await withCheckedContinuation { continuation in
      threadTaskRunner.postTask {
        continuation.resume()
      }
    }

    // If the invalidation succeeded on the correct thread, the run loop dropped its strong
    // reference, and the display link must have been deallocated.
    #expect(weakDisplayLink == nil)
  }
}
