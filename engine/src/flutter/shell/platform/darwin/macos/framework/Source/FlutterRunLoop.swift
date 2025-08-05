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
  private static var _mainRunLoop: FlutterRunLoop?

  private let runLoop: CFRunLoop = CFRunLoopGetCurrent()
  private var tasks: [Task] = []
  private let tasksLock = NSLock()
  private var source: CFRunLoopSource!
  private var timer: CFRunLoopTimer!

  private struct Task {
    let block: () -> Void
    let targetTime: CFAbsoluteTime
  }

  private override init() {
    super.init()

    var sourceContext = CFRunLoopSourceContext(
      version: 0,
      info: Unmanaged.passUnretained(self).toOpaque(),
      retain: nil,
      release: nil,
      copyDescription: nil,
      equal: nil,
      hash: nil,
      schedule: nil,
      cancel: nil,
      perform: { info in
        let runner = Unmanaged<FlutterRunLoop>.fromOpaque(info!).takeUnretainedValue()
        runner.performExpiredTasks()
      }
    )
    guard let createdSource = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &sourceContext) else {
      fatalError("Failed to create CFRunLoopSource")
    }
    source = createdSource
    CFRunLoopAddSource(runLoop, source, .commonModes)
    CFRunLoopAddSource(runLoop, source, Self.flutterRunLoopMode)

    var timerContext = CFRunLoopTimerContext(
      version: 0,
      info: Unmanaged.passUnretained(self).toOpaque(),
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
          let runner = Unmanaged<FlutterRunLoop>.fromOpaque(info!).takeUnretainedValue()
          runner.performExpiredTasks()
        },
        &timerContext
      )
    else {
      fatalError("Failed to create CFRunLoopTimer")
    }
    timer = createdTimer
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
  @objc public static func ensureMainLoopInitialized() {
    assert(Thread.isMainThread, "Must be called on the main thread.")
    if _mainRunLoop == nil {
      _mainRunLoop = FlutterRunLoop()
    }
  }

  // The `FlutterRunLoop` for the main thread.
  @objc public static var mainRunLoop: FlutterRunLoop {
    assert(
      _mainRunLoop != nil,
      "Main run loop has not been initialized. Call ensureMainLoopInitialized() first."
    )
    return _mainRunLoop!
  }

  // Schedules a block to be executed on the main thread.
  @objc public func perform(afterDelay delay: TimeInterval, block: @escaping () -> Void) {
    tasksLock.lock()
    defer { tasksLock.unlock() }

    tasks.append(Task(block: block, targetTime: CFAbsoluteTimeGetCurrent() + delay))
    if delay > 0 {
      rearmTimer()
    } else {
      CFRunLoopSourceSignal(source)
      CFRunLoopWakeUp(runLoop)
    }
  }

  // Schedules a block to be executed on the main thread after a delay.
  @objc(performBlock:)
  public func perform(_ block: @escaping () -> Void) {
    perform(afterDelay: 0, block: block)
  }

  private func performExpiredTasks() {
    var pendingTasks: [Task] = []
    var expiredTasks: [Task] = []

    tasksLock.lock()
    let now = CFAbsoluteTimeGetCurrent()
    for task in tasks {
      if task.targetTime <= now {
        expiredTasks.append(task)
      } else {
        pendingTasks.append(task)
      }
    }
    tasks = pendingTasks
    rearmTimer()
    tasksLock.unlock()

    for task in expiredTasks {
      task.block()
    }
  }

  private func rearmTimer() {
    let nextFireTime = tasks.reduce(CFAbsoluteTime.greatestFiniteMagnitude) { currentMin, task in
      min(currentMin, task.targetTime)
    }
    CFRunLoopTimerSetNextFireDate(timer, nextFireTime)
  }

  /// Executes single iteration of the run loop in the mode where only Flutter
  /// messages are processed.
  @objc public func pollFlutterMessagesOnce() {
    CFRunLoopRunInMode(Self.flutterRunLoopMode, 0.1, true)
  }
}
