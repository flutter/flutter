// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

/// Coordinates Flutter view content updates with macOS window resizing.
///
/// When a native window containing a Flutter view is resized, the platform's window bounds can
/// change before Flutter has been able to render a new frame matching those new dimensions. This
/// asynchronicity can lead to undesirable visual effects such as:
///   - Content temporarily appearing at the old size within the new, larger bounds.
///   - Black "letterboxing" artifacts rendered at view edges.
///   - A perception of lag in content resizing.
///
/// `ResizeSynchronizer` mitigates these issues by introducing a controlled blocking mechanism
/// during the resize lifecycle:
///
/// 1.  Initiation (Platform Thread): When a native window resize is detected (e.g., by a window
///     delegate), the platform thread calls `beginResize(forSize:notify:onTimeout:)` with the new
///     target dimensions. This method blocks the calling platform thread, pausing the completion of
///     the native resize event. While blocked, it continuously polls for engine messages to process
///     relevant updates. The `notify` closure is invoked just before blocking begins.
///
/// 2.  Commit (Raster Thread): As the engine renders frames, the raster thread, upon presenting a
///     new frame, calls `performCommit(forSize:afterDelay:notify:)`, providing the size of the
///     frame just rendered.
///
/// 3.  Unblocking: If the size of the committed frame matches the target size that `beginResize()`
///     is waiting for, `beginResize()` unblocks. This allows the native resize operation to
///     complete, now that Flutter's content is synchronized with the new window dimensions.
///
/// Safeguards:
///   - Timeout: `beginResize()` includes a timeout mechanism to prevent indefinite blocking if a
///     matching frame isn't committed in a timely manner. An optional `onTimeout` closure can be
///     provided to handle this event.
///   - Shutdown: The synchronization can be cleanly interrupted by calling `shutDown()`, which will
///     also unblock any pending `beginResize()` call. After shutdown, `beginResize()` will no
///     longer block.
///   - Thread Safety: The class manages its internal state in a thread-safe manner to coordinate
///     actions between the platform thread and the raster thread.
@objc(FlutterResizeSynchronizer)
public final class ResizeSynchronizer: NSObject {
  private static let invalidSize = CGSize(width: -1, height: -1)

  // Synchronizes access to _isInResize_unsafe: isInResize is accessed from multiple threads and
  // thus requires synchronized access to the underlying storage.
  private let isInResizeLock = NSLock()
  private var _isInResize_unsafe: Bool = false
  private var isInResize: Bool {
    get {
      isInResizeLock.lock()
      defer { isInResizeLock.unlock() }
      return _isInResize_unsafe
    }
    set {
      isInResizeLock.lock()
      _isInResize_unsafe = newValue
      isInResizeLock.unlock()
    }
  }

  // True if the app is shutting down. Must be set on platform thread.
  private var isShuttingDown: Bool = false

  // True if at least one frame has been presented. Must be set on platform thread.
  private var didReceiveFrame: Bool = false

  // The updated view surface size. Must be set on platform thread.
  private var contentSize: CGSize = ResizeSynchronizer.invalidSize

  /// Begins window resize operation to the specified size.
  ///
  /// Blocks the thread until `performCommit(forSize:notify:delay:)` with the same size is called.
  /// While the thread is blocked, Flutter messages are being pumped.
  /// See `FlutterRunLoop.mainRunLoop.pollFlutterMessagesOnce()`.
  @objc public func beginResize(
    forSize size: CGSize,
    notify: () -> Void,
    onTimeout: (() -> Void)? = nil
  ) {
    if !didReceiveFrame || isShuttingDown {
      // If we haven't yet received a frame, or we're shutting down, there's nothing to do.
      notify()
      return
    }

    // Mark that we're in a resize and set the content size to a sentinel value.
    isInResize = true
    contentSize = ResizeSynchronizer.invalidSize

    // Call the notify callback.
    notify()

    // Spin, waiting for the commit (during frame present) for up to 1 second, then time out.
    let startTime = CFAbsoluteTimeGetCurrent()
    let timeoutDuration: TimeInterval = 1.0
    while true {
      // If no change to size, or we got a shutdown notice, bail out.
      if contentSize == size || isShuttingDown {
        break
      }

      // If we've hit the timeout, notify the caller and bail out.
      if CFAbsoluteTimeGetCurrent() - startTime > timeoutDuration {
        onTimeout?()
        break
      }

      // Process platform thread messages to pick up any updates to contentSize, didReceiveFrame,
      // isShuttingDown made in performCommit and shutdown methods.
      FlutterRunLoop.mainRunLoop.pollFlutterMessagesOnce()
    }
    isInResize = false
  }

  /// Commit the updated frame size.
  ///
  /// Schedules the given block on the platform thread with the given delay. Unblocks `beginResize`
  /// on the platform thread, if waiting for the surface during resize.
  ///
  /// Called from the raster thread on frame present.
  @objc public func performCommit(
    forSize size: CGSize,
    afterDelay delay: TimeInterval,
    notify: @escaping () -> Void
  ) {
    var effectiveDelay = delay

    // If we're currently resizing, process immediately.
    if self.isInResize {  // Accesses the computed property which uses the lock
      effectiveDelay = 0
    }

    FlutterRunLoop.mainRunLoop.perform(afterDelay: effectiveDelay) {
      self.didReceiveFrame = true
      self.contentSize = size
      notify()
    }
  }

  /// Notifies the synchronizer that the Flutter view is being shut down.
  ///
  /// Unblocks the platform thread if blocked.
  @objc public func shutDown() {
    FlutterRunLoop.mainRunLoop.perform {
      self.isShuttingDown = true
    }
  }
}
