// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import InternalFlutterSwift
import QuartzCore
import Testing

@MainActor
struct TaskRunnerTests {

  @Test func postTask() {
    let taskRunner = TaskRunnerTestHelper.makeCurrentThreadTaskRunner()

    var didRun = false
    taskRunner.postTask {
      didRun = true
    }

    #expect(runLoopUntil(timeout: 5.0) { didRun }, "Posted task did not run within timeout")
  }

  @Test func postDelayedTask() {
    let taskRunner = TaskRunnerTestHelper.makeCurrentThreadTaskRunner()

    var didRun = false
    var elapsed: CFTimeInterval = 0
    let startTime = CACurrentMediaTime()
    taskRunner.postTask(delay: 0.1) {
      elapsed = CACurrentMediaTime() - startTime
      didRun = true
    }

    #expect(runLoopUntil(timeout: 5.0) { didRun }, "Delayed task did not run within timeout")
    let epsilon = 0.001
    #expect(elapsed >= 0.1 - epsilon)
  }

  @Test func runsTasksOnCurrentThread() {
    let taskRunner = TaskRunnerTestHelper.makeCurrentThreadTaskRunner()

    #expect(taskRunner.runsTasksOnCurrentThread())
  }
}

/// Spins the current thread's run loop until `condition` returns true, or `timeout` elapses.
///
/// A current-thread `TaskRunner` posts to the current thread's `fml::MessageLoop`, which is backed
/// by the thread's run loop. That run loop must be actively run for posted tasks to execute, so we
/// pump it here rather than blocking. Returns true if the condition was met before the timeout.
@MainActor
private func runLoopUntil(
  timeout: TimeInterval,
  condition: () -> Bool
) -> Bool {
  let deadline = Date(timeIntervalSinceNow: timeout)
  while !condition() {
    if Date() >= deadline {
      return false
    }
    // `run(mode:before:)` immediately returns false when the run loop has no input sources or
    // timers to process. In that case, sleep to avoid spinning in a tight loop until the deadline.
    if !RunLoop.current.run(mode: .default, before: deadline) {
      Thread.sleep(forTimeInterval: 0.01)
    }
  }
  return true
}
