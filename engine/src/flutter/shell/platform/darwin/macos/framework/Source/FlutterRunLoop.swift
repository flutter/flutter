// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

/// Scheduling tasks on the main thread run loop, potentially with a delay.
///
/// If no tasks with negative delays are posted, this class guarantees the order
/// of execution between tasks. In other words, tasks with earlier fire dates
/// always run before tasks with later fire dates.
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
    // The timer will not be invalidated, as the `.mainRunLoop` static
    // variable will never be deallocated once initialized.
    runLoop.add(timer: lockScope.timer, forModes: [.common, Self.flutterRunLoopMode])
  }

  /// Schedules a block to be executed on the main thread after the given delay.
  @objc func perform(afterDelay delay: TimeInterval = 0, block: @MainActor @escaping () -> Void) {
    let task = FlutterRunLoop.Task(block: block, targetDate: Date() + delay)
    lockScope.addTaskAndRearmTimer(task: task)
    if delay == 0 {
      // Wake up the runloop immediately for delay == 0 tasks so they are not affected
      // by timer tolerance, as the runloop will check for and fire expired timers
      // when active.
      runLoop.wakeUp()
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
  private let unsafeTaskQueue = FlutterRunLoop.UnsafeTaskQueue()
  let timer: Timer

  init() {
    self.timer = Timer(
      fire: .distantFuture,
      interval: .greatestFiniteMagnitude,
      repeats: true,
    ) { [lock, unsafeTaskQueue] timer in
      MainActor.assumeIsolated {
        for task in LockScope.popExpiredTasks(
          fromQueue: unsafeTaskQueue, withLock: lock, andRearmTimer: timer)
        {
          task.block()
        }
      }
    }
  }

  /// Adds the given task to the task queue and updates the Timer's fire date
  /// accordingly.
  func addTaskAndRearmTimer(task: FlutterRunLoop.Task) {
    lock.withLock {
      let newFireDate = unsafeTaskQueue.add(task: task)
      if newFireDate < timer.fireDate {
        // This call is relatively expensive, avoid calling it for every task added.
        CFRunLoopTimerSetNextFireDate(timer, newFireDate.timeIntervalSinceReferenceDate)
      }
    }
  }

  /// Pops all expired tasks from the task queue and updates the Timer's fire date.
  ///
  /// Returns a sequence of all expired tasks popped from the task queue, sorted by
  /// their expiration dates in ascending order.
  @inline(__always)
  private static func popExpiredTasks(
    fromQueue unsafeTaskQueue: FlutterRunLoop.UnsafeTaskQueue, withLock lock: NSLock,
    andRearmTimer timer: Timer
  ) -> some Sequence<FlutterRunLoop.Task> {
    lock.withLock {
      let (tasks, newFireDate) = unsafeTaskQueue.popTasks(expiringBy: Date())
      // Always set the new fireDate even if it didn't change, to prevent the
      // repeating timer from automatically setting the fire date to .distantFuture
      // (since the firing interval is set to .greatestFiniteMagnitude).
      CFRunLoopTimerSetNextFireDate(timer, newFireDate.timeIntervalSinceReferenceDate)
      return tasks
    }
  }
}

// The data structure is made internal for testing.
extension FlutterRunLoop {
  struct Task {
    let block: @MainActor () -> Void
    let targetDate: Date
  }

  // A simple priority queue that supports adding tasks and popping tasks.
  final class UnsafeTaskQueue {
    // The task queue, sorted by the target date of tasks in ascending order (first to expire first).
    // This is for optimizing adding tasks over popping tasks, since new tasks usually have later
    // expiration dates than most tasks already in the queue.
    private var tasks: ContiguousArray<Task> = []

    func add(task: Task) -> Date {
      let insertionIndex =
        tasks.lastIndex {
          $0.targetDate <= task.targetDate
        }.map { $0 + 1 } ?? 0
      tasks.insert(task, at: insertionIndex)
      return tasks[0].targetDate
    }

    // Returns a list of expired tasks, sorted by their expiration dates
    // in ascending order (first to expire first), and the new earliest deadline,
    // or .distantFuture if no tasks remain in the queue.
    func popTasks(
      expiringBy date: Date
    ) -> (some Sequence<Task>, Date) {
      let firstUnexpiredIndex = tasks.firstIndex { date < $0.targetDate } ?? tasks.count

      // If no tasks have expired.
      guard firstUnexpiredIndex > 0 else {
        return (ContiguousArray<Task>(), tasks.first?.targetDate ?? .distantFuture)
      }

      let expiredTasks = ContiguousArray<Task>(tasks[..<firstUnexpiredIndex])
      tasks.removeSubrange(..<firstUnexpiredIndex)
      return (expiredTasks, tasks.first?.targetDate ?? .distantFuture)
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

  // Calls CFRunLoopWakeUp on the run loop.
  func wakeUp() {
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
