// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"

#import <Metal/Metal.h>

#import "flutter/shell/platform/darwin/macos/InternalFlutterSwift/InternalFlutterSwift.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterSurfaceManager.h"
#include "flutter/testing/testing.h"

constexpr int64_t kImplicitViewId = 0ll;

@interface TestFlutterViewDelegate : NSObject <FlutterViewDelegate>

@end

@implementation TestFlutterViewDelegate

- (void)viewDidReshape:(nonnull NSView*)view {
}

- (BOOL)viewShouldAcceptFirstResponder:(NSView*)view {
  return YES;
}

@end

@interface TestFlutterViewSizingDelegate : NSObject <FlutterViewSizingDelegate>

@property(readwrite, nonatomic) NSSize updatedContentsSize;
@property(readwrite, nonatomic) BOOL didUpdateContents;

@end

@implementation TestFlutterViewSizingDelegate

- (std::optional<NSSize>)minimumViewSize:(nonnull FlutterView*)view {
  return std::nullopt;
}

- (std::optional<NSSize>)maximumViewSize:(nonnull FlutterView*)view {
  return std::nullopt;
}

- (void)viewDidUpdateContents:(nonnull FlutterView*)view withSize:(NSSize)newSize {
  self.didUpdateContents = YES;
  self.updatedContentsSize = newSize;
}

@end

// Regression test for https://github.com/flutter/flutter/issues/190075. A frame with no layers has
// no size of its own, so it must not report a content size of zero, which is neither a size the
// sizing delegate can lay out for nor a size a pending resize can ever match.
TEST(FlutterView, EmptyFramePresentReportsViewSize) {
  [FlutterRunLoop ensureMainLoopInitialized];

  id<MTLDevice> device = MTLCreateSystemDefaultDevice();
  id<MTLCommandQueue> queue = [device newCommandQueue];
  TestFlutterViewDelegate* delegate = [[TestFlutterViewDelegate alloc] init];
  FlutterView* view = [[FlutterView alloc] initWithMTLDevice:device
                                                commandQueue:queue
                                                    delegate:delegate
                                              viewIdentifier:kImplicitViewId
                                             enableWideGamut:NO];
  [view setFrameSize:NSMakeSize(80, 60)];
  TestFlutterViewSizingDelegate* sizingDelegate = [[TestFlutterViewSizingDelegate alloc] init];
  view.sizingDelegate = sizingDelegate;

  // FlutterView conforms to FlutterSurfaceManagerDelegate privately.
  id surfaceManagerDelegate = view;
  __block BOOL didCommit = NO;
  [surfaceManagerDelegate
      onPresentEmptyFrameWithBlock:^{
        didCommit = YES;
      }
                             delay:0];
  [FlutterRunLoop.mainRunLoop pollFlutterMessagesOnce];

  EXPECT_TRUE(didCommit);
  EXPECT_TRUE(sizingDelegate.didUpdateContents);
  EXPECT_TRUE(NSEqualSizes(sizingDelegate.updatedContentsSize, NSMakeSize(80, 60)));
}

TEST(FlutterView, ShouldInheritContentsScaleReturnsYes) {
  id<MTLDevice> device = MTLCreateSystemDefaultDevice();
  id<MTLCommandQueue> queue = [device newCommandQueue];
  TestFlutterViewDelegate* delegate = [[TestFlutterViewDelegate alloc] init];
  FlutterView* view = [[FlutterView alloc] initWithMTLDevice:device
                                                commandQueue:queue
                                                    delegate:delegate
                                              viewIdentifier:kImplicitViewId
                                             enableWideGamut:NO];
  EXPECT_EQ([view layer:view.layer shouldInheritContentsScale:3.0 fromWindow:view.window], YES);
}

@interface TestFlutterView : FlutterView

@property(readwrite, nonatomic) NSView* (^onHitTest)(NSPoint point);

@end

@implementation TestFlutterView

@synthesize onHitTest;

