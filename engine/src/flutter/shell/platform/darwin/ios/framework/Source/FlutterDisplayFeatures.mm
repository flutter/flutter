// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterDisplayFeatures.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"

FLUTTER_ASSERT_ARC

FlutterDisplayFeatureList FlutterDisplayFeaturesFromRegions(
    FlutterHingeStatus status,
    const std::vector<FlutterReservedRegionInfo>& regions) {
  FlutterDisplayFeatureList result;

  // With the device closed the view is on the cover display, which has no fold,
  // and dart:ui has no posture to describe "closed" anyway.
  if (status == FlutterHingeStatusClosed) {
    return result;
  }

  for (const FlutterReservedRegionInfo& region : regions) {
    if (!region.isActive) {
      continue;
    }
    // A zero-width feature still trips DisplayFeatureSubScreen.avoidBounds when
    // its state is postureHalfOpened, splitting the screen with no visible fold.
    if (CGRectGetWidth(region.frame) <= 0 || CGRectGetHeight(region.frame) <= 0) {
      continue;
    }

    FlutterDisplayFeatureType type;
    FlutterDisplayFeatureState state;
    if (region.isDivision) {
      // The hinge status is immediate; isActive lags it and can still read true
      // in the very update that reports fully open, with nothing following to
      // correct it. The posture therefore decides whether there is a fold.
      if (status != FlutterHingeStatusPartiallyOpen) {
        continue;
      }
      // The inner display is one continuous panel; there is no physical gap, so
      // this is a fold rather than a hinge.
      type = FlutterDisplayFeatureTypeFold;
      state = FlutterDisplayFeatureStatePostureHalfOpened;
    } else {
      // dart:ui asserts that a cutout carries the unknown state.
      type = FlutterDisplayFeatureTypeCutout;
      state = FlutterDisplayFeatureStateUnknown;
    }

    result.bounds.push_back(CGRectGetMinX(region.frame));
    result.bounds.push_back(CGRectGetMinY(region.frame));
    result.bounds.push_back(CGRectGetMaxX(region.frame));
    result.bounds.push_back(CGRectGetMaxY(region.frame));
    result.types.push_back(static_cast<int>(type));
    result.states.push_back(static_cast<int>(state));
  }
  return result;
}

#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 270100

// The hinge and reserved-region APIs are declared by the iOS 27.1 SDK. This
// implementation is only compiled when building against that SDK or newer; the
// stub below stands in otherwise so callers need no compile-time guard.

@interface FlutterDisplayFeaturesMonitor ()
@property(nonatomic, weak) UIView* view;
@property(nonatomic, copy) FlutterDisplayFeaturesUpdateBlock onUpdate;
@property(nonatomic, strong, nullable) UIHingeInteraction* interaction;
@property(nonatomic, assign) FlutterHingeStatus status;
@end

@implementation FlutterDisplayFeaturesMonitor

- (nullable instancetype)initWithView:(UIView*)view
                             onUpdate:(FlutterDisplayFeaturesUpdateBlock)onUpdate {
  self = [super init];
  if (self) {
    _view = view;
    _onUpdate = [onUpdate copy];
    _status = FlutterHingeStatusUnknown;

    __weak FlutterDisplayFeaturesMonitor* weakSelf = self;
    _interaction = [[UIHingeInteraction alloc]
        initWithUpdateHandler:^(UIHingeInteraction* _Nonnull, UIHingeInteractionUpdate* update) {
          FlutterDisplayFeaturesMonitor* strongSelf = weakSelf;
          if (!strongSelf) {
            return;
          }
          // A nil hinge means this device has none, or the interaction left a
          // hierarchy that provides hinge updates.
          UIHinge* hinge = update.hinge;
          strongSelf.status =
              hinge ? static_cast<FlutterHingeStatus>(hinge.status) : FlutterHingeStatusUnknown;
          [strongSelf refresh];
        }];
    [view addInteraction:_interaction];
  }
  return self;
}

- (void)refresh {
  UIView* view = self.view;
  if (!view) {
    return;
  }

  std::vector<FlutterReservedRegionInfo> regions;
  // The fold is inactive while the device is flat, so it is requested with
  // includeInactive; the mapping drops inactive regions itself, and this keeps
  // the query, and so the dependency UIKit tracks, identical across postures.
  for (UIViewReservedRegion* region in
       [view reservedRegionsOfKind:UIViewReservedRegionKind.divisionRegionKind
                           options:UIViewReservedRegionQueryOptionsIncludeInactive]) {
    regions.push_back({region.frame, /*isDivision=*/true, region.isActive});
  }
  // An occlusion is only active while that camera is in use.
  for (UIViewReservedRegion* region in
       [view reservedRegionsOfKind:UIViewReservedRegionKind.occlusionRegionKind
                           options:UIViewReservedRegionQueryOptionsNone]) {
    regions.push_back({region.frame, /*isDivision=*/false, region.isActive});
  }

  if (self.onUpdate) {
    self.onUpdate(FlutterDisplayFeaturesFromRegions(self.status, regions));
  }
}

- (void)invalidate {
  if (self.interaction) {
    [self.view removeInteraction:self.interaction];
    self.interaction = nil;
  }
  self.onUpdate = nil;
}

@end

#else  // __IPHONE_OS_VERSION_MAX_ALLOWED < 270100

// Built against an SDK without the hinge APIs: nothing to observe. Returning
// nil from init lets FlutterViewController keep a single code path.

@implementation FlutterDisplayFeaturesMonitor

- (nullable instancetype)initWithView:(UIView*)view
                             onUpdate:(FlutterDisplayFeaturesUpdateBlock)onUpdate {
  return nil;
}

- (void)refresh {
}

- (void)invalidate {
}

@end

#endif  // __IPHONE_OS_VERSION_MAX_ALLOWED
