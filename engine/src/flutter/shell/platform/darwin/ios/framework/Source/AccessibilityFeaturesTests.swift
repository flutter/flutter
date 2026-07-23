// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Accessibility
import UIKit
import Testing

@testable import InternalFlutterSwift

/// A mock subclass of `AccessibilityFeatures` that allows override the
/// values returned by the functions.
class MockAccessibilityFeatures: AccessibilityFeatures {
    var mockVoiceOverRunning = false
    var mockSwitchControlRunning = false
    var mockInvertColorsEnabled = false
    var mockBoldTextEnabled = false
    var mockReduceMotionEnabled = false
    var mockDarkerSystemColorsEnabled = false
    var mockOnOffSwitchLabelsEnabled = false
    var mockAnimatedImagesAutoPlayEnabled = true
    var mockVideosAutoPlayEnabled = true
    var mockDeterministicCursorEnabled = false

    override func isVoiceOverRunning() -> Bool {
        return mockVoiceOverRunning
    }

    override func isSwitchControlRunning() -> Bool {
        return mockSwitchControlRunning
    }

    override func isInvertColorsEnabled() -> Bool {
        return mockInvertColorsEnabled
    }

    override func isBoldTextEnabled() -> Bool {
        return mockBoldTextEnabled
    }

    override func isReduceMotionEnabled() -> Bool {
        return mockReduceMotionEnabled
    }

    override func isDarkerSystemColorsEnabled() -> Bool {
        return mockDarkerSystemColorsEnabled
    }

    override func isOnOffSwitchLabelsEnabled() -> Bool {
        return mockOnOffSwitchLabelsEnabled
    }

    override func isAnimatedImagesAutoPlayEnabled() -> Bool {
        return mockAnimatedImagesAutoPlayEnabled
    }

    override func isVideosAutoPlayEnabled() -> Bool {
        return mockVideosAutoPlayEnabled
    }

    override func isDeterministicCursorEnabled() -> Bool {
        return mockDeterministicCursorEnabled
    }
}

struct AccessibilityFeaturesTests {
    @Test func accessibilityFeatureFlagRawValuesAreCorrect() {
        #expect(AccessibilityFeatureFlag.accessibleNavigation.rawValue == 1 << 0)
        #expect(AccessibilityFeatureFlag.invertColors.rawValue == 1 << 1)
        #expect(AccessibilityFeatureFlag.disableAnimations.rawValue == 1 << 2)
        #expect(AccessibilityFeatureFlag.boldText.rawValue == 1 << 3)
        #expect(AccessibilityFeatureFlag.reduceMotion.rawValue == 1 << 4)
        #expect(AccessibilityFeatureFlag.highContrast.rawValue == 1 << 5)
        #expect(AccessibilityFeatureFlag.onOffSwitchLabels.rawValue == 1 << 6)
        #expect(AccessibilityFeatureFlag.noAnnounce.rawValue == 1 << 7)
        #expect(AccessibilityFeatureFlag.noAutoPlayAnimatedImages.rawValue == 1 << 8)
        #expect(AccessibilityFeatureFlag.noAutoPlayVideos.rawValue == 1 << 9)
        #expect(AccessibilityFeatureFlag.deterministicCursor.rawValue == 1 << 10)
    }

    @Test @MainActor
    func flagsBitmaskIsCorrect() {
        let features = MockAccessibilityFeatures()
        #expect(features.flags == 0)

        features.mockVoiceOverRunning = true
        #expect(
            AccessibilityFeatureFlag(rawValue: features.flags).contains(.accessibleNavigation)
        )
        features.mockVoiceOverRunning = false

        features.mockSwitchControlRunning = true
        #expect(
            AccessibilityFeatureFlag(rawValue: features.flags).contains(.accessibleNavigation)
        )
        features.mockSwitchControlRunning = false

        features.mockInvertColorsEnabled = true
        #expect(AccessibilityFeatureFlag(rawValue: features.flags).contains(.invertColors))
        features.mockInvertColorsEnabled = false

        features.mockBoldTextEnabled = true
        #expect(AccessibilityFeatureFlag(rawValue: features.flags).contains(.boldText))
        features.mockBoldTextEnabled = false

        features.mockReduceMotionEnabled = true
        #expect(AccessibilityFeatureFlag(rawValue: features.flags).contains(.reduceMotion))
        features.mockReduceMotionEnabled = false

        features.mockDarkerSystemColorsEnabled = true
        #expect(AccessibilityFeatureFlag(rawValue: features.flags).contains(.highContrast))
        features.mockDarkerSystemColorsEnabled = false

        features.mockOnOffSwitchLabelsEnabled = true
        #expect(AccessibilityFeatureFlag(rawValue: features.flags).contains(.onOffSwitchLabels))
        features.mockOnOffSwitchLabelsEnabled = false

        features.mockAnimatedImagesAutoPlayEnabled = false
        #expect(
            AccessibilityFeatureFlag(rawValue: features.flags).contains(.noAutoPlayAnimatedImages)
        )
        features.mockAnimatedImagesAutoPlayEnabled = true

        features.mockVideosAutoPlayEnabled = false
        #expect(
            AccessibilityFeatureFlag(rawValue: features.flags).contains(.noAutoPlayVideos)
        )
        features.mockVideosAutoPlayEnabled = true

        features.mockDeterministicCursorEnabled = true
        #expect(AccessibilityFeatureFlag(rawValue: features.flags).contains(.deterministicCursor))
        features.mockDeterministicCursorEnabled = false

        features.mockBoldTextEnabled = true
        features.mockReduceMotionEnabled = true
        features.mockOnOffSwitchLabelsEnabled = true
        #expect(
            features.flags == AccessibilityFeatureFlag([.boldText, .reduceMotion, .onOffSwitchLabels]).rawValue
        )
    }

    @Test func observedNotificationNamesContainsAllNotifications() {
        let features = AccessibilityFeatures()
        let names = features.observedNotificationNames

        #expect(names.contains(UIAccessibility.voiceOverStatusDidChangeNotification.rawValue))
        #expect(names.contains(UIAccessibility.switchControlStatusDidChangeNotification.rawValue))
        #expect(names.contains(UIAccessibility.speakScreenStatusDidChangeNotification.rawValue))
        #expect(names.contains(UIAccessibility.invertColorsStatusDidChangeNotification.rawValue))
        #expect(names.contains(UIAccessibility.reduceMotionStatusDidChangeNotification.rawValue))
        #expect(names.contains(UIAccessibility.boldTextStatusDidChangeNotification.rawValue))
        #expect(
            names.contains(UIAccessibility.darkerSystemColorsStatusDidChangeNotification.rawValue)
        )
        #expect(names.contains(UIAccessibility.onOffSwitchLabelsDidChangeNotification.rawValue))
        #expect(names.contains(UIAccessibility.videoAutoplayStatusDidChangeNotification.rawValue))

        if #available(iOS 18.0, *) {
            #expect(
                names.contains(AccessibilitySettings.animatedImagesEnabledDidChangeNotification.rawValue)
            )
            #expect(
                names.contains(
                    AccessibilitySettings.prefersNonBlinkingTextInsertionIndicatorDidChangeNotification.rawValue
                )
            )
            #expect(names.count == 11, "Should be 11 notifications on iOS 18+")
        } else {
            #expect(names.count == 9, "Should be 9 notifications before iOS 18")
        }
    }
}
