// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import InternalFlutterSwift
import Testing

// The TaskRunner API relies on CFRunLoop.
// `@MainActor` makes sure the test subject TaskRunner can use the main thread
// run loop which tests do not have to manually pump.
@MainActor
@Suite struct TaskRunnerTests {
  let taskRunner: TaskRunner = TaskRunnerTestHelper.makeCurrentThreadTaskRunner()

  @Test func postTask() async {
    await withCheckedContinuation { continuation in
      taskRunner.postTask {
        continuation.resume()
      }
    }
  }

  @Test func postDelayedTask() async {
    let startTime = CACurrentMediaTime()
    await withCheckedContinuation { continuation in
      taskRunner.postTask(delay: 0.1) {
        let endTime = CACurrentMediaTime()
        let epsilon = 0.001
        #expect(endTime - startTime >= 0.1 - epsilon)
        continuation.resume()
      }
    }
  }

  @Test func runsTasksOnCurrentThread() {
    #expect(taskRunner.runsTasksOnCurrentThread())
  }
}
