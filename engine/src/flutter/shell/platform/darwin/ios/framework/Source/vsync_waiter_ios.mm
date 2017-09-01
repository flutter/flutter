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
}

- (instancetype)init {
  self = [super init];

  if (self) {
    _displayLink =
        [[CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLink:)] retain];
    _displayLink.paused = YES;

    blink::Threads::UI()->PostTask([client = [self retain]]() {
      [client->_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
      [client release];
    });
  }

  return self;
}

- (void)await:(shell::VsyncWaiter::Callback)callback {
  FTL_DCHECK(!_pendingCallback);
  _pendingCallback = std::move(callback);
  _displayLink.paused = NO;
}

- (void)onDisplayLink:(CADisplayLink*)link {
  // ftl::TimePoint and CATimeInterval both use mach_absolute_time.
  ftl::TimePoint frame_start_time = ftl::TimePoint::Now();
  ftl::TimePoint frame_target_time =
      ftl::TimePoint::FromEpochDelta(ftl::TimeDelta::FromSecondsF(link.targetTimestamp));

  _displayLink.paused = YES;

  // Note: Even though we know we are on the UI thread already (since the
  // display link was scheduled on the UI thread in the contructor), we use
  // the PostTask mechanism because the callback may have side-effects that need
  // to be addressed via a task observer. Invoking the callback by itself
  // bypasses such task observers.
  //
  // We are not using the PostTask for thread switching, but to make task
  // observers work.
  blink::Threads::UI()->PostTask([
    callback = _pendingCallback, frame_start_time, frame_target_time
  ]() { callback(frame_start_time, frame_target_time); });

  _pendingCallback = nullptr;
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
  [client_ await:callback];
}

}  // namespace shell
