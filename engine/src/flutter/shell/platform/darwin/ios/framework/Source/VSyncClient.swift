// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import QuartzCore
import UIKit

@objc(FlutterVSyncClient)
public class VSyncClient: NSObject {
  private static let defaultRefreshRate: Double = 60.0

  private let taskRunner: TaskRunner
  private let isVariableRefreshRateEnabled: Bool
  private let callback: (CFTimeInterval, CFTimeInterval) -> Void

  /// The display link used to coordinate vsync callbacks.
  @objc
  internal private(set) var displayLink: CADisplayLink?

  private var _refreshRate: Double = defaultRefreshRate

  /// The current display refresh rate in Hertz, rounded to the nearest integer value.
  ///
  /// This value is calculated during each vsync callback as the inverse of the frame duration (the
  /// time between the current frame and the target next frame). The resulting frequency is rounded
  /// to the nearest whole number to smooth out minor hardware timestamp variations.
  ///
  /// If the current refresh rate is unknown or invalid (e.g., during startup or a paused transition),
  /// this property falls back to `defaultRefreshRate` (60Hz).
  @objc
  public var refreshRate: Double {
    return _refreshRate > 0.0 ? _refreshRate : VSyncClient.defaultRefreshRate
  }

  /// Default value is `true`. Vsync client will pause vsync callback after receiving a vsync
  /// signal. Setting this property to `false` can avoid this and vsync client will trigger vsync
  /// callback continuously.
  @objc
  public var allowPauseAfterVsync: Bool = true

  /// Initializes the vsync client.
  ///
  /// - Parameters:
  ///   - taskRunner: The task runner to use for posting tasks.
  ///   - isVariableRefreshRateEnabled: Whether variable refresh rate should be enabled.
  ///   - maxRefreshRate: The maximum refresh rate to configure the display link with.
  ///   - callback: The callback to invoke when a vsync signal is received.
  @objc
  public init(
    taskRunner: TaskRunner,
    isVariableRefreshRateEnabled: Bool,
    maxRefreshRate: Double,
    callback: @escaping (CFTimeInterval, CFTimeInterval) -> Void
  ) {
    self.taskRunner = taskRunner
    self.isVariableRefreshRateEnabled = isVariableRefreshRateEnabled
    self._refreshRate = maxRefreshRate
    self.callback = callback

    super.init()

    let relay = VSyncClientRelay(target: self)
    let link = CADisplayLink(target: relay, selector: #selector(VSyncClientRelay.onDisplayLink(_:)))
    link.isPaused = true
    self.displayLink = link

    setMaxRefreshRate(maxRefreshRate)

    // Capture a weak reference to self to ensure we don't add the display link to the run loop if
    // the client has already been deallocated.
    taskRunner.postTask { [weak self] in
      guard let self else { return }
      self.displayLink?.add(to: .current, forMode: .common)
    }
  }

  deinit {
    invalidate()
  }

  /// Configures the maximum and preferred refresh rate range for the display link.
  ///
  /// Sets the preferred frame rate range on iOS 15.0 and above, or preferred frames per second on
  /// older iOS versions, provided that variable refresh rate support is enabled.
  ///
  /// - Parameter requestedRate: The target maximum refresh rate in Hertz.
  @objc
  public func setMaxRefreshRate(_ requestedRate: Double) {
    guard isVariableRefreshRateEnabled else { return }
    guard let link = displayLink else { return }

    let maxFrameRate = max(requestedRate, VSyncClient.defaultRefreshRate)
    let minFrameRate = max(maxFrameRate / 2.0, VSyncClient.defaultRefreshRate)

    if #available(iOS 15.0, *) {
      link.preferredFrameRateRange = CAFrameRateRange(
        minimum: Float(minFrameRate),
        maximum: Float(maxFrameRate),
        preferred: Float(maxFrameRate)
      )
    } else {
      link.preferredFramesPerSecond = Int(maxFrameRate)
    }
  }

  /// Resumes the display link to begin receiving vsync callback ticks.
  ///
  /// Calling this method unpauses the underlying `CADisplayLink`, allowing it to trigger
  /// `onDisplayLink(_:)` on the next vsync event.
  @objc
  public func await() {
    displayLink?.isPaused = false
  }

