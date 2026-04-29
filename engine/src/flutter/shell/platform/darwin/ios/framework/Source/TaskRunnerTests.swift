// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import InternalFlutterSwift
import XCTest

class TaskRunnerTests: XCTestCase {

  func testPostTask() {
    let taskRunner = FlutterFMLTaskRunnerTestHelper.makeCurrentThreadTaskRunner()

    let expectation = self.expectation(description: "Task should be executed")
    taskRunner.postTask {
      expectation.fulfill()
    }

    waitForExpectations(timeout: 5.0, handler: nil)
  }
func testPostDelayedTask() {
  let taskRunner = FlutterFMLTaskRunnerTestHelper.makeCurrentThreadTaskRunner()

  let expectation = self.expectation(description: "Delayed task should be executed")
  let startTime = CACurrentMediaTime()
  taskRunner.postTask(delay: 0.1) {
    let endTime = CACurrentMediaTime()
    XCTAssertGreaterThanOrEqual(endTime - startTime, 0.1)
    expectation.fulfill()
  }

  waitForExpectations(timeout: 5.0, handler: nil)
}


  func testRunsTasksOnCurrentThread() {
    let taskRunner = FlutterFMLTaskRunnerTestHelper.makeCurrentThreadTaskRunner()

    XCTAssertTrue(taskRunner.runsTasksOnCurrentThread())
  }
}
