// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERMETALLAYER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERMETALLAYER_H_

#import <QuartzCore/QuartzCore.h>

/// A CAMetalLayer that provides Flutter with IOSurface-backed render targets
/// and presents their completed contents through the native drawable pipeline.
@interface FlutterMetalLayer : CAMetalLayer

/// Returns an IOSurface-backed drawable for Flutter rendering.
- (nullable id<CAMetalDrawable>)nextFlutterDrawable;

/// Returns whether the Metal layer is enabled.
/// This is controlled by FLTUseFlutterMetalLayer value in Info.plist.
+ (BOOL)enabled;

@end

@protocol MTLCommandBuffer;

@protocol FlutterMetalDrawable <CAMetalDrawable>

/// In order for FlutterMetalLayer to provide back pressure it must have access
/// to the command buffer that is used to render into the drawable to schedule
/// a completion handler.
/// This method must be called before the command buffer is committed.
- (void)flutterPrepareForPresent:(nonnull id<MTLCommandBuffer>)commandBuffer;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERMETALLAYER_H_
