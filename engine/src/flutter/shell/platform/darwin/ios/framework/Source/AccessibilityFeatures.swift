// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Accessibility
import Foundation
import UIKit

/// An option set for defining the different kinds of accessibility features
/// that can be enabled by the platform.
///
/// - Important: must match the `AccessibilityFeatures` class in `window.dart`.
struct AccessibilityFeatureFlag: OptionSet {
    let rawValue: Int32
    
    static let accessibleNavigation = AccessibilityFeatureFlag(rawValue: 1 << 0)
    static let invertColors = AccessibilityFeatureFlag(rawValue: 1 << 1)
    static let disableAnimations = AccessibilityFeatureFlag(rawValue: 1 << 2)
    static let boldText = AccessibilityFeatureFlag(rawValue: 1 << 3)
    static let reduceMotion = AccessibilityFeatureFlag(rawValue: 1 << 4)
    static let highContrast = AccessibilityFeatureFlag(rawValue: 1 << 5)
    static let onOffSwitchLabels = AccessibilityFeatureFlag(rawValue: 1 << 6)
    static let noAnnounce = AccessibilityFeatureFlag(rawValue: 1 << 7)
    static let noAutoPlayAnimatedImages = AccessibilityFeatureFlag(rawValue: 1 << 8)
    static let noAutoPlayVideos = AccessibilityFeatureFlag(rawValue: 1 << 9)
    static let deterministicCursor = AccessibilityFeatureFlag(rawValue: 1 << 10)
}

/// A wrapper for native iOS accessibility settings.
@objc(FlutterAccessibilityFeatures)
public class AccessibilityFeatures: NSObject {
    /// Returns the current accessibility flags as a bitmask.
    @objc public var flags: Int32 {
        var flags: AccessibilityFeatureFlag = []
        
        if self.isVoiceOverRunning() || self.isSwitchControlRunning() {
            flags.insert(.accessibleNavigation)
        }
        if self.isInvertColorsEnabled() {
            flags.insert(.invertColors)
        }
        if self.isBoldTextEnabled() {
            flags.insert(.boldText)
        }
        if self.isReduceMotionEnabled() {
            flags.insert(.reduceMotion)
        }
        if self.isDarkerSystemColorsEnabled() {
            flags.insert(.highContrast)
        }
        if self.isOnOffSwitchLabelsEnabled() {
            flags.insert(.onOffSwitchLabels)
        }
        if !self.isAnimatedImagesAutoPlayEnabled() {
            flags.insert(.noAutoPlayAnimatedImages)
        }
        if !self.isVideosAutoPlayEnabled() {
            flags.insert(.noAutoPlayVideos)
        }
        if self.isDeterministicCursorEnabled() {
            flags.insert(.deterministicCursor)
        }
        
        return flags.rawValue
    }
    
    /// Returns an array of notification names to observe for accessibility
    /// changes.
    @objc public var observedNotificationNames: [String] {
        var names: [String] = [
            AccessibilityFeatures.voiceOverStatusDidChangeNotification,
            AccessibilityFeatures.switchControlStatusDidChangeNotification,
            AccessibilityFeatures.speakScreenStatusDidChangeNotification,
            AccessibilityFeatures.invertColorsStatusDidChangeNotification,
            AccessibilityFeatures.reduceMotionStatusDidChangeNotification,
            AccessibilityFeatures.boldTextStatusDidChangeNotification,
            AccessibilityFeatures.darkerSystemColorsStatusDidChangeNotification,
            AccessibilityFeatures.onOffSwitchLabelsDidChangeNotification,
            AccessibilityFeatures.videosAutoPlayStatusDidChangeNotification,
        ]
        
        if #available(iOS 18.0, *) {
            names.append(contentsOf: [
                AccessibilityFeatures.animatedImagesAutoPlayStatusDidChangeNotification,
                AccessibilityFeatures.deterministicCursorStatusDidChangeNotification,
            ])
        }
        
