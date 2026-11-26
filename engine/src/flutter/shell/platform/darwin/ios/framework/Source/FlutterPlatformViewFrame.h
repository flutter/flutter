// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWFRAME_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWFRAME_H_

#import <UIKit/UIKit.h>

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViewLayer.h"

NS_ASSUME_NONNULL_BEGIN

/// The Flutter content painted above a platform view.
///
/// `FlutterPlatformViewsController` displays the content in two views. `view` renders it to a
/// surface the size of the Flutter view, and `clippingView` clips `view` to `rect`. Resizing a
/// surface reallocates its textures, so the controller resizes `clippingView` when `rect` changes
/// and leaves `view` the size of the Flutter view.
@interface FlutterPlatformViewOverlay : NSObject

/// The view that the Flutter content is rendered to.
///
/// This view is the size of the Flutter view.
@property(nonatomic, readonly) UIView* view;

/// The superview of `view`, which clips it to `rect`.
@property(nonatomic, readonly) UIView* clippingView;

/// The region of the Flutter view that the Flutter content covers, in physical pixels.
///
/// This is the smallest rect that contains the parts of the content that overlap this platform view
/// or any platform view below it.
@property(nonatomic, readonly) CGRect rect;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithView:(UIView*)view
                clippingView:(UIView*)clippingView
                        rect:(CGRect)rect NS_DESIGNATED_INITIALIZER;

@end

/// The platform views and overlays that make up one frame, along with the block that presents the
/// frame's Flutter content.
///
/// The raster thread builds each frame from the layer data produced by the engine, and hands it to
/// `[FlutterPlatformViewsController presentFrame:]` on the platform thread. That method updates the
/// platform views and overlays from this frame and invokes `present`.
@interface FlutterPlatformViewFrame : NSObject

/// The platform views in the frame, in composition order.
@property(nonatomic, readonly, copy) NSArray<FlutterPlatformViewLayer*>* layers;

/// The overlays in the frame, keyed by the ID of the platform view that each one is painted above.
@property(nonatomic, readonly, copy) NSDictionary<NSNumber*, FlutterPlatformViewOverlay*>* overlays;

/// The clipping views of the overlays that an earlier frame used and this frame does not.
///
/// `FlutterPlatformViewsController` removes them from the Flutter view in `presentFrame:`.
@property(nonatomic, readonly, copy) NSArray<UIView*>* unusedOverlayViews;

/// The number of physical pixels per point in the frame.
///
/// `FlutterPlatformViewsController` divides the rects, sizes, and transforms of the frame's layers
/// and overlays by this to convert them from physical pixels to points.
@property(nonatomic, readonly) CGFloat devicePixelRatio;

/// Presents the Flutter content of the frame.
///
/// `IOSExternalViewEmbedder` encodes the GPU work for the frame's surfaces before it builds the
/// frame, and this block presents them. `FlutterPlatformViewsController` calls this block in the
/// same `CATransaction` in which it updates the platform views and overlays.
@property(nonatomic, readonly, copy) void (^present)(void);

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithLayers:(NSArray<FlutterPlatformViewLayer*>*)layers
                      overlays:(NSDictionary<NSNumber*, FlutterPlatformViewOverlay*>*)overlays
            unusedOverlayViews:(NSArray<UIView*>*)unusedOverlayViews
              devicePixelRatio:(CGFloat)devicePixelRatio
                       present:(void (^)(void))present NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWFRAME_H_
