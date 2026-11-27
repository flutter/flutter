// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWSCONTROLLER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWSCONTROLLER_H_

#import <UIKit/UIKit.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPlatformViews.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPlugin.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunner.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewResponder.h"

NS_ASSUME_NONNULL_BEGIN

@class FlutterPlatformViewFrame;
@class FlutterPlatformViewLayer;
@class FlutterTouchInterceptingView;
@class FlutterClippingMaskViewPool;

@interface FlutterPlatformViewsController : NSObject

- (instancetype)init NS_DESIGNATED_INITIALIZER;

/// The task runner used to post rendering tasks to the platform thread.
@property(nonatomic, strong) FlutterFMLTaskRunner* taskRunner;

/// The view that displays the Flutter content, to which platform views are added as subviews.
///
/// `FlutterViewController` sets this when its surface appears, and sets it to nil when the surface
/// is destroyed.
@property(nonatomic, weak) UIView* _Nullable flutterView;

/// @brief The flutter view controller.
@property(nonatomic, weak) UIViewController<FlutterViewResponder>* _Nullable flutterViewController;

/// @brief set the factory used to construct embedded UI Views.
- (void)registerViewFactory:(NSObject<FlutterPlatformViewFactory>*)factory
                              withId:(NSString*)factoryId
    gestureRecognizersBlockingPolicy:
        (FlutterPlatformViewGestureRecognizersBlockingPolicy)gestureRecognizerBlockingPolicy;

/// @brief Returns the`FlutterTouchInterceptingView` with the provided view_id.
///
/// Returns nil if there is no platform view with the provided id. Called
/// from the platform thread.
- (FlutterTouchInterceptingView*)flutterTouchInterceptingViewForId:(int64_t)viewId;

/// @brief Discards all platform view instances and removes their views from the Flutter view.
///
/// `PlatformViewIOS::OnPreEngineRestart` calls this on the platform thread during hot restart.
///
/// This method doesn't clear the state of the frame being built (composition order, slices,
/// composition params, visited views). That state is managed by `IOSExternalViewEmbedder` on the
/// raster thread and is cleared in `IOSExternalViewEmbedder::PrepareFlutterView` at the start of
/// the next frame.
- (void)reset;

/// @brief Sets the intrinsic content size of the Flutter view to `frameSize`.
///
/// Must run on the platform thread.
- (void)performResize:(CGSize)frameSize;

/// @brief Update the buffers and mutate the platform views in CATransaction on the platform thread.
///
/// This method composites only the platform views whose layers in `frame` differ from the layers
/// they were last composited with.
///
/// Must run on the platform thread.
- (void)presentFrame:(FlutterPlatformViewFrame*)frame;

/// @brief Handler for platform view message channels.
- (void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;

/// @brief Returns the platform view id if the platform view (or any of its descendant view) is
/// the first responder.
///
/// Returns -1 if no such platform view is found.
- (long)firstResponderPlatformViewId;

@end

@interface FlutterPlatformViewsController (Testing)

// Returns the `FlutterPlatformView`'s `view` object associated with the view_id.
//
// If the `PlatformViewsController` does not contain any `FlutterPlatformView` object or
// a `FlutterPlatformView` object associated with the view_id cannot be found, the method
// returns nil.
- (UIView* _Nullable)platformViewForId:(int64_t)viewId;

// Composites the platform view described by `layer`.
//
// This method sets the frames of the view's |ChildClippingView| and |FlutterTouchInterceptingView|,
// then applies the layer's mutators.
//
// It divides by `devicePixelRatio` to convert the layer from physical pixels to points.
- (void)compositeLayer:(FlutterPlatformViewLayer*)layer devicePixelRatio:(CGFloat)devicePixelRatio;

/// @brief The composition order from the previous frame.
///
/// Only accessed from the platform thread.
- (NSArray<NSNumber*>*)previousCompositionOrder;

@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWSCONTROLLER_H_
