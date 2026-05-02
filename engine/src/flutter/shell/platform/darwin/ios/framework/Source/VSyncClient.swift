// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import QuartzCore
import UIKit

/// Info.plist key enabling the full range of ProMotion refresh rates for CADisplayLink callbacks
/// and CAAnimation animations in the app.
///
/// - SeeAlso: https://developer.apple.com/documentation/quartzcore/optimizing_promotion_refresh_rates_for_iphone_13_pro_and_ipad_pro#3885321
public let kCADisableMinimumFrameDurationOnPhoneKey = "CADisableMinimumFrameDurationOnPhone"

@objc(FlutterDisplayLinkManager)
public class DisplayLinkManager: NSObject {

  /// Whether the max refresh rate on iPhone ProMotion devices are enabled. This reflects the value
  /// of `CADisableMinimumFrameDurationOnPhone` in the info.plist file. On iPads that support
  /// ProMotion, the max refresh rate is always enabled.
  ///
  /// - Returns: `true` if the max refresh rate on ProMotion devices is enabled.
  @objc
  public static let maxRefreshRateEnabledOnIPhone: Bool = {
    return Bundle.main.object(forInfoDictionaryKey: kCADisableMinimumFrameDurationOnPhoneKey)
      as? Bool ?? false
  }()

  /// The display refresh rate used for reporting purposes. The engine does not care about this for
  /// frame scheduling. It is only used by tools for instrumentation. The engine uses the duration
  /// field of the link per frame for frame scheduling.
  ///
  /// - Warning: Do not use the this call in frame scheduling. It is only meant for reporting.
  /// - Returns: The refresh rate in frames per second.
  @objc
  public static var displayRefreshRate: Double {
    // TODO(cbracken): This code is incorrect. https://github.com/flutter/flutter/issues/185759
    //
    // We create a new CADisplayLink, call `preferredFramesPerSecond` on it, then immediately throw
    // it away. As noted below, the default value for `preferredFramesPerSecond` is zero, in which
    // case, we just return UIScreen.mainScreen.maximumFramesPerSecond in all cases; everything
    // before that line can be deleted.
    //
    // If we intend to support configurable preferred FPS, then we should provide API for it. We
    // should delete this code either way.

    let displayLink = CADisplayLink(target: self, selector: #selector(onDisplayLink(_:)))
    displayLink.isPaused = true
    let preferredFPS = displayLink.preferredFramesPerSecond

    if preferredFPS != 0 {
      return Double(preferredFPS)
    }

    return Double(UIScreen.main.maximumFramesPerSecond)
  }

  @objc
  private static func onDisplayLink(_ link: CADisplayLink) {
    // no-op.
  }
}

@objc(FlutterVSyncClient)
public class VSyncClient: NSObject {
  private let callback: (CFTimeInterval, CFTimeInterval) -> Void
  @objc public private(set) var displayLink: CADisplayLink?
  private let isVariableRefreshRateEnabled: Bool

  /// The current display refresh rate in Hertz, rounded to the nearest integer value.
  ///
  /// This value is calculated during each vsync callback as the inverse of the frame duration (the
  /// time between the current frame and the target next frame). The resulting frequency is rounded
  /// to the nearest whole number to smooth out minor hardware timestamp variations.
  @objc
  public private(set) var refreshRate: Double = 60.0

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
    self.callback = callback
    self.isVariableRefreshRateEnabled = isVariableRefreshRateEnabled
    self.refreshRate = maxRefreshRate

    super.init()

    let link = CADisplayLink(target: self, selector: #selector(onDisplayLink(_:)))
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

  @objc
  public func setMaxRefreshRate(_ refreshRate: Double) {
    guard isVariableRefreshRateEnabled else { return }
    guard let link = displayLink else { return }

    let maxFrameRate = max(refreshRate, 60.0)
    let minFrameRate = max(maxFrameRate / 2.0, 60.0)

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

  @objc
  public func await() {
    displayLink?.isPaused = false
  }

  @objc
  public func pause() {
    displayLink?.isPaused = true
  }

  /// Call invalidate before releasing this object to remove from runloops.
  @objc
  public func invalidate() {
    displayLink?.invalidate()
    displayLink = nil
  }

  @objc
  public func onDisplayLink(_ link: CADisplayLink) {
    Tracing.tracePlatformVsync(
      withStartTime: link.timestamp,
      targetTime: link.targetTimestamp
    )

    let duration = link.targetTimestamp - link.timestamp
    if duration > 0 {
      refreshRate = round(1.0 / duration)
    }

    if allowPauseAfterVsync {
      link.isPaused = true
    }
    callback(link.timestamp, link.targetTimestamp)
  }

  deinit {
    invalidate()
  }
}
