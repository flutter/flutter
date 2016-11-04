// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"

#include <utility>

#include <Foundation/Foundation.h>
#include <QuartzCore/CADisplayLink.h>
#include <mach/mach_time.h>

#include "flutter/common/threads.h"
#include "flutter/glue/trace_event.h"
#include "lib/ftl/logging.h"

@interface VSyncClient : NSObject

@end

@implementation VSyncClient {
  CADisplayLink* _displayLink;
  shell::VsyncWaiter::Callback _pendingCallback;
  bool _traceCounter;
}

- (instancetype)init {
  self = [super init];

  if (self) {
    _displayLink = [[CADisplayLink
        displayLinkWithTarget:self
                     selector:@selector(onDisplayLink:)] retain];
    _displayLink.paused = YES;
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSRunLoopCommonModes];
  }

  return self;
}

- (void)await:(shell::VsyncWaiter::Callback)callback {
  FTL_DCHECK(!_pendingCallback);
  _pendingCallback = std::move(callback);
  _displayLink.paused = NO;
}

- (void)onDisplayLink:(CADisplayLink*)link {
  _traceCounter = !_traceCounter;
  TRACE_COUNTER1("flutter", "OnDisplayLink", _traceCounter);
  ftl::TimePoint frame_time = ftl::TimePoint::Now();
  _displayLink.paused = YES;
  auto callback = std::move(_pendingCallback);
  _pendingCallback = shell::VsyncWaiter::Callback();
  blink::Threads::UI()->PostTask(
      [callback, frame_time] { callback(frame_time); });
}

- (void)dealloc {
  [_displayLink invalidate];
  [_displayLink release];

  [super dealloc];
}

@end

namespace shell {

VsyncWaiterIOS::VsyncWaiterIOS() : client_([[VSyncClient alloc] init]) {}

VsyncWaiterIOS::~VsyncWaiterIOS() {
  [client_ release];
}

void VsyncWaiterIOS::AsyncWaitForVsync(Callback callback) {
  [client_ await:std::move(callback)];
}

}  // namespace shell
