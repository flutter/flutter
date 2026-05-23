// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit

/// Provides access to display capabilities and configuration metadata, such as the current
/// maximum refresh rate and whether ProMotion's full refresh-rate range is enabled.
///
/// This class is responsible for display link configuration management, such as querying the
/// maximum supported refresh rate from the platform as well as plist-based configuration.
///
/// On ProMotion iPhones, 120Hz variable refresh rate support must be explicitly unlocked by setting
/// the `CADisableMinimumFrameDurationOnPhone` key (`disableMinimumFrameDurationOnPhoneKey`) to
/// `true` in the application's `Info.plist`. iPad Pro devices will use 120Hz by default.
///
/// All mutable state is confined to `displayRefreshRate`, which is only ever read or written while
/// holding a lock. All other stored properties are immutable, so instances are safe to share and
/// read from any thread once constructed.
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
  public var displayRefreshRate: Double {
    // We cache the refresh rate rather than query from UIKit on every read, since this can be read
    // from background engine threads. The value is kept up-to-date by observing display-mode and
    // low-power-mode change notifications, so callers always see an up-to-date value without
    // polling UIKit themselves.
    //
    // This always reports the hardware/plist-configured maximum. Implement a means for callers to
    // request a reduced maximum frame rate.
    //
    // TODO(cbracken): https://github.com/flutter/flutter/issues/185759
    refreshRateLock.lock()
    defer { refreshRateLock.unlock() }
    return _displayRefreshRate
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
      self.updateCachedDisplayRefreshRate(Double(UIScreen.main.maximumFramesPerSecond))
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

  /// Updates the cached refresh rate under `refreshRateLock`.
  ///
  /// Used by the notification observers started in `startObservingDisplayConfigurationChanges()`.
  /// Marking as `internal` rather than `private` to allow tests to exercise the locking/storage
  /// behavior directly, without being able to change what `UIScreen.main` reports in a test host.
  internal func updateCachedDisplayRefreshRate(_ newValue: Double) {
    refreshRateLock.lock()
    _displayRefreshRate = newValue
    refreshRateLock.unlock()
  }
}