        return names
    }
    
    /// Notification name for changes to `VoiceOver` status.
    @objc public static var voiceOverStatusDidChangeNotification: String {
        return UIAccessibility.voiceOverStatusDidChangeNotification.rawValue
    }
    
    /// Whether `VoiceOver` is running.
    @objc public func isVoiceOverRunning() -> Bool {
        return UIAccessibility.isVoiceOverRunning
    }
    
    /// Notification name for changes to `Switch Control` status.
    @objc public static var switchControlStatusDidChangeNotification: String {
        return UIAccessibility.switchControlStatusDidChangeNotification.rawValue
    }
    
    /// Whether `Switch Control` is running.
    @objc public func isSwitchControlRunning() -> Bool {
        return UIAccessibility.isSwitchControlRunning
    }
    
    /// Notification name for changes to `Speak Screen` setting.
    @objc public static var speakScreenStatusDidChangeNotification: String {
        return UIAccessibility.speakScreenStatusDidChangeNotification.rawValue
    }
    
    /// Whether `Speak Screen` setting is enabled.
    @objc public func isSpeakScreenEnabled() -> Bool {
        return UIAccessibility.isSpeakScreenEnabled
    }
    
    /// Notification name for changes to `Classic Invert` setting.
    @objc public static var invertColorsStatusDidChangeNotification: String {
        return UIAccessibility.invertColorsStatusDidChangeNotification.rawValue
    }
    
    /// Whether `Classic Invert` setting is enabled.
    @objc public func isInvertColorsEnabled() -> Bool {
        return UIAccessibility.isInvertColorsEnabled
    }
    
    /// Notification name for changes to `Reduce Motion` setting.
    @objc public static var reduceMotionStatusDidChangeNotification: String {
        return UIAccessibility.reduceMotionStatusDidChangeNotification.rawValue
    }
    
    /// Whether `Reduce Motion` setting is enabled.
    @objc public func isReduceMotionEnabled() -> Bool {
        return UIAccessibility.isReduceMotionEnabled
    }
    
    /// Notification name for changes to `Bold Text` setting.
    @objc public static var boldTextStatusDidChangeNotification: String {
        return UIAccessibility.boldTextStatusDidChangeNotification.rawValue
    }
    
    /// Whether `Bold Text` setting is enabled.
    @objc public func isBoldTextEnabled() -> Bool {
        return UIAccessibility.isBoldTextEnabled
    }
    
    /// Notification name for changes to `Increase Contrast` setting.
    @objc public static var darkerSystemColorsStatusDidChangeNotification: String {
        return UIAccessibility.darkerSystemColorsStatusDidChangeNotification.rawValue
    }
    
    /// Whether `Increase Contrast` setting is enabled.
    @objc public func isDarkerSystemColorsEnabled() -> Bool {
        return UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    /// Notification name for changes to `On/Off Labels` setting.
    @objc public static var onOffSwitchLabelsDidChangeNotification: String {
        return UIAccessibility.onOffSwitchLabelsDidChangeNotification.rawValue
    }
    
    /// Whether `On/Off Labels` setting is enabled.
    @objc public func isOnOffSwitchLabelsEnabled() -> Bool {
        return UIAccessibility.isOnOffSwitchLabelsEnabled
    }
    
    /// Notification name for changes to `Auto-Play Animated Images` setting.
    @available(iOS 18.0, *)
    @objc public static var animatedImagesAutoPlayStatusDidChangeNotification: String {
        return AccessibilitySettings.animatedImagesEnabledDidChangeNotification.rawValue
    }
    
    /// Whether `Auto-Play Animated Images` setting is enabled.
    ///
    /// Defaults to `true` on iOS versions earlier than 18.
    @objc public func isAnimatedImagesAutoPlayEnabled() -> Bool {
        if #available(iOS 18.0, *) {
            return AccessibilitySettings.animatedImagesEnabled
        }
        return true
    }
    
    /// Notification name for changes to `Auto-Play Video Previews` setting.
    @objc public static var videosAutoPlayStatusDidChangeNotification: String {
        return UIAccessibility.videoAutoplayStatusDidChangeNotification.rawValue
    }
    
    /// Whether `Auto-Play Video Previews` setting is enabled.
    @objc public func isVideosAutoPlayEnabled() -> Bool {
        return UIAccessibility.isVideoAutoplayEnabled
    }
    
    /// Notification name for changes to `Prefer Non-Blinking Cursor` setting.
    @available(iOS 18.0, *)
    @objc public static var deterministicCursorStatusDidChangeNotification: String {
        return AccessibilitySettings.prefersNonBlinkingTextInsertionIndicatorDidChangeNotification.rawValue
    }
    
    /// Whether `Prefer Non-Blinking Cursor` setting is enabled.
    ///
    /// Defaults to `false` on iOS versions earlier than 18.
    @objc public func isDeterministicCursorEnabled() -> Bool {
        if #available(iOS 18.0, *) {
            return AccessibilitySettings.prefersNonBlinkingTextInsertionIndicator
        }
        return false
    }
}
