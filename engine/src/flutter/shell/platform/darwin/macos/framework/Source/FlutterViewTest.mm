// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"

#import <Metal/Metal.h>

#import "flutter/testing/testing.h"

constexpr int64_t kImplicitViewId = 0ll;

@interface TestReshapeListener : NSObject <FlutterViewReshapeListener>

@end

@implementation TestReshapeListener

- (void)viewDidReshape:(nonnull NSView*)view {
}

@end

TEST(FlutterView, ShouldInheritContentsScaleReturnsYes) {
  id<MTLDevice> device = MTLCreateSystemDefaultDevice();
  id<MTLCommandQueue> queue = [device newCommandQueue];
  TestReshapeListener* listener = [[TestReshapeListener alloc] init];
  FlutterThreadSynchronizer* threadSynchronizer = [[FlutterThreadSynchronizer alloc] init];
  FlutterView* view = [[FlutterView alloc] initWithMTLDevice:device
                                                commandQueue:queue
                                             reshapeListener:listener
                                          threadSynchronizer:threadSynchronizer
                                                      viewId:kImplicitViewId];
  EXPECT_EQ([view layer:view.layer shouldInheritContentsScale:3.0 fromWindow:view.window], YES);
}
