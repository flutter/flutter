// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterDisplayFeatures.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"

FLUTTER_ASSERT_ARC

// Mirrors the test-only category in FlutterViewControllerTest.mm: this method is
// not part of any shared header, so it has to be declared here to be mockable.
@interface FlutterViewController (DisplayFeaturesTest)
- (void)updateViewportMetricsIfNeeded;
@end

namespace {

// The iPhone Duo inner display as measured on the simulator: 951x669pt with a
// 40pt fold division through the centre.
constexpr CGFloat kInnerWidth = 951;
constexpr CGFloat kInnerHeight = 669;

FlutterReservedRegionInfo Division(CGFloat width, bool active) {
  return {CGRectMake((kInnerWidth - width) / 2, 0, width, kInnerHeight), /*isDivision=*/true,
          active};
}

FlutterReservedRegionInfo Occlusion(bool active) {
  return {CGRectMake(867, 0, 84, 120), /*isDivision=*/false, active};
}

}  // namespace

@interface FlutterDisplayFeaturesTest : XCTestCase
@end

@implementation FlutterDisplayFeaturesTest

#pragma mark - Mapping

- (void)testPartiallyOpenDivisionBecomesHalfOpenedFold {
  FlutterDisplayFeatureList features =
      FlutterDisplayFeaturesFromRegions(FlutterHingeStatusPartiallyOpen, {Division(40, true)});

  XCTAssertEqual(features.types.size(), 1u);
  XCTAssertEqual(features.types[0], FlutterDisplayFeatureTypeFold);
  XCTAssertEqual(features.states[0], FlutterDisplayFeatureStatePostureHalfOpened);
  // Bounds are left, top, right, bottom in logical pixels.
  XCTAssertEqual(features.bounds.size(), 4u);
  XCTAssertEqualWithAccuracy(features.bounds[0], 455.5, 0.01);
  XCTAssertEqualWithAccuracy(features.bounds[1], 0, 0.01);
  XCTAssertEqualWithAccuracy(features.bounds[2], 495.5, 0.01);
  XCTAssertEqualWithAccuracy(features.bounds[3], kInnerHeight, 0.01);
}

- (void)testFullyOpenReportsNoFoldEvenIfTheDivisionStillReadsActive {
  // isActive lags the hinge: in the update that reports fully open the division
  // still reads active, and nothing follows to correct it. A 40pt postureFlat
  // fold would split every dialog on a device lying flat.
  FlutterDisplayFeatureList features =
      FlutterDisplayFeaturesFromRegions(FlutterHingeStatusFullyOpen, {Division(40, true)});

  XCTAssertTrue(features.types.empty());
}

- (void)testFullyOpenStillReportsAnActiveOcclusion {
  FlutterDisplayFeatureList features = FlutterDisplayFeaturesFromRegions(
      FlutterHingeStatusFullyOpen, {Division(40, true), Occlusion(true)});

  XCTAssertEqual(features.types.size(), 1u);
  XCTAssertEqual(features.types[0], FlutterDisplayFeatureTypeCutout);
}

- (void)testClosedReportsNothing {
  // The view is on the cover display, which has no fold, and dart:ui has no
  // closed posture to describe it with.
  FlutterDisplayFeatureList features = FlutterDisplayFeaturesFromRegions(
      FlutterHingeStatusClosed, {Division(40, true), Occlusion(true)});

  XCTAssertTrue(features.bounds.empty());
  XCTAssertTrue(features.types.empty());
  XCTAssertTrue(features.states.empty());
}

- (void)testInactiveDivisionIsDropped {
  FlutterDisplayFeatureList features =
      FlutterDisplayFeaturesFromRegions(FlutterHingeStatusFullyOpen, {Division(40, false)});

  XCTAssertTrue(features.types.empty());
}

- (void)testZeroWidthDivisionIsDroppedEvenWhenHalfOpened {
  // This is the combination that would split the screen with no visible fold:
  // DisplayFeatureSubScreen.avoidBounds treats a zero-width feature as an
  // obstruction when its state is postureHalfOpened.
  FlutterDisplayFeatureList features =
      FlutterDisplayFeaturesFromRegions(FlutterHingeStatusPartiallyOpen, {Division(0, true)});

  XCTAssertTrue(features.types.empty());
}

- (void)testOcclusionBecomesCutoutWithUnknownState {
  FlutterDisplayFeatureList features =
      FlutterDisplayFeaturesFromRegions(FlutterHingeStatusPartiallyOpen, {Occlusion(true)});

  XCTAssertEqual(features.types.size(), 1u);
  XCTAssertEqual(features.types[0], FlutterDisplayFeatureTypeCutout);
  // dart:ui asserts this pairing in the DisplayFeature constructor.
  XCTAssertEqual(features.states[0], FlutterDisplayFeatureStateUnknown);
}

- (void)testInactiveOcclusionIsDropped {
  FlutterDisplayFeatureList features =
      FlutterDisplayFeaturesFromRegions(FlutterHingeStatusFullyOpen, {Occlusion(false)});

  XCTAssertTrue(features.types.empty());
}

