// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

/// Interface for scheduling tasks on the run loop.
///
/// The main difference between using `FlutterRunLoop` to schedule tasks compared
/// to `DispatchQueue.async` or `RunLoop.perform(_:)` is that `FlutterRunLoop`
/// schedules the task in both common run loop mode and a private run loop mode,
/// which allows it to run in a mode where it only processes Flutter messages
/// (`pollFlutterMessagesOnce()`).
@objc public final class FlutterRunLoop: NSObject {
  private static let flutterRunLoopMode = CFRunLoopMode("FlutterRunLoopMode" as CFString)
  
  // The `ensureMainLoopInitialized` method must be called on the main thread
  // before using this class to set this variable.
  private static nonisolated(unsafe) var _mainRunLoop: FlutterRunLoop?
  
  private let runLoop: CFRunLoop = CFRunLoopGetCurrent()
  private let taskQueue = TaskQueue()
  // This keeps the SourceContextInfo alive.
  private let sourceContextInfo: SourceContextInfo
  private let source: CFRunLoopSource
  private let timer: CFRunLoopTimer
  
  private override init() {
    var timerContext = CFRunLoopTimerContext(
      version: 0,
      info: Unmanaged.passUnretained(taskQueue).toOpaque(),
      retain: nil,
      release: nil,
      copyDescription: nil
    )
    
    guard
      let createdTimer = CFRunLoopTimerCreate(
        kCFAllocatorDefault,
        CFAbsoluteTime.greatestFiniteMagnitude,  // fireDate.
        CFAbsoluteTime.greatestFiniteMagnitude,  // interval.
        0,  // flags.
        0,  // order.
        { timer, info in
          let taskQueue = Unmanaged<TaskQueue>.fromOpaque(info!).takeUnretainedValue()
          taskQueue.runExpiredTasksAndRearm(timer: timer!)
        },
        &timerContext
      )
    else {
      fatalError("Failed to create CFRunLoopTimer")
    }
    self.timer = createdTimer
    self.sourceContextInfo = SourceContextInfo(taskQueue: taskQueue, timer: timer)
    
    var sourceContext = CFRunLoopSourceContext(
      version: 0,
      info: Unmanaged.passUnretained(sourceContextInfo).toOpaque(),
      retain: nil,
      release: nil,
      copyDescription: nil,
      equal: nil,
      hash: nil,
      schedule: nil,
      cancel: nil,
      perform: { info in
        let info = Unmanaged<SourceContextInfo>.fromOpaque(info!).takeUnretainedValue()
        info.taskQueue.runExpiredTasksAndRearm(timer: info.timer)
      }
    )
    guard let createdSource = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &sourceContext) else {
      fatalError("Failed to create CFRunLoopSource")
    }
    self.source = createdSource
    super.init()
    
    CFRunLoopAddSource(runLoop, source, .commonModes)
    CFRunLoopAddSource(runLoop, source, Self.flutterRunLoopMode)
    
    CFRunLoopAddTimer(runLoop, timer, .commonModes)
    CFRunLoopAddTimer(runLoop, timer, Self.flutterRunLoopMode)
  }
  
  deinit {
    CFRunLoopTimerInvalidate(timer)
    CFRunLoopRemoveTimer(runLoop, timer, .commonModes)
    CFRunLoopRemoveTimer(runLoop, timer, Self.flutterRunLoopMode)
    CFRunLoopSourceInvalidate(source)
    CFRunLoopRemoveSource(runLoop, source, .commonModes)
    CFRunLoopRemoveSource(runLoop, source, Self.flutterRunLoopMode)
  }
  
  // Ensures that the `FlutterRunLoop` for main thread is initialized. Only
  // needs to be called once and must be called on the main thread.
  @MainActor
  @objc public static func ensureMainLoopInitialized() {
    assert(Thread.isMainThread, "Must be called on the main thread.")
    if _mainRunLoop == nil {
      _mainRunLoop = FlutterRunLoop()
    }
  }
  
  // The `FlutterRunLoop` for the main thread.
  @objc public static var mainRunLoop: FlutterRunLoop {
    guard let runLoop = _mainRunLoop else {
      fatalError(
        "Main run loop has not been initialized. Call ensureMainLoopInitialized() first."
      );
    }
    return runLoop;
  }
  
  // Schedules a block to be executed on the main thread.
  @objc public func perform(afterDelay delay: TimeInterval, block: @MainActor @escaping () -> Void) {
    let nextFireTime = taskQueue.add(task: TaskQueue.Task(block: block, targetTime: CFAbsoluteTimeGetCurrent() + delay))
    if delay > 0 {
      CFRunLoopTimerSetNextFireDate(timer, nextFireTime)
    } else {
      CFRunLoopSourceSignal(source)
      CFRunLoopWakeUp(runLoop)
    }
  }
  
  // Schedules a block to be executed on the main thread after a delay.
  @objc(performBlock:)
  public func perform(_ block: @MainActor @escaping () -> Void) {
    perform(afterDelay: 0, block: block)
  }
  
  /// Executes single iteration of the run loop in the mode where only Flutter
  /// messages are processed.
  @objc public func pollFlutterMessagesOnce() {
    CFRunLoopRunInMode(Self.flutterRunLoopMode, 0.1, true)
  }
}

private final class TaskQueue {
  private let lock = NSLock()
  
  struct Task {
    let block: @MainActor () -> Void
    let targetTime: CFAbsoluteTime
  }
  
  // (target time of the first task to expire, unsorted task queue)
  private var tasks: [Task] = []
  private var earliestDeadline = CFAbsoluteTime.greatestFiniteMagnitude
  
  func add(task: Task) -> CFAbsoluteTime {
    lock.withLock {
      tasks.append(task)
      earliestDeadline = min(earliestDeadline, task.targetTime)
      return earliestDeadline
    }
  }
  
  // Returns a tuple representing the new earliest deadline
  // and an unordered list of expired tasks.
  private func popTasks(expiringBy time: CFAbsoluteTime) -> (CFAbsoluteTime, [Task]) {
    lock.withLock {
      guard time >= earliestDeadline else {
        return (earliestDeadline, [])
      }
      
      var newQueue: [Task] = []
      var newEarliestDeadline = CFAbsoluteTime.greatestFiniteMagnitude
      var expiredTasks: [Task] = []
      
      for task in tasks {
        if task.targetTime <= time {
          expiredTasks.append(task)
        } else {
          newQueue.append(task)
          newEarliestDeadline = min(newEarliestDeadline, task.targetTime)
        }
      }
      
      earliestDeadline = newEarliestDeadline
      tasks = newQueue
      return (newEarliestDeadline, expiredTasks)
    }
  }
  
  func runExpiredTasksAndRearm(timer: CFRunLoopTimer) {
    let (nextFireDate, expiredTasks) = popTasks(expiringBy: CFAbsoluteTimeGetCurrent())
    
    CFRunLoopTimerSetNextFireDate(timer, nextFireDate)
    MainActor.assumeIsolated {
      for task in expiredTasks {
        task.block()
      }
    }
  }
}

private final class SourceContextInfo {
  init(taskQueue: TaskQueue, timer: CFRunLoopTimer) {
    self.taskQueue = taskQueue
    self.timer = timer
  }
  
  let taskQueue: TaskQueue
  let timer: CFRunLoopTimer
}

