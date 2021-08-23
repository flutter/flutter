// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>
#import <OCMock/OCMock.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterSurfaceManager.h"
#include "flutter/testing/testing.h"
#include "gtest/gtest.h"

@interface TestMetalView : NSView

- (nonnull instancetype)init;

@end

@implementation TestMetalView

- (instancetype)init {
  self = [super initWithFrame:NSZeroRect];
  if (self) {
    [self setWantsLayer:YES];
  }
  return self;
}

@end

namespace flutter::testing {

static FlutterMetalSurfaceManager* CreateSurfaceManager() {
  id<MTLDevice> device = MTLCreateSystemDefaultDevice();
  id<MTLCommandQueue> commandQueue = [device newCommandQueue];
  TestMetalView* metalView = [[TestMetalView alloc] init];
  CALayer* layer = reinterpret_cast<CALayer*>(metalView.layer);
  return [[FlutterMetalSurfaceManager alloc] initWithDevice:device
                                               commandQueue:commandQueue
                                                      layer:layer];
}

TEST(FlutterMetalSurfaceManager, EnsureSizeUpdatesSize) {
  FlutterMetalSurfaceManager* surfaceManager = CreateSurfaceManager();
  CGSize size = CGSizeMake(100, 50);
  [surfaceManager ensureSurfaceSize:size];
  id<MTLTexture> texture =
      (reinterpret_cast<FlutterMetalRenderBackingStore*>([surfaceManager renderBuffer])).texture;
  CGSize textureSize = CGSizeMake(texture.width, texture.height);
  ASSERT_TRUE(CGSizeEqualToSize(size, textureSize));
}

TEST(FlutterMetalSurfaceManager, EnsureSizeUpdatesSizeForBackBuffer) {
  FlutterMetalSurfaceManager* surfaceManager = CreateSurfaceManager();
  CGSize size = CGSizeMake(100, 50);
  [surfaceManager ensureSurfaceSize:size];
  [surfaceManager renderBuffer];  // make sure we have back buffer
  [surfaceManager swapBuffers];
  id<MTLTexture> texture =
      (reinterpret_cast<FlutterMetalRenderBackingStore*>([surfaceManager renderBuffer])).texture;
  CGSize textureSize = CGSizeMake(texture.width, texture.height);
  ASSERT_TRUE(CGSizeEqualToSize(size, textureSize));
}

}  // namespace flutter::testing
