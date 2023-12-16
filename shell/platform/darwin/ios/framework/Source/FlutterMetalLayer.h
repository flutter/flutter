// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <QuartzCore/QuartzCore.h>

/// Drop-in replacement (as far as Flutter is concerned) for CAMetalLayer
/// that can present with transaction from a background thread.
@interface FlutterMetalLayer : CALayer

@property(nullable, retain) id<MTLDevice> device;
@property(nullable, readonly) id<MTLDevice> preferredDevice;
@property MTLPixelFormat pixelFormat;
@property BOOL framebufferOnly;
@property CGSize drawableSize;
@property BOOL presentsWithTransaction;
@property(nullable) CGColorSpaceRef colorspace;
@property BOOL wantsExtendedDynamicRangeContent;

- (nullable id<CAMetalDrawable>)nextDrawable;

/// Returns whether the Metal layer is enabled.
/// This is controlled by FLTUseFlutterMetalLayer value in Info.plist.
+ (BOOL)enabled;

@end
