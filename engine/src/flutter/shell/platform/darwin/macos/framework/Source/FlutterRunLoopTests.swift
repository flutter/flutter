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
  func `perform(afterDelay:) executes in .common mode`(delay: TimeInterval) async throws {
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
  @MainActor
  func `perform schedules in flutter mode`(delay: TimeInterval) async throws {
    // Verify scheduled tasks executes in FlutterRunLoopMode (serviced by pollFlutterMessagesOnce()).
    var executedInFlutterMode = false
    runLoop.perform(afterDelay: delay) {
      executedInFlutterMode = true
    }
    #expect(!executedInFlutterMode)

    while !executedInFlutterMode {
      runLoop.pollFlutterMessagesOnce()
    }
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

  @Test
  func `nested perform calls execute successfully without deadlock`() async throws {
    await withCheckedContinuation { continuation in
      runLoop.perform {
        self.runLoop.perform {
          continuation.resume()
        }
      }
    }
  }
}

@Suite
struct UnsafeTaskQueueTests {
  typealias Task = FlutterRunLoop.Task

  @Test
  func `UnsafeTaskQueue sorts tasks by targetDate in ascending order`() throws {
    let queue = FlutterRunLoop.UnsafeTaskQueue()

    let task1 = Task(expiresAt: 5)
    let task2 = Task(expiresAt: 1)
    let task3 = Task(expiresAt: 3)

    _ = queue.add(task: task1)
    _ = queue.add(task: task2)
    _ = queue.add(task: task3)

    // task2 (1s), task3 (3s), task1 (5s)
    let (expired, _) = queue.popTasks(expiringBy: .distantFuture)
    #expect(expired.map(\.targetDate) == [task2.targetDate, task3.targetDate, task1.targetDate])
  }

  @Test
  func `UnsafeTaskQueue add and popTasks return the earliest fire date`() {
    let queue = FlutterRunLoop.UnsafeTaskQueue()

    // Adding Tasks
    #expect(queue.add(task: Task(expiresAt: 5)) == Date(5))  // Queue: [5s] -> Earliest: 5s
    #expect(queue.add(task: Task(expiresAt: 1)) == Date(1))  // Queue: [1s, 5s] -> Earliest: 1s
    #expect(queue.add(task: Task(expiresAt: 3)) == Date(1))  // Queue: [1s, 3s, 5s] -> Earliest: 1s

    // Poping tasks
    let (_, newFireDate1) = queue.popTasks(expiringBy: Date(2))
    #expect(newFireDate1 == Date(3))

    let (_, newFireDate2) = queue.popTasks(expiringBy: Date(4))
    #expect(newFireDate2 == Date(5))

    let (_, newFireDate3) = queue.popTasks(expiringBy: Date(6))
    #expect(newFireDate3 == .distantFuture)
  }

  @Test
  func `UnsafeTaskQueue popTasks only pops expired tasks and leaves unexpired tasks`() {
    let queue = FlutterRunLoop.UnsafeTaskQueue()

    let expiredTask = Task(expiresAt: 1)
    let unexpiredTask = Task(expiresAt: 5)

    _ = queue.add(task: expiredTask)
    _ = queue.add(task: unexpiredTask)

    let (expired, newFireDate) = queue.popTasks(expiringBy: Date(3))
    let expiredArray = Array(expired)

    #expect(expiredArray.count == 1)
    #expect(expiredArray.first?.targetDate == expiredTask.targetDate)
    #expect(newFireDate == unexpiredTask.targetDate)
  }

  @Test(arguments: [
    // Interleaved dates (B, A, C, B, A, C)
    (
      insertions: [
        Task(expiresAt: 2),
        Task(expiresAt: 1),
        Task(expiresAt: 3),
        Task(expiresAt: 2),
        Task(expiresAt: 1),
        Task(expiresAt: 3),
      ],
      expectedOrder: [2, 5, 1, 4, 3, 6]
    ),
    // Reverse dates (C, C, B, B, A, A)
    (
      insertions: [
        Task(expiresAt: 3),
        Task(expiresAt: 3),
        Task(expiresAt: 2),
        Task(expiresAt: 2),
        Task(expiresAt: 1),
        Task(expiresAt: 1),
      ],
      expectedOrder: [5, 6, 3, 4, 1, 2]
    ),
    // Already sorted dates (A, A, B, B, C, C)
    (
      insertions: [
        Task(expiresAt: 1),
        Task(expiresAt: 1),
        Task(expiresAt: 2),
        Task(expiresAt: 2),
        Task(expiresAt: 3),
        Task(expiresAt: 3),
      ],
      expectedOrder: [1, 2, 3, 4, 5, 6]
    ),
    // All same date (A, A, A, A, A, A)
    (
      insertions: [
        Task(expiresAt: 1),
        Task(expiresAt: 1),
        Task(expiresAt: 1),
        Task(expiresAt: 1),
        Task(expiresAt: 1),
        Task(expiresAt: 1),
      ],
      expectedOrder: [1, 2, 3, 4, 5, 6]
    ),
  ])
  @MainActor
  func `UnsafeTaskQueue preserves insertion order for tasks with the same targetDate`(
    testCase: (insertions: [Task], expectedOrder: [Int])
  ) throws {
    let queue = FlutterRunLoop.UnsafeTaskQueue()

    var executionOrder: [Int] = []

    for (index, task) in testCase.insertions.enumerated() {
      let id = index + 1
      _ = queue.add(task: Task(block: { executionOrder.append(id) }, targetDate: task.targetDate))
    }

    let (expired, _) = queue.popTasks(expiringBy: .distantFuture)
    for task in expired {
      task.block()
    }

    #expect(executionOrder == testCase.expectedOrder)
  }
}

// MARK: - Test Helpers

extension FlutterRunLoop.Task {
  fileprivate init(expiresAt targetDate: Int, block: @escaping @MainActor () -> Void = {}) {
    self.init(block: block, targetDate: Date(targetDate))
  }
}

extension Date {
  fileprivate init(_ seconds: Int) {
    self.init(timeIntervalSinceReferenceDate: Double(seconds))
  }
}
