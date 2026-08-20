// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import Testing

@testable import InternalFlutterSwift

// The tests are serialized to prevent scheduled tasks from leaking into other
// tests.
@Suite(.serialized)
struct FlutterRunLoopTests {
  private let runLoop: FlutterRunLoop

  @MainActor
  init() {
    self.runLoop = .mainRunLoop
  }

  @Test(arguments: [0.0, 0.1])
  func `perform(afterDelay:) executes the given block`(delay: TimeInterval) async throws {
    await withCheckedContinuation { continuation in
      runLoop.perform(afterDelay: delay) {
        continuation.resume()
      }
    }
  }

  @Test
  func `pollFlutterMessagesOnce() executes scheduled tasks`() async throws {
    var executed = false
    runLoop.perform { executed = true }
    #expect(!executed)

    await MainActor.run(body: runLoop.pollFlutterMessagesOnce)
    #expect(executed)
  }

  @Test(arguments: [0.0, 0.1])
  func `perform schedules in both common and flutter modes`(delay: TimeInterval) async throws {
    // Verify scheduled tasks executes in .common mode (serviced by the main run loop automatically).
    await withCheckedContinuation { continuation in
      runLoop.perform(afterDelay: delay) {
        continuation.resume()
      }
    }

    // Verify scheduled tasks executes in FlutterRunLoopMode (serviced by pollFlutterMessagesOnce()).
    var executedInFlutterMode = false
    runLoop.perform(afterDelay: delay) {
      executedInFlutterMode = true
    }
    #expect(!executedInFlutterMode)
    await MainActor.run(body: runLoop.pollFlutterMessagesOnce)
    #expect(executedInFlutterMode)
  }

  @Test
  func `long running task does not hold the lock`() async throws {
    let task1CanFinish = DispatchSemaphore(value: 0)

    // Wait until task1 has actually started executing on the main thread.
    await withCheckedContinuation { continuation in
      runLoop.perform {
        continuation.resume()
        _ = task1CanFinish.wait(timeout: .now() + 5.0)
      }
    }

    // task1 is now actively executing its block on the main thread.
    // Adding new tasks from this test thread must not block while
    // task1 is running, otherwise this test deadlocks.
    runLoop.perform {}
    runLoop.perform(afterDelay: 1.0) {}

    // Stop task1.
    task1CanFinish.signal()
  }
}
