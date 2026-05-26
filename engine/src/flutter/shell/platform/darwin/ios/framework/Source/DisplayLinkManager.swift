// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import QuartzCore
import UIKit

/// Provides access to display capabilities and configuration metadata.
///
/// - Warning: Do not use this class to drive active frame scheduling or rendering loops. For frame
///   scheduling, use `VSyncClient` instead.
///
/// This class is responsible for display link configuration management, such as querying the
/// maximum supported refresh rate from the platform as well as plist-based configuration.
///
/// On ProMotion iPhones, 120Hz variable refresh rate support must be explicitly unlocked by setting
/// the `CADisableMinimumFrameDurationOnPhone` key (`disableMinimumFrameDurationOnPhoneKey`) to
/// `true` in the application's `Info.plist`. iPad Pro devices will use 120Hz by default.
///
/// - Note: This class contains only stateless `static` properties and class methods and should not
///   be instantiated.
@objc(FlutterDisplayLinkManager)
public class DisplayLinkManager: NSObject {

  /// Info.plist key enabling the full range of ProMotion refresh rates for CADisplayLink callbacks
  /// and CAAnimation animations in the app.
  ///
  /// - SeeAlso: https://developer.apple.com/documentation/quartzcore/optimizing_promotion_refresh_rates_for_iphone_13_pro_and_ipad_pro#3885321
  internal static let disableMinimumFrameDurationOnPhoneKey = "CADisableMinimumFrameDurationOnPhone"

  /// Whether the max refresh rate on iPhone ProMotion devices is enabled.
  ///
  /// This reflects the value of `disableMinimumFrameDurationOnPhoneKey` in the info.plist file.
  /// On iPads that support ProMotion, the max refresh rate is enabled by default. Maximum frame
  /// rate can be limited via `VSyncClient.setMaxRefreshRate(_:)`
  ///
  /// - Returns: `true` if the max refresh rate on ProMotion devices is enabled.
  @objc
  public static var maxRefreshRateEnabledOnIPhone: Bool {
    return Bundle.main.object(forInfoDictionaryKey: disableMinimumFrameDurationOnPhoneKey)
      as? Bool ?? false
  }

  /// The maximum display refresh rate used for reporting purposes.
  ///
  /// This is intended to return either the hardware maximum refresh rate or the maximum configured
  /// by the user (e.g. via an Info.plist setting or custom configuration). The engine does not care
  /// about this for frame scheduling. It is only used by tools for instrumentation. The engine uses
  /// the duration field of the link per frame for frame scheduling.
  ///
  /// - Attention: Do not use this call in frame scheduling. It is only meant for reporting.
  /// - Returns: The refresh rate in frames per second.
  @objc
  public static var displayRefreshRate: Double {
    // TODO(cbracken): This code is incorrect. https://github.com/flutter/flutter/issues/185759
    //
    // We create a new CADisplayLink, call `preferredFramesPerSecond` on it, then immediately throw
    // it away. As noted below, the default value for `preferredFramesPerSecond` is zero, in which
    // case, we just return UIScreen.main.maximumFramesPerSecond in all cases; everything before
    // that line can be deleted.
    //
    // If we intend to support configurable preferred FPS, then we should provide API for it. We
    // should delete this code either way.

    let displayLink = CADisplayLink(target: self, selector: #selector(onDisplayLink(_:)))
    displayLink.isPaused = true
    let preferredFPS = displayLink.preferredFramesPerSecond

    // From Docs:
    // The default value for preferredFramesPerSecond is 0. When this value is 0, the preferred
    // frame rate is equal to the maximum refresh rate of the display, as indicated by the
    // maximumFramesPerSecond property.
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
