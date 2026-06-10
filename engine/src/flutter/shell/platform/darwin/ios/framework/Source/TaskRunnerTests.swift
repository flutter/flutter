// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import InternalFlutterSwift
import Testing

@MainActor
@Suite struct TaskRunnerTests {

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
    let taskRunner = TaskRunnerTestHelper.makeCurrentThreadTaskRunner()

    #expect(taskRunner.runsTasksOnCurrentThread())
  }
}
