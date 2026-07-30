// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Testing

@testable import InternalFlutterSwift

extension TaskRunner {
  /// Runs `work` on this runner's thread and returns its result once complete.
  ///
  /// `VSyncClient` owns its `CADisplayLink` on the runner's thread. To prevent races, all
  /// interactions with it to happen via this call, and are dispatched to the owning thread, never
  /// invoked directly from the test thread.
  fileprivate func run<T>(_ work: @escaping () -> T) async -> T {
    await withCheckedContinuation { continuation in
      postTask {
        continuation.resume(returning: work())
      }
    }
  }
}

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
  @Test func realDisplayLinkVsyncTimestampsCorrect() async throws {
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

    await threadTaskRunner.run { vsyncClient.onDisplayLink(link) }

    // Since the display link is paused and has not delivered a frame yet, both timestamp and
    // targetTimestamp are 0.0. Verify the client synthesizes a valid target timestamp using the max
    // refresh rate.
    #expect(callbackStartTime > 0.0)
    #expect(abs((callbackTargetTime - callbackStartTime) - 1.0 / 60.0) <= 0.0001)
  }

  @Test func vsyncClientPreventsZeroRefreshRateDivision() async throws {
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

    await threadTaskRunner.run { vsyncClient.onDisplayLink(link) }

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

  @Test func setAllowPauseAfterVsyncCorrect() async throws {
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: 60.0
    ) { _, _ in }
    let link = try #require(vsyncClient.displayLink)

    let pausedWhenDisallowed = await threadTaskRunner.run { () -> Bool in
      vsyncClient.allowPauseAfterVsync = false
      vsyncClient.await()
      vsyncClient.onDisplayLink(link)
      return link.isPaused
    }
    #expect(pausedWhenDisallowed == false)

    let pausedWhenAllowed = await threadTaskRunner.run { () -> Bool in
      vsyncClient.allowPauseAfterVsync = true
      vsyncClient.await()
      vsyncClient.onDisplayLink(link)
      return link.isPaused
    }
    #expect(pausedWhenAllowed)
  }

  @Test func setCorrectVariableRefreshRates() async throws {
    let maxFrameRate: Double = 120.0
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: true,
      maxRefreshRate: maxFrameRate
    ) { _, _ in }
    let link = try #require(vsyncClient.displayLink)

    if #available(iOS 15.0, *) {
      let range = await threadTaskRunner.run { link.preferredFrameRateRange }
      #expect(abs(Double(range.maximum) - maxFrameRate) <= 0.1)
      #expect(abs(Double(range.preferred ?? 0) - maxFrameRate) <= 0.1)
      #expect(abs(Double(range.minimum) - maxFrameRate / 2) <= 0.1)
    } else {
      let framesPerSecond = await threadTaskRunner.run { link.preferredFramesPerSecond }
      #expect(abs(Double(framesPerSecond) - maxFrameRate) <= 0.1)
    }
  }

  @Test func doNotSetVariableRefreshRatesIfCADisableMinimumFrameDurationOnPhoneIsNotOn()
    async throws
  {
    let maxFrameRate: Double = 120.0
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: maxFrameRate
    ) { _, _ in }
    let link = try #require(vsyncClient.displayLink)

    if #available(iOS 15.0, *) {
      let range = await threadTaskRunner.run { link.preferredFrameRateRange }
      #expect(abs(Double(range.maximum)) <= 0.1)
      #expect(abs(Double(range.preferred ?? 0)) <= 0.1)
      #expect(abs(Double(range.minimum)) <= 0.1)
    } else {
      let framesPerSecond = await threadTaskRunner.run { link.preferredFramesPerSecond }
      #expect(abs(Double(framesPerSecond)) <= 0.1)
    }
  }

  @Test func awaitAndPauseWillWorkCorrectly() async throws {
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: 60.0
    ) { _, _ in }
    let link = try #require(vsyncClient.displayLink)

    let (initiallyPaused, pausedAfterAwait, pausedAfterPause) = await threadTaskRunner.run {
      () -> (Bool, Bool, Bool) in
      let initiallyPaused = link.isPaused
      vsyncClient.await()
      let pausedAfterAwait = link.isPaused
      vsyncClient.pause()
      let pausedAfterPause = link.isPaused
      return (initiallyPaused, pausedAfterAwait, pausedAfterPause)
    }

    #expect(initiallyPaused)
    #expect(pausedAfterAwait == false)
    #expect(pausedAfterPause)
  }

  @Test func releasesLinkOnInvalidation() async {
    weak var weakClient: VSyncClient?
    let (vsyncSignals, vsyncContinuation) = AsyncStream.makeStream(of: Void.self)

    // Scope the VSyncClient to a nested function so it is released on return.
    func awaitFirstVsyncThenInvalidate() async {
      let client = VSyncClient(
        taskRunner: threadTaskRunner,
        isVariableRefreshRateEnabled: false,
        maxRefreshRate: 60.0
      ) { _, _ in
        vsyncContinuation.yield()
      }
      weakClient = client

      await threadTaskRunner.run { client.await() }

      // Wait for the display link to deliver its first vsync on the runner's thread.
      var vsyncs = vsyncSignals.makeAsyncIterator()
      _ = await vsyncs.next()

      client.invalidate()
    }
    await awaitFirstVsyncThenInvalidate()

    // Flush the task queue to ensure the invalidate() dispatched to the runner on dealloc has run.
    await threadTaskRunner.run {}
    #expect(weakClient == nil)
  }

  @Test func deallocatesWithoutExplicitInvalidation() async {
    weak var weakClient: VSyncClient?

    // Scope the VSyncClient to a nested function so it is released on return.
    func create() {
      let client = VSyncClient(
        taskRunner: threadTaskRunner,
        isVariableRefreshRateEnabled: false,
        maxRefreshRate: 60.0
      ) { _, _ in }
      weakClient = client
    }
    create()

    // Flush the task queue to run the registration task dispatched in init. That task holds only a
    // weak reference to the client, so the client can dealloc.
    await threadTaskRunner.run {}
    #expect(weakClient == nil)
  }

  /// Verifies there is no retain cycle through the display-link → relay → client chain after
  /// the display server has taken ownership of the link. On iOS 27+, QuartzCore holds a
  /// `_CADisplayLinkAssertion` on registered links; a never-unpaused link may therefore
  /// outlive `VSyncClient` itself, which is expected.
  @Test func deallocatesAfterRegistrationCompletes() async {
    weak var weakClient: VSyncClient?

    // Scope the VSyncClient to a nested function so it is released on return.
    func createAndAwaitRegistration() async {
      let client = VSyncClient(
        taskRunner: threadTaskRunner,
        isVariableRefreshRateEnabled: false,
        maxRefreshRate: 60.0
      ) { _, _ in }
      weakClient = client

      // Flush the task queue to run the registration dispatched in init. This ensures registration
      // has completed before the strong reference is released.
      await threadTaskRunner.run {}
    }
    await createAndAwaitRegistration()

    #expect(weakClient == nil)
  }
}
