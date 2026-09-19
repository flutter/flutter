// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERDISPLAYFEATURES_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERDISPLAYFEATURES_H_

#import <UIKit/UIKit.h>

#include <vector>

NS_ASSUME_NONNULL_BEGIN

/// Mirrors the index order of `dart:ui`'s `DisplayFeatureType`.
typedef NS_ENUM(NSInteger, FlutterDisplayFeatureType) {
  FlutterDisplayFeatureTypeUnknown = 0,
  FlutterDisplayFeatureTypeFold = 1,
  FlutterDisplayFeatureTypeHinge = 2,
  FlutterDisplayFeatureTypeCutout = 3,
};

/// Mirrors the index order of `dart:ui`'s `DisplayFeatureState`.
typedef NS_ENUM(NSInteger, FlutterDisplayFeatureState) {
  FlutterDisplayFeatureStateUnknown = 0,
  FlutterDisplayFeatureStatePostureFlat = 1,
  FlutterDisplayFeatureStatePostureHalfOpened = 2,
};

/// Mirrors the raw values of `UIHingeStatus` (iOS 27.1), so the mapping below
/// can be exercised without the SDK that declares the real enum.
typedef NS_ENUM(NSInteger, FlutterHingeStatus) {
  FlutterHingeStatusUnknown = 0,
  FlutterHingeStatusClosed = 1,
  FlutterHingeStatusPartiallyOpen = 2,
  FlutterHingeStatusFullyOpen = 3,
};

/// A reserved region as read from `UIView.reservedRegions(kind:options:)`,
/// reduced to what the mapping needs.
struct FlutterReservedRegionInfo {
  /// In the view's logical coordinates (points).
  CGRect frame;
  /// True for `.division` (the fold), false for `.occlusion` (a camera).
  bool isDivision;
  /// A division is inactive while the device is flat. This lags the hinge.
  bool isActive;
};

/// Display features in logical pixels, laid out the way `ViewportMetrics`
/// expects: four doubles per feature (left, top, right, bottom) and one type
/// and one state per feature. The caller scales `bounds` by the device pixel
/// ratio.
struct FlutterDisplayFeatureList {
  std::vector<double> bounds;
  std::vector<int> types;
  std::vector<int> states;
};

/// Converts the hinge posture and reserved regions into display features.
///
/// Rules, each of which exists to keep `DisplayFeatureSubScreen` from
/// splitting an app's layout when there is no visible fold:
///
/// * Nothing is reported while the device is closed. `dart:ui` has no closed
///   posture, and with the device shut the view is on the cover display, which
///   has no fold.
/// * A division is only reported while the hinge is partially open. The
///   hinge status is immediate, but a region's `isActive` lags it: measured on
///   the iPhone Duo simulator, a division still reads active inside the update
///   handler that reports fully open, and clears a few milliseconds later with
///   no further hinge update or layout pass to pick that up. Trusting it would
///   leave a 40pt `postureFlat` fold splitting every dialog on a flat device.
/// * Inactive regions are never reported.
/// * A region whose shortest side is zero is never reported. Combined with
///   `postureHalfOpened` it would still satisfy
///   `DisplayFeatureSubScreen.avoidBounds` and split the screen in two.
/// * Occlusions become `cutout` with state `unknown`, which `dart:ui` asserts.
/// * Divisions become `fold`, not `hinge`: the inner display is one continuous
///   panel with no physical gap between two separate screens.
FlutterDisplayFeatureList FlutterDisplayFeaturesFromRegions(
    FlutterHingeStatus status,
    const std::vector<FlutterReservedRegionInfo>& regions);

/// Delivers the current display features. Called on the main thread.
typedef void (^FlutterDisplayFeaturesUpdateBlock)(const FlutterDisplayFeatureList& features);

/// Observes the hinge and the reserved regions of a view and reports them as
/// display features whenever either changes.
///
/// The hinge APIs ship in the iOS 27.1 SDK. When the engine is built against an
/// older SDK this class still exists but `init` returns nil, so callers need
/// only an `@available(iOS 27.1, *)` check.
API_AVAILABLE(ios(27.1))
@interface FlutterDisplayFeaturesMonitor : NSObject

/// Starts observing `view`. Returns nil when the SDK the engine was built with
/// does not declare the hinge APIs.
- (nullable instancetype)initWithView:(UIView*)view
                             onUpdate:(FlutterDisplayFeaturesUpdateBlock)onUpdate
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// Re-reads the reserved regions and reports again.
///
/// This must be called from the view controller's `viewDidLayoutSubviews`.
/// Reserved regions lag the hinge, and UIKit offers no notification for them;
/// instead it tracks a read made during layout and runs layout again when the
/// region changes. Measured on the iPhone Duo simulator: with the read inside
/// `viewDidLayoutSubviews`, a layout pass follows every change of the division
/// (about a second after the hinge reads partially open, and within 15 ms of
/// it reading fully open). With the read made only outside layout, no layout
/// pass follows at all, because the view's bounds do not change while folding.
- (void)refresh;

/// Stops observing and releases the interaction.
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERDISPLAYFEATURES_H_