- (void)testMixedRegionsKeepOrderAndParallelVectors {
  FlutterDisplayFeatureList features = FlutterDisplayFeaturesFromRegions(
      FlutterHingeStatusPartiallyOpen, {Division(40, true), Occlusion(true), Division(0, true)});

  XCTAssertEqual(features.types.size(), 2u);
  XCTAssertEqual(features.states.size(), 2u);
  XCTAssertEqual(features.bounds.size(), 8u);
  XCTAssertEqual(features.types[0], FlutterDisplayFeatureTypeFold);
  XCTAssertEqual(features.types[1], FlutterDisplayFeatureTypeCutout);
}

- (void)testUnknownStatusReportsNoFold {
  FlutterDisplayFeatureList features =
      FlutterDisplayFeaturesFromRegions(FlutterHingeStatusUnknown, {Division(40, true)});

  XCTAssertTrue(features.types.empty());
}

#pragma mark - Settling

- (void)testPartiallyOpenWithInactiveDivisionIsNotSettled {
  // Folding the device: the status is already partially open but the division
  // only becomes active once the hinge comes to rest.
  XCTAssertFalse(FlutterDisplayFeaturesRegionsAreSettled(FlutterHingeStatusPartiallyOpen,
                                                         {Division(40, false)}));
}

- (void)testPartiallyOpenWithActiveDivisionIsSettled {
  XCTAssertTrue(FlutterDisplayFeaturesRegionsAreSettled(FlutterHingeStatusPartiallyOpen,
                                                        {Division(40, true)}));
}

- (void)testPartiallyOpenWithoutADivisionIsSettled {
  // Built against an older SDK, or a window with no fold in it: there is
  // nothing to wait for.
  XCTAssertTrue(FlutterDisplayFeaturesRegionsAreSettled(FlutterHingeStatusPartiallyOpen, {}));
  XCTAssertTrue(
      FlutterDisplayFeaturesRegionsAreSettled(FlutterHingeStatusPartiallyOpen, {Occlusion(false)}));
}

- (void)testOtherPosturesAreAlwaysSettled {
  // No fold is reported outside partially open, so a stale isActive is moot.
  XCTAssertTrue(
      FlutterDisplayFeaturesRegionsAreSettled(FlutterHingeStatusFullyOpen, {Division(40, true)}));
  XCTAssertTrue(
      FlutterDisplayFeaturesRegionsAreSettled(FlutterHingeStatusClosed, {Division(40, false)}));
  XCTAssertTrue(
      FlutterDisplayFeaturesRegionsAreSettled(FlutterHingeStatusUnknown, {Division(40, false)}));
}

#pragma mark - Viewport metrics

// ViewportMetrics is a C++ struct passed by value, so its contents cannot be
// captured through OCMock. These tests follow the existing convention in
// FlutterViewControllerTest and verify the call into the send path instead;
// the values themselves are covered by the mapping tests above.

- (FlutterViewController*)viewControllerWithMockEngine {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];
  mockEngine.viewController = viewController;
  return viewController;
}

- (void)testApplyDisplayFeaturesSendsViewportMetrics {
  id mockVC = OCMPartialMock([self viewControllerWithMockEngine]);
  OCMExpect([mockVC updateViewportMetricsIfNeeded]);

  [mockVC applyDisplayFeatures:FlutterDisplayFeaturesFromRegions(FlutterHingeStatusPartiallyOpen,
                                                                 {Division(40, true)})];

  OCMVerifyAll(mockVC);
}

- (void)testApplyingUnchangedDisplayFeaturesDoesNotResend {
  id mockVC = OCMPartialMock([self viewControllerWithMockEngine]);
  FlutterDisplayFeatureList features =
      FlutterDisplayFeaturesFromRegions(FlutterHingeStatusPartiallyOpen, {Division(40, true)});
  [mockVC applyDisplayFeatures:features];

  // Layout passes call refresh often; identical features must not flood the
  // engine with metric updates.
  OCMReject([mockVC updateViewportMetricsIfNeeded]);
  [mockVC applyDisplayFeatures:features];

  OCMVerifyAll(mockVC);
}

- (void)testApplyingEmptyAfterNonEmptyResendsToClear {
  id mockVC = OCMPartialMock([self viewControllerWithMockEngine]);
  [mockVC applyDisplayFeatures:FlutterDisplayFeaturesFromRegions(FlutterHingeStatusPartiallyOpen,
                                                                 {Division(40, true)})];

  // Folding shut: the platform reports closed and the features must go away,
  // which is a change and therefore has to be sent.
  OCMExpect([mockVC updateViewportMetricsIfNeeded]);
  [mockVC applyDisplayFeatures:FlutterDisplayFeaturesFromRegions(FlutterHingeStatusClosed,
                                                                 {Division(40, true)})];

  OCMVerifyAll(mockVC);
}

- (void)testApplyingEmptyWhenAlreadyEmptyDoesNotSend {
  id mockVC = OCMPartialMock([self viewControllerWithMockEngine]);

  // A device without a hinge reports empty forever; that must stay silent.
  OCMReject([mockVC updateViewportMetricsIfNeeded]);
  [mockVC applyDisplayFeatures:FlutterDisplayFeatureList()];

  OCMVerifyAll(mockVC);
}

@end
