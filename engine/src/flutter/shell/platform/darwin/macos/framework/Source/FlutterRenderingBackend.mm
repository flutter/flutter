// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterRenderingBackend.h"

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

@implementation FlutterRenderingBackend

+ (BOOL)renderUsingMetal {
#ifdef SHELL_ENABLE_METAL
  if (@available(macOS 10.14, *)) {
    BOOL systemSupportsMetal = MTLCreateSystemDefaultDevice() != nil;
    return systemSupportsMetal;
  }
#endif
  return NO;
}

+ (Class)layerClass {
  BOOL enableMetal = [FlutterRenderingBackend renderUsingMetal];
  if (enableMetal) {
    return [CAMetalLayer class];
  } else {
    return [CAOpenGLLayer class];
  }
}

+ (CALayer*)createBackingLayer {
  BOOL enableMetal = [FlutterRenderingBackend renderUsingMetal];
  if (enableMetal) {
    CAMetalLayer* metalLayer = [CAMetalLayer layer];
    // This is set to true to synchronize the presentation of the layer and its contents with Core
    // Animation. When presenting the texture see `[FlutterMetalResizableBackingStoreProvider
    // resizeSynchronizerCommit:]` we start a CATransaction and wait for the command buffer to be
    // scheduled. This ensures that the resizing process is smooth.
    metalLayer.presentsWithTransaction = YES;
    metalLayer.autoresizingMask = kCALayerHeightSizable | kCALayerWidthSizable;
    return metalLayer;
  } else {
    return [CAOpenGLLayer layer];
  }
}

@end
