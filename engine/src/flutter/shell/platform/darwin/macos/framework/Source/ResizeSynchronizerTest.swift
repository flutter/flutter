// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import InternalFlutterSwift
import Testing

// Tests for `ResizeSynchronizer`.
//
// `FlutterRunLoop` asserts that it be called on the main thread, and thus the main thread is,
// in effect, a source of implicit shared state/behaviour. Because `beginResize` is a blocking call
// performed on the main thread, we serialise to avoid potential interactions between tests.
@Suite("ResizeSynchronizer tests", .serialized)
struct ResizeSynchronizerTest {

  @MainActor
  @Test("performCommit callback executes when no resize is active")
  func testNotBlocked() async {
    FlutterRunLoop.ensureMainLoopInitialized()

    let synchronizer = ResizeSynchronizer()
    var didReceiveFrame = false

    // Call performCommit from raster thread during frame present.
    Thread.detachNewThread {
      synchronizer.performCommit(forSize: CGSize(width: 100, height: 100), afterDelay: 0) {
        didReceiveFrame = true
      }
    }

    // Ensure the task is processed within the timeout.
    do {
      try await waitForCondition("didReceiveFrame to be true", timeout: 1.0) { didReceiveFrame }
    } catch {
      // Record the timeout and bail out of the test.
      Issue.record("\(error)")
      return
    }
  }

  @MainActor
  @Test("beginResize does not invoke onTimeout if performCommit called with matching frame size")
  func testBeginResizeDoesNotTimeOutWithMatchingPerformCommit() async {
    FlutterRunLoop.ensureMainLoopInitialized()

    // Resize synchronizer must have presented a frame in order to block.
    let synchronizer = ResizeSynchronizer()
    var didReceiveFrame = false
    synchronizer.performCommit(forSize: CGSize(width: 10, height: 10), afterDelay: 0) {
      didReceiveFrame = true
    }
    do {
      try await waitForCondition("didReceiveFrame to be true", timeout: 1.0) { didReceiveFrame }
    } catch {
      // Record the timeout and bail out of the test.
      Issue.record("\(error)")
      return
    }

    var commit1 = false
    var commit2 = false
    var didTimeout = false
    let latch = DispatchSemaphore(value: 0)

    // Call performCommit from raster thread during frame present.
    Thread.detachNewThread {
      // Block until `beginResize` has been called.
      latch.wait()

      // First commit size DOES NOT match that passed to beginResize.
      synchronizer.performCommit(forSize: CGSize(width: 50, height: 100), afterDelay: 0) {
        commit1 = true
      }

      // Second commit size DOES match that passed to beginResize.
      synchronizer.performCommit(forSize: CGSize(width: 100, height: 100), afterDelay: 0) {
        commit2 = true
      }
    }

    // This call blocks until performCommit is called with matching size, or times out.
    synchronizer.beginResize(forSize: CGSize(width: 100, height: 100)) {
      // Unblock the raster thread by signaling the latch.
      latch.signal()
    } onTimeout: {
      didTimeout = true
    }

    // Verify beginResize did not timeout.
    #expect(
      didTimeout == false,
      "onTimeout was called even though performCommit was called with matching size")

    // Verify performCommit callbacks were invoked.
    #expect(commit1 == true)
    #expect(commit2 == true)
  }

  @MainActor
  @Test("beginResize invokes onTimeout if performCommit not called with matching frame size")
  func testBeginResizeDoesTimeOutWithoutMatchingPerformCommit() async {
    FlutterRunLoop.ensureMainLoopInitialized()

    // Resize synchronizer must have presented a frame in order to block.
    let synchronizer = ResizeSynchronizer()
    var didReceiveFrame = false
    synchronizer.performCommit(forSize: CGSize(width: 10, height: 10), afterDelay: 0) {
      didReceiveFrame = true
    }
    do {
      try await waitForCondition("didReceiveFrame to be true", timeout: 1.0) { didReceiveFrame }
    } catch {
      // Record the timeout and bail out of the test.
      Issue.record("\(error)")
      return
    }

    didReceiveFrame = false
    var didTimeout = false
    let latch = DispatchSemaphore(value: 0)

    // Call performCommit from raster thread during frame present.
    Thread.detachNewThread {
      // Block until `beginResize` has been called.
      latch.wait()

      // First commit size DOES NOT match that passed to beginResize.
      synchronizer.performCommit(forSize: CGSize(width: 50, height: 100), afterDelay: 0) {
        didReceiveFrame = true
      }
    }

    // This call blocks until performCommit is called with matching size, or times out.
    synchronizer.beginResize(forSize: CGSize(width: 100, height: 100)) {
      // Unblock the raster thread by signaling the latch.
      latch.signal()
    } onTimeout: {
      didTimeout = true
    }

    // Verify beginResize timed out.
    #expect(
      didTimeout == true,
      "onTimeout was not called even though performCommit was not called with matching size")

    // Verify performCommit callback was invoked.
    #expect(didReceiveFrame == true)
  }

  @MainActor
  @Test("shutDown unblocks an active beginResize and prevents future blocking")
  func testUnblocksOnShutdown() async {
    FlutterRunLoop.ensureMainLoopInitialized()
    let synchronizer = ResizeSynchronizer()

    // Resize synchronizer must have received one frame in order to block.
    var didReceiveFrame = false
    synchronizer.performCommit(forSize: CGSize(width: 10, height: 10), afterDelay: 0) {
      didReceiveFrame = true
    }
    do {
      try await waitForCondition("didReceiveFrame to be true", timeout: 1.0) { didReceiveFrame }
    } catch {
      // Record the timeout and bail out of the test.
      Issue.record("\(error)")
      return
    }

    // Block until we receive a performCommit with a matching frameSize.
    let latch = DispatchSemaphore(value: 0)
    Thread.detachNewThread {
      // Block until `beginResize` has been called, and signals the latch.
      latch.wait()

      synchronizer.shutDown()
    }

    synchronizer.beginResize(forSize: CGSize(width: 100, height: 100)) {
      // Unblock resize.
      latch.signal()
    }

    // Subsequent calls should not block.
    synchronizer.beginResize(forSize: CGSize(width: 100, height: 100)) {}
  }

}

// Returns when `condition` is true, or throws if it's not true at the expiration of `timeout`.
// Polls `FlutterRunLoop.mainRunLoop` to execute any posted tasks every `pollingInterval` seconds.
@MainActor
private func waitForCondition(
  _ description: String,
  timeout: TimeInterval,
  pollingInterval: TimeInterval = 0.01,
  condition: @escaping @MainActor () -> Bool
) async throws {
  let startTime = CFAbsoluteTimeGetCurrent()
  while !condition() {
    if CFAbsoluteTimeGetCurrent() - startTime > timeout {
      struct TimeoutError: Error, CustomStringConvertible {
        let message: String
        var description: String { message }
      }
      throw TimeoutError(message: "Timeout waiting for \(description) after \(timeout) seconds")
    }
    // Pump messages to ensure performCommit blocks execute.
    FlutterRunLoop.mainRunLoop.pollFlutterMessagesOnce()
    // Allow other tasks to run, avoid pegging the CPU.
    try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
  }
}