  /// Pauses the display link to stop receiving vsync callbacks.
  ///
  /// Calling this method pauses the underlying `CADisplayLink`, preventing it from triggering
  /// any subsequent vsync events until `await()` is called.
  @objc
  public func pause() {
    displayLink?.isPaused = true
  }

  /// Invalidates the underlying display link to remove it from all run loops.
  ///
  /// This method must be called before releasing the `VSyncClient` instance to prevent memory leaks
  /// caused by the `CADisplayLink` retaining its target.
  @objc
  public func invalidate() {
    guard let link = displayLink else { return }
    displayLink = nil

    // Ensure that the CADisplayLink target (us) is invalidated on the thread it was created on.
    // CADisplayLinkManager.invalidate() is thread-safe and will do this for us, but both for
    // symmetry with how we do registration in init() and to use TaskRunner APIs for all thread
    // hops, we do this explicitly.
    if taskRunner.runsTasksOnCurrentThread() {
      link.invalidate()
    } else {
      taskRunner.postTask {
        link.invalidate()
      }
    }
  }

  /// The callback target triggered by the `CADisplayLink` on every vsync tick.
  ///
  /// This method updates the current display refresh rate metrics, logs a timeline trace for
  /// instrumentation, automatically pauses the display link if `allowPauseAfterVsync` is set to
  /// `true`, and invokes the vsync listener callback with the target start and next frame times.
  ///
  /// - Parameter link: The display link triggering this event.
  @objc
  internal func onDisplayLink(_ link: CADisplayLink) {
    // CADisplayLink timestamps use the CACurrentMediaTime() monotonic clock (seconds since boot).
    // CACurrentMediaTime() is based on mach_absolute_time, whereas the core engine uses
    // fml::TimePoint, which is implemented with std::chrono::steady_clock, which uses
    // mach_continuous_time under the hood. Thus, the values passed to the engine in the vsync
    // callback need to be rebased to fml::TimePoint's epoch.
    //
    // According to Apple's docs, before the first frame is delivered, or when the display link is
    // paused, both timestamp and targetTimestamp properties are 0.0. To guarantee consistent frame
    // progression, we guard against zero values and fall back to CACurrentMediaTime().
    var timestamp = link.timestamp
    if timestamp == 0.0 {
      timestamp = CACurrentMediaTime()
    }

    // targetTimestamp is the anticipated presentation time of the next screen refresh. If
    // targetTimestamp is zero or less than/equal to timestamp (which also occurs on paused/unpaused
    // transitions), synthesize a projected target time based on the current refresh rate.
    var targetTimestamp = link.targetTimestamp
    if targetTimestamp <= timestamp {
      targetTimestamp = timestamp + (1.0 / refreshRate)
    }

    Tracing.tracePlatformVsync(
      withStartTime: timestamp,
      targetTime: targetTimestamp
    )

    let duration = targetTimestamp - timestamp

    // In steady-state, duration reflects the hardware refresh interval (e.g., ~0.01667s for 60Hz).
    // We dynamically recalculate the refresh rate from the frame duration to adjust to ProMotion
    // display refresh rate shifts.
    //
    // Round to nearest whole Hz value to ensure we don't introduce frame timing issues due to
    // floating point error. e.g. 59.998, 60.004, 59.995, ... --> 60.000, 60.000, 60.000, ...
    if duration > 0 {
      let roundedRefreshRate = round(1.0 / duration)
      if roundedRefreshRate > 0.0 {
        _refreshRate = roundedRefreshRate
      }
    }

    if allowPauseAfterVsync {
      link.isPaused = true
    }
    callback(timestamp, targetTimestamp)
  }
}

/// A weak proxy target for `CADisplayLink` callbacks to prevent retain cycles.
///
/// `CADisplayLink` strongly retains its target. If the display link directly targeted
/// `VSyncClient`, it would form a strong retain cycle (since `VSyncClient` also strongly retains
/// the `CADisplayLink` instance). Instead, we route display link callbacks through this
/// intermediate relay holding `VSyncClient` weakly.
private final class VSyncClientRelay: NSObject {
  private weak var target: VSyncClient?

  init(target: VSyncClient) {
    self.target = target
  }

  @objc
  func onDisplayLink(_ link: CADisplayLink) {
    target?.onDisplayLink(link)
  }
}
