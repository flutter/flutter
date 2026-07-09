// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import InternalFlutterSwift
import Testing

@MainActor
@Suite struct TaskRunnerTests {

  @Test(.timeLimit(.minutes(1)))
  func postTask() async {
    let taskRunner = TaskRunnerTestHelper.makeCurrentThreadTaskRunner()

    await confirmation { confirm in
      taskRunner.postTask(confirm)
    }
  }

  @Test(.timeLimit(.minutes(1)))
  func postDelayedTask() async {
    let taskRunner = TaskRunnerTestHelper.makeCurrentThreadTaskRunner()

    let startTime = CACurrentMediaTime()
    await confirmation { confirm in
      taskRunner.postTask(delay: 0.1) {
        let endTime = CACurrentMediaTime()
        let epsilon = 0.001
        #expect(endTime - startTime >= 0.1 - epsilon)
        confirm()
      }
    }
  }

  @Test func runsTasksOnCurrentThread() {
    let taskRunner = TaskRunnerTestHelper.makeCurrentThreadTaskRunner()

    #expect(taskRunner.runsTasksOnCurrentThread())
  }
}
