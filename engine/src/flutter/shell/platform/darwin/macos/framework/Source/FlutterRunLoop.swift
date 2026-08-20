// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

/// Scheduling tasks on the main thread run loop, potentially with a delay.
///
/// This implementation does not guarantee the order of execution between tasks.
/// In other words, a task may run before another task with an earlier fire date.
///
/// The main difference between using `FlutterRunLoop` to schedule tasks compared
/// to `DispatchQueue.async` or `RunLoop.perform(_:)` is that `FlutterRunLoop`
/// schedules the task in both common run loop mode and a private run loop mode,
/// which allows it to run in a mode where it only processes Flutter messages
/// (`pollFlutterMessagesOnce()`).
@objc final class FlutterRunLoop: NSObject, Sendable {
  private static let flutterRunLoopMode = RunLoop.Mode("FlutterRunLoopMode")
  private static let flutterCFRunLoopMode = flutterRunLoopMode.cfRunLoopMode

  @objc @MainActor
  static let mainRunLoop = FlutterRunLoop()
  private let lockScope = LockScope()
  private let runLoop = SendableCFRunLoop()

  @MainActor
  private override init() {
    super.init()
    // The timer will not be explicitly invalidated, as the `.mainRunLoop` static
    // variable has the same lifespan as the program.
    runLoop.add(timer: lockScope.timer, forModes: [.common, Self.flutterRunLoopMode])
  }

  /// Schedules a block to be executed on the main thread after the given delay.
  @objc func perform(afterDelay delay: TimeInterval = 0, block: @MainActor @escaping () -> Void) {
    if delay > 0 {
      let task = LockScope.Task(block: block, targetDate: .now + delay)
      lockScope.addTaskAndRearm(task)
    } else {
      runLoop.perform(inModes: [.common, Self.flutterRunLoopMode]) { [self] in
        MainActor.assumeIsolated {
          for task in lockScope.popExpiredTasksAndRearm() {
            task.block()
          }
          // This class does not guarantee the execution order of expired tasks.
          block()
        }
      }
    }
  }

  /// Schedules a block to be executed on the main thread. This method is Objective-C only.
  @available(swift, obsoleted: 1.0)
  @objc func performBlock(_ block: @MainActor @escaping () -> Void) {
    perform(block: block)
  }

  /// Executes single iteration of the run loop in the mode where only Flutter
  /// messages are processed.
  ///
  /// Must be called on the main thread.
  @MainActor
  @objc func pollFlutterMessagesOnce() {
    CFRunLoopRunInMode(Self.flutterCFRunLoopMode, 0.1, true)
  }
}

/// A Sendable class that synchronizes non-thead-safe calls using a NSLock.
private final class LockScope: @unchecked Sendable {
  private let lock = NSLock()
  private let unsafeTaskQueue = UnsafeTaskQueue()
  let timer: Timer

  init() {
    self.timer = Timer(
      fire: .distantFuture,
      interval: .greatestFiniteMagnitude,
      repeats: false
    ) { [lock, unsafeTaskQueue] timer in
      MainActor.assumeIsolated {
        for task in LockScope.popExpiredTasksAndRearm(
          lock: lock, unsafeTaskQueue: unsafeTaskQueue, timer: timer)
        {
          task.block()
        }
      }
    }
  }

  /// Adds the given task to the task queue and updates the Timer's fire date
  /// accordingly.
  func addTaskAndRearm(_ task: Task) {
    lock.withLock {
      timer.fireDate = unsafeTaskQueue.add(task: task)
    }
  }

  private static func popExpiredTasksAndRearm(
    lock: NSLock, unsafeTaskQueue: UnsafeTaskQueue, timer: Timer
  ) -> [Task] {
    lock.withLock {
      let (tasks, newFireDate) = unsafeTaskQueue.popTasks(expiringBy: .now)
      timer.fireDate = newFireDate
      return tasks
    }
  }

  /// Pops all expired tasks from the task queue and updates the Timer's fire date.
  ///
  /// Returns an unsorted array of all expired tasks popped from the task queue.
  @MainActor
  func popExpiredTasksAndRearm() -> [Task] {
    Self.popExpiredTasksAndRearm(lock: lock, unsafeTaskQueue: unsafeTaskQueue, timer: timer)
  }
}

extension LockScope {
  struct Task {
    let block: @MainActor () -> Void
    let targetDate: Date
  }

  final class UnsafeTaskQueue {
    // Unsorted task queue.
    private var tasks: [Task] = []
    private var earliestDeadline: Date = .distantFuture

    func add(task: Task) -> Date {
      tasks.append(task)
      earliestDeadline = min(earliestDeadline, task.targetDate)
      return earliestDeadline
    }

    // Returns an unordered list of expired tasks, and the new earliest deadline.
    func popTasks(
      expiringBy date: Date,
    ) -> ([Task], Date) {
      guard date >= earliestDeadline else {
        return ([], earliestDeadline)
      }

      var newQueue: [Task] = []
      var newEarliestDeadline = Date.distantFuture
      var expiredTasks: [Task] = []

      for task in tasks {
        if task.targetDate <= date {
          expiredTasks.append(task)
        } else {
          newQueue.append(task)
          newEarliestDeadline = min(newEarliestDeadline, task.targetDate)
        }
      }

      earliestDeadline = newEarliestDeadline
      tasks = newQueue
      return (expiredTasks, earliestDeadline)
    }
  }
}

// According to Apple's Threading Programming Guide, Unlike NSRunLoop,
// CFRunLoop APIs are "generally" thread-safe, but
// "If you are performing operations that alter the configuration of the run loop,
// however, it is still good practice to do so from the thread that owns the run loop
// whenever possible."
private final class SendableCFRunLoop: @unchecked Sendable {
  private let runLoop: CFRunLoop = CFRunLoopGetCurrent()

  // Calls CFRunLoopPerformBlock on the run loop and then wakes up the run loop.
  func perform(inModes modes: [RunLoop.Mode], block: @escaping @Sendable () -> Void) {
    let cfModes = modes.map { $0.cfRunLoopMode } as NSArray
    CFRunLoopPerformBlock(runLoop, cfModes, block)
    CFRunLoopWakeUp(runLoop)
  }

  func add(timer: Timer, forModes modes: [RunLoop.Mode]) {
    for mode in modes {
      CFRunLoopAddTimer(runLoop, timer, mode.cfRunLoopMode)
    }
  }

}

extension RunLoop.Mode {
  fileprivate var cfRunLoopMode: CFRunLoopMode {
    switch self {
    case .default: .defaultMode
    case .common: .commonModes
    case let mode: CFRunLoopMode(mode.rawValue as CFString)
    }
  }
}
