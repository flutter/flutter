// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit

/// Reports the device's display capabilities, including the maximum refresh rate a display can
/// support and whether the full ProMotion refresh-rate range is unlocked for this app.
///
/// The maximum refresh rate is the hardware ceiling for the display. On a ProMotion display the
/// ceiling is commonly 120Hz, while CoreAnimation remains free to drive the panel at any rate at or
/// below that ceiling depending on on-screen content, thermal state, and power settings. The live
/// rate is derived separately, once per frame, from the timing of the `CADisplayLink` held by
/// `VSyncClient`.
///
/// The full ProMotion refresh-rate range must be explicitly unlocked by setting the
/// `CADisableMinimumFrameDurationOnPhone` key (`disableMinimumFrameDurationOnPhoneKey`) to `true`
/// in the application's `Info.plist`; iPad Pro devices default to the full range without this key.
///
/// Callers obtain the singleton instance via `shared` and typically use
/// `maxRefreshRateEnabledOnIPhone` and `displayRefreshRate` to configure a `CADisplayLink`'s
/// `preferredFrameRateRange`, either indirectly through a `VSyncClient`'s initializer or, in the
/// case of `FlutterMetalLayer`, by configuring its own `CADisplayLink` similarly. The primary
/// consumer is `VsyncWaiterIOS`, the C++ engine's vsync entry point, which owns a long-lived
/// `VSyncClient` and re-reads `displayRefreshRate` on every vsync to detect ceiling changes at
/// runtime and propagate them to the core engine. `KeyboardInsetManager` and
/// `FlutterViewController` consult it the same way when configuring their own (short-lived)
/// `VSyncClient` instances.
///
/// All mutable state is confined to the refresh-rate cache, which is only ever read or written
/// while holding a lock; every other stored property is immutable, so instances are safe to share
/// and read from any thread once constructed.
@objc(FlutterDisplayLinkManager)
public final class DisplayLinkManager: NSObject, @unchecked Sendable {

  /// The shared DisplayLinkManager.
  ///
  /// The first access performs a one-time read of `UIScreen.main`, and must happen on the main
  /// thread; this is enforced by an assertion in `init()`.
  @objc
  public static let shared = DisplayLinkManager()

  /// Info.plist key enabling the full range of ProMotion refresh rates for CADisplayLink callbacks
  /// and CAAnimation animations in the app.
  ///
  /// - SeeAlso: https://developer.apple.com/documentation/quartzcore/optimizing_promotion_refresh_rates_for_iphone_13_pro_and_ipad_pro#3885321
  internal static let disableMinimumFrameDurationOnPhoneKey = "CADisableMinimumFrameDurationOnPhone"

  /// Whether the max refresh rate on iPhone ProMotion devices is enabled.
  ///
  /// This reflects the value of `disableMinimumFrameDurationOnPhoneKey` in the info.plist file. On
  /// iPads that support ProMotion, the max refresh rate is enabled by default. The maximum frame
  /// rate can be limited via `VSyncClient.setMaxRefreshRate(_:)`
  ///
  /// - Returns: `true` if the max refresh rate on ProMotion devices is enabled.
  @objc
  public let maxRefreshRateEnabledOnIPhone: Bool

  /// The maximum display refresh rate, in frames per second.
  @objc
  public internal(set) var displayRefreshRate: Double {
    get {
      // We cache the refresh rate rather than query from UIKit on every read, since this can be
      // read from background engine threads. The value is kept up-to-date by observing
      // display-mode and low-power-mode change notifications, so callers always see an
      // up-to-date value without polling UIKit themselves.
      //
      // This always reports the hardware/plist-configured maximum. Implement a means for
      // callers to request a reduced maximum frame rate.
      //
      // TODO(cbracken): https://github.com/flutter/flutter/issues/185759
      refreshRateLock.withLock { _displayRefreshRate }
    }
    // The setter is `internal` rather than `private` so tests can exercise the locking/storage
    // behavior directly, without being able to change what `UIScreen.main` reports in a test host.
    set {
      refreshRateLock.withLock { _displayRefreshRate = newValue }
    }
  }

  private var _displayRefreshRate: Double
  private let refreshRateLock = NSLock()

  /// The observer tokens returned by `NotificationCenter.addObserver`.
  ///
  /// If these aren't retained, they're deallocated immediately and the observers stop firing.
  private var observers: [Any] = []

  /// Initializes a new DisplayLinkManager.
  ///
  /// Queries the system plist and main screen properties on the main thread, then starts observing
  /// for changes that can affect the cached refresh rate.
  private override init() {
    assert(
      Thread.isMainThread,
      "DisplayLinkManager.shared must first be accessed on the main thread.")
    self.maxRefreshRateEnabledOnIPhone =
      Bundle.main.object(
        forInfoDictionaryKey: DisplayLinkManager.disableMinimumFrameDurationOnPhoneKey
      ) as? Bool ?? false

    self._displayRefreshRate = Double(UIScreen.main.maximumFramesPerSecond)
    super.init()

    startObservingDisplayConfigurationChanges()
  }

  /// Testing initializer that injects configuration values.
  ///
  /// Unlike the standard initializer, this does not start observing system notifications.
  internal init(maxRefreshRateEnabled: Bool, refreshRate: Double) {
    self.maxRefreshRateEnabledOnIPhone = maxRefreshRateEnabled
    self._displayRefreshRate = refreshRate
    super.init()
  }

  /// Starts watching for system changes that can affect `UIScreen.main.maximumFramesPerSecond`.
  ///
  /// Triggers for frame-rate changes include Low Power Mode or thermal throttling being enabled
  /// (which caps ProMotion to 60Hz), or the screen's mode changing (e.g. an external display
  /// connecting).
  ///
  /// There's no documented, exhaustive list of everything that can affect the reported refresh
  /// rate, so on top of the specific triggers above, this also updates whenever the app returns
  /// to the foreground. That bounds how stale the cached value can get even from a trigger this
  /// class doesn't explicitly know about.
  private func startObservingDisplayConfigurationChanges() {
    let handleChange: (Notification) -> Void = { [weak self] _ in
      guard let self = self else { return }
      self.displayRefreshRate = Double(UIScreen.main.maximumFramesPerSecond)
    }
    observers = [
      NotificationCenter.default.addObserver(
        forName: UIScreen.modeDidChangeNotification, object: UIScreen.main, queue: .main,
        using: handleChange),
      NotificationCenter.default.addObserver(
        forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: .main,
        using: handleChange),
      NotificationCenter.default.addObserver(
        forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: .main,
        using: handleChange),
      NotificationCenter.default.addObserver(
        forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main,
        using: handleChange),
    ]
  }
}
