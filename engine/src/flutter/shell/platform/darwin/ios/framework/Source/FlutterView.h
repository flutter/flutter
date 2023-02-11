// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_VIEW_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_VIEW_H_

#import <UIKit/UIKit.h>

#include <memory>

#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/shell/common/shell.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"
#import "flutter/shell/platform/darwin/ios/ios_context.h"
#import "flutter/shell/platform/darwin/ios/ios_surface.h"

@protocol FlutterViewEngineDelegate <NSObject>

- (flutter::Rasterizer::Screenshot)takeScreenshot:(flutter::Rasterizer::ScreenshotType)type
                                  asBase64Encoded:(BOOL)base64Encode;

- (std::shared_ptr<flutter::FlutterPlatformViewsController>&)platformViewsController;

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

@interface FlutterView : UIView

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder*)aDecoder NS_UNAVAILABLE;

- (instancetype)initWithDelegate:(id<FlutterViewEngineDelegate>)delegate
                          opaque:(BOOL)opaque
                 enableWideGamut:(BOOL)isWideGamutEnabled NS_DESIGNATED_INITIALIZER;

// Set by FlutterEngine or FlutterViewController to override software rendering.
@property(class, nonatomic) BOOL forceSoftwareRendering;
@end

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_VIEW_H_
