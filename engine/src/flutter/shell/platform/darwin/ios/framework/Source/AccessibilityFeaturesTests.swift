// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Accessibility
import UIKit
import XCTest

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

class AccessibilityFeaturesTests: XCTestCase {
    func testAccessibilityFeatureFlagRawValuesAreCorrect() {
        XCTAssertEqual(AccessibilityFeatureFlag.accessibleNavigation.rawValue, 1 << 0)
        XCTAssertEqual(AccessibilityFeatureFlag.invertColors.rawValue, 1 << 1)
        XCTAssertEqual(AccessibilityFeatureFlag.disableAnimations.rawValue, 1 << 2)
        XCTAssertEqual(AccessibilityFeatureFlag.boldText.rawValue, 1 << 3)
        XCTAssertEqual(AccessibilityFeatureFlag.reduceMotion.rawValue, 1 << 4)
        XCTAssertEqual(AccessibilityFeatureFlag.highContrast.rawValue, 1 << 5)
        XCTAssertEqual(AccessibilityFeatureFlag.onOffSwitchLabels.rawValue, 1 << 6)
        XCTAssertEqual(AccessibilityFeatureFlag.noAnnounce.rawValue, 1 << 7)
        XCTAssertEqual(AccessibilityFeatureFlag.noAutoPlayAnimatedImages.rawValue, 1 << 8)
        XCTAssertEqual(AccessibilityFeatureFlag.noAutoPlayVideos.rawValue, 1 << 9)
        XCTAssertEqual(AccessibilityFeatureFlag.deterministicCursor.rawValue, 1 << 10)
    }
    
    func testFlagsBitmaskIsCorrect() {
        let features = MockAccessibilityFeatures()
        XCTAssertEqual(features.flags, 0)
        
        features.mockVoiceOverRunning = true
        XCTAssertTrue(
            AccessibilityFeatureFlag(rawValue: features.flags).contains(.accessibleNavigation)
        )
        features.mockVoiceOverRunning = false
        
        features.mockSwitchControlRunning = true
        XCTAssertTrue(
            AccessibilityFeatureFlag(rawValue: features.flags).contains(.accessibleNavigation)
        )
        features.mockSwitchControlRunning = false
        
        features.mockInvertColorsEnabled = true
        XCTAssertTrue(AccessibilityFeatureFlag(rawValue: features.flags).contains(.invertColors))
        features.mockInvertColorsEnabled = false
        
        features.mockBoldTextEnabled = true
        XCTAssertTrue(AccessibilityFeatureFlag(rawValue: features.flags).contains(.boldText))
        features.mockBoldTextEnabled = false
        
        features.mockReduceMotionEnabled = true
        XCTAssertTrue(AccessibilityFeatureFlag(rawValue: features.flags).contains(.reduceMotion))
        features.mockReduceMotionEnabled = false
        
        features.mockDarkerSystemColorsEnabled = true
        XCTAssertTrue(AccessibilityFeatureFlag(rawValue: features.flags).contains(.highContrast))
        features.mockDarkerSystemColorsEnabled = false
        
        features.mockOnOffSwitchLabelsEnabled = true
        XCTAssertTrue(AccessibilityFeatureFlag(rawValue: features.flags).contains(.onOffSwitchLabels))
        features.mockOnOffSwitchLabelsEnabled = false
        
        features.mockAnimatedImagesAutoPlayEnabled = false
        XCTAssertTrue(
            AccessibilityFeatureFlag(rawValue: features.flags).contains(.noAutoPlayAnimatedImages)
        )
        features.mockAnimatedImagesAutoPlayEnabled = true
        
        features.mockVideosAutoPlayEnabled = false
        XCTAssertTrue(
            AccessibilityFeatureFlag(rawValue: features.flags).contains(.noAutoPlayVideos)
        )
        features.mockVideosAutoPlayEnabled = true
        
        features.mockDeterministicCursorEnabled = true
        XCTAssertTrue(AccessibilityFeatureFlag(rawValue: features.flags).contains(.deterministicCursor))
        features.mockDeterministicCursorEnabled = false
        
        features.mockBoldTextEnabled = true
        features.mockReduceMotionEnabled = true
        features.mockOnOffSwitchLabelsEnabled = true
        XCTAssertEqual(
            features.flags,
            AccessibilityFeatureFlag([.boldText, .reduceMotion, .onOffSwitchLabels]).rawValue
        )
    }
    
    func testObservedNotificationNamesContainsAllNotifications() {
        let features = AccessibilityFeatures()
        let names = features.observedNotificationNames
        
        XCTAssertTrue(names.contains(UIAccessibility.voiceOverStatusDidChangeNotification.rawValue))
        XCTAssertTrue(names.contains(UIAccessibility.switchControlStatusDidChangeNotification.rawValue))
        XCTAssertTrue(names.contains(UIAccessibility.speakScreenStatusDidChangeNotification.rawValue))
        XCTAssertTrue(names.contains(UIAccessibility.invertColorsStatusDidChangeNotification.rawValue))
        XCTAssertTrue(names.contains(UIAccessibility.reduceMotionStatusDidChangeNotification.rawValue))
        XCTAssertTrue(names.contains(UIAccessibility.boldTextStatusDidChangeNotification.rawValue))
        XCTAssertTrue(
            names.contains(UIAccessibility.darkerSystemColorsStatusDidChangeNotification.rawValue)
        )
        XCTAssertTrue(names.contains(UIAccessibility.onOffSwitchLabelsDidChangeNotification.rawValue))
        XCTAssertTrue(names.contains(UIAccessibility.videoAutoplayStatusDidChangeNotification.rawValue))
        
        if #available(iOS 18.0, *) {
            XCTAssertTrue(
                names.contains(AccessibilitySettings.animatedImagesEnabledDidChangeNotification.rawValue)
            )
            XCTAssertTrue(
                names.contains(
                    AccessibilitySettings.prefersNonBlinkingTextInsertionIndicatorDidChangeNotification.rawValue
                )
            )
            XCTAssertEqual(names.count, 11, "Should be 11 notifications on iOS 18+")
        } else {
            XCTAssertEqual(names.count, 9, "Should be 9 notifications before iOS 18")
        }
    }
}