- (NSView*)hitTest:(NSPoint)point {
  return self.onHitTest(point);
}

- (void)reshaped {
  // Disable resize synchronization for testing.
}

@end

@interface TestCursor : NSCursor
@property(readwrite, nonatomic) BOOL setCalled;
@end

@implementation TestCursor

- (void)set {
  self.setCalled = YES;
}

@end

TEST(FlutterView, CursorUpdateDoesHitTest) {
  id<MTLDevice> device = MTLCreateSystemDefaultDevice();
  id<MTLCommandQueue> queue = [device newCommandQueue];
  TestFlutterViewDelegate* delegate = [[TestFlutterViewDelegate alloc] init];
  TestFlutterView* view = [[TestFlutterView alloc] initWithMTLDevice:device
                                                        commandQueue:queue
                                                            delegate:delegate
                                                      viewIdentifier:kImplicitViewId
                                                     enableWideGamut:NO];
  NSWindow* window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 800, 600)
                                                 styleMask:NSBorderlessWindowMask
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];

  TestCursor* cursor = [[TestCursor alloc] init];

  window.contentView = view;
  __weak NSView* weakView = view;
  __block BOOL hitTestCalled = NO;
  __block NSPoint hitTestCoordinate = NSZeroPoint;
  view.onHitTest = ^NSView*(NSPoint point) {
    hitTestCalled = YES;
    hitTestCoordinate = point;
    return weakView;
  };
  NSEvent* mouseEvent = [NSEvent mouseEventWithType:NSEventTypeMouseMoved
                                           location:NSMakePoint(100, 100)
                                      modifierFlags:0
                                          timestamp:0
                                       windowNumber:0
                                            context:nil
                                        eventNumber:0
                                         clickCount:0
                                           pressure:0];
  [view didUpdateMouseCursor:cursor];
  [view cursorUpdate:mouseEvent];

  EXPECT_TRUE(hitTestCalled);
  // The hit test coordinate should be in the window coordinate system.
  EXPECT_TRUE(CGPointEqualToPoint(hitTestCoordinate, CGPointMake(100, 100)));
  EXPECT_TRUE(cursor.setCalled);
}

TEST(FlutterView, CursorUpdateDoesNotOverridePlatformView) {
  id<MTLDevice> device = MTLCreateSystemDefaultDevice();
  id<MTLCommandQueue> queue = [device newCommandQueue];
  TestFlutterViewDelegate* delegate = [[TestFlutterViewDelegate alloc] init];
  TestFlutterView* view = [[TestFlutterView alloc] initWithMTLDevice:device
                                                        commandQueue:queue
                                                            delegate:delegate
                                                      viewIdentifier:kImplicitViewId
                                                     enableWideGamut:NO];
  NSWindow* window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 800, 600)
                                                 styleMask:NSBorderlessWindowMask
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];

  TestCursor* cursor = [[TestCursor alloc] init];

  NSView* platformView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];

  window.contentView = view;
  __block BOOL hitTestCalled = NO;
  __block NSPoint hitTestCoordinate = NSZeroPoint;
  view.onHitTest = ^NSView*(NSPoint point) {
    hitTestCalled = YES;
    hitTestCoordinate = point;
    return platformView;
  };
  NSEvent* mouseEvent = [NSEvent mouseEventWithType:NSEventTypeMouseMoved
                                           location:NSMakePoint(100, 100)
                                      modifierFlags:0
                                          timestamp:0
                                       windowNumber:0
                                            context:nil
                                        eventNumber:0
                                         clickCount:0
                                           pressure:0];
  [view didUpdateMouseCursor:cursor];
  [view cursorUpdate:mouseEvent];

  EXPECT_TRUE(hitTestCalled);
  // The hit test coordinate should be in the window coordinate system.
  EXPECT_TRUE(CGPointEqualToPoint(hitTestCoordinate, CGPointMake(100, 100)));
  EXPECT_FALSE(cursor.setCalled);
}
