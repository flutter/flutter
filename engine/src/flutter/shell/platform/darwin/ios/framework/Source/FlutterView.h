// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVIEW_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVIEW_H_

#import <Metal/Metal.h>
#import <UIKit/UIKit.h>

#include "flutter/shell/common/rasterizer.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"

@protocol FlutterViewEngineDelegate <NSObject>

@property(nonatomic, readonly) FlutterPlatformViewsController* platformViewsController;

- (flutter::Rasterizer::Screenshot)takeScreenshot:(flutter::Rasterizer::ScreenshotType)type
                                  asBase64Encoded:(BOOL)base64Encode;

/**
 * A callback that is called when iOS queries accessibility information of the Flutter view.
 *
 * This is useful to predict the current iOS accessibility status. For example, there is
 * no API to listen whether voice control is turned on or off. The Flutter engine uses
 * this callback to enable semantics in order to catch the case that voice control is
 * on.
 */
- (void)flutterViewAccessibilityDidCall;
@end

/**
 * A custom NSLayoutConstraint subclass for autoresizing the FlutterView.
 * This class is a special NSLayoutConstraint used internally to
 * manage the dynamic resizing of a FlutterView based on its content.
 *
 * In native, `intrinsicContentSize` is a public property that determines the preferred
 * sized of an UIView, based on it's internal content. Given a position and layout constraints,
 * this allows the UIView to size itself.
 * However, the mechanism in which this sizing occurs based on`intrinsicContentSize`
 * and the layout constraints is private.
 *
 * This custom NSLayoutConstraint allows us to replicate this mechanizm without needing to rely
 * on private APIs.
 */
@interface FlutterAutoResizeLayoutConstraint : NSLayoutConstraint
@end

@interface FlutterView : UIView

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder*)aDecoder NS_UNAVAILABLE;

- (instancetype)initWithDelegate:(id<FlutterViewEngineDelegate>)delegate
                          opaque:(BOOL)opaque
                 enableWideGamut:(BOOL)isWideGamutEnabled NS_DESIGNATED_INITIALIZER;

- (UIScreen*)screen;
- (MTLPixelFormat)pixelFormat;

/**
 * A method that sets the instrinsic content size
 * This is used when autoResizable is enabled.
 */
- (void)setIntrinsicContentSize:(CGSize)size;

/**
 * A method that resets and recalculates the instrinsic content size
 * Currently called when the device orientation changes.
 */
- (void)resetIntrinsicContentSize;
@property(nonatomic, assign, readwrite) BOOL autoResizable;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVIEW_H_
