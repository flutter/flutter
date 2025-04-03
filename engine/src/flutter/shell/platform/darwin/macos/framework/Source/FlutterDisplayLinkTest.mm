// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDisplayLink.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterRunLoop.h"

#import <AppKit/AppKit.h>
#include <numeric>

#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/testing/testing.h"

@interface TestDisplayLinkDelegate : NSObject <FlutterDisplayLinkDelegate> {
  void (^_block)(CFTimeInterval timestamp, CFTimeInterval targetTimestamp);
}

- (instancetype)initWithBlock:(void (^)(CFTimeInterval timestamp,
                                        CFTimeInterval targetTimestamp))block;

@end

@implementation TestDisplayLinkDelegate
- (instancetype)initWithBlock:(void (^__strong)(CFTimeInterval, CFTimeInterval))block {
  if (self = [super init]) {
    _block = block;
  }
  return self;
}

- (void)onDisplayLink:(CFTimeInterval)timestamp targetTimestamp:(CFTimeInterval)targetTimestamp {
  _block(timestamp, targetTimestamp);
}

@end

class FlutterDisplayLinkTest : public testing::Test {
 public:
  void SetUp() override { [FlutterRunLoop ensureMainLoopInitialized]; }
};

TEST_F(FlutterDisplayLinkTest, ViewAddedToWindowFirst) {
  NSWindow* window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 100, 100)
                                                 styleMask:NSWindowStyleMaskTitled
                                                   backing:NSBackingStoreNonretained
                                                     defer:NO];
  NSView* view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
  [window setContentView:view];

  __block BOOL signalled = NO;

  TestDisplayLinkDelegate* delegate = [[TestDisplayLinkDelegate alloc]
      initWithBlock:^(CFTimeInterval timestamp, CFTimeInterval targetTimestamp) {
        signalled = YES;
      }];

  FlutterDisplayLink* displayLink = [FlutterDisplayLink displayLinkWithView:view];
  displayLink.delegate = delegate;
  displayLink.paused = NO;

  while (!signalled) {
    [FlutterRunLoop.mainRunLoop pollFlutterMessagesOnce];
  }

  [displayLink invalidate];
}

TEST_F(FlutterDisplayLinkTest, ViewAddedToWindowLater) {
  NSView* view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];

  __block BOOL signalled = NO;

  TestDisplayLinkDelegate* delegate = [[TestDisplayLinkDelegate alloc]
      initWithBlock:^(CFTimeInterval timestamp, CFTimeInterval targetTimestamp) {
        signalled = YES;
      }];

  FlutterDisplayLink* displayLink = [FlutterDisplayLink displayLinkWithView:view];
  displayLink.delegate = delegate;
  displayLink.paused = NO;

  NSWindow* window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 100, 100)
                                                 styleMask:NSWindowStyleMaskTitled
                                                   backing:NSBackingStoreNonretained
                                                     defer:NO];
  [window setContentView:view];

  while (!signalled) {
    [FlutterRunLoop.mainRunLoop pollFlutterMessagesOnce];
  }

  [displayLink invalidate];
}

TEST_F(FlutterDisplayLinkTest, ViewRemovedFromWindow) {
  NSWindow* window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 100, 100)
                                                 styleMask:NSWindowStyleMaskTitled
                                                   backing:NSBackingStoreNonretained
                                                     defer:NO];
  NSView* view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
  [window setContentView:view];

  __block BOOL signalled = NO;

  TestDisplayLinkDelegate* delegate = [[TestDisplayLinkDelegate alloc]
      initWithBlock:^(CFTimeInterval timestamp, CFTimeInterval targetTimestamp) {
        signalled = YES;
      }];

  FlutterDisplayLink* displayLink = [FlutterDisplayLink displayLinkWithView:view];
  displayLink.delegate = delegate;
  displayLink.paused = NO;

  while (!signalled) {
    [FlutterRunLoop.mainRunLoop pollFlutterMessagesOnce];
  }
  displayLink.paused = YES;

  signalled = false;

  displayLink.paused = NO;

  [window setContentView:nil];

  CFTimeInterval start = CACurrentMediaTime();
  while (CACurrentMediaTime() < start + 0.1) {
    [FlutterRunLoop.mainRunLoop pollFlutterMessagesOnce];
  }

  EXPECT_FALSE(signalled);

  [displayLink invalidate];
}

TEST_F(FlutterDisplayLinkTest, CVDisplayLinkInterval) {
  CVDisplayLinkRef link;
  CVDisplayLinkCreateWithCGDisplay(CGMainDisplayID(), &link);
  __block CFTimeInterval last = 0;
  auto intervals = std::make_shared<std::vector<CFTimeInterval>>();
  auto event = std::make_shared<fml::AutoResetWaitableEvent>();
  CVDisplayLinkSetOutputHandler(
      link, ^(CVDisplayLinkRef displayLink, const CVTimeStamp* inNow,
              const CVTimeStamp* inOutputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut) {
        if (last != 0) {
          intervals->push_back(CACurrentMediaTime() - last);
        }
        last = CACurrentMediaTime();
        if (intervals->size() == 10) {
          event->Signal();
        }
        return 0;
      });

  CVDisplayLinkStart(link);
  event->Wait();
  CVDisplayLinkStop(link);
  CVDisplayLinkRelease(link);
  CFTimeInterval average = std::reduce(intervals->begin(), intervals->end()) / intervals->size();
  CFTimeInterval max = *std::max_element(intervals->begin(), intervals->end());
  CFTimeInterval min = *std::min_element(intervals->begin(), intervals->end());
  NSLog(@"CVDisplayLink Interval: Average: %fs, Max: %fs, Min: %fs", average, max, min);
}
