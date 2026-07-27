// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import InternalFlutterSwift
import QuartzCore
import Testing

// A current-thread `TaskRunner` posts to the current thread's `fml::MessageLoop`, which is backed by
// the thread's run loop. `@MainActor` binds the runner to the main thread, whose run loop the test
// host keeps running; each `await` yields to that run loop so posted tasks execute without manual
// pumping.
@MainActor
struct TaskRunnerTests {

  @Test func postTask() async {
    let taskRunner = TaskRunnerTestHelper.makeCurrentThreadTaskRunner()

    await withCheckedContinuation { continuation in
      taskRunner.postTask {
        continuation.resume()
      }
    }
  }

  @Test func postDelayedTask() async {
    let taskRunner = TaskRunnerTestHelper.makeCurrentThreadTaskRunner()

    var elapsed: CFTimeInterval = 0
    let startTime = CACurrentMediaTime()
    await withCheckedContinuation { continuation in
      taskRunner.postTask(delay: 0.1) {
        elapsed = CACurrentMediaTime() - startTime
        continuation.resume()
      }
    }

    let epsilon = 0.001
    #expect(elapsed >= 0.1 - epsilon)
  }

  @Test func runsTasksOnCurrentThread() {
    let taskRunner = TaskRunnerTestHelper.makeCurrentThreadTaskRunner()

    #expect(taskRunner.runsTasksOnCurrentThread())
  }
}
