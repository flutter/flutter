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
#include "lib/fxl/logging.h"

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
  FXL_DCHECK(!_pendingCallback);
  _pendingCallback = std::move(callback);
  _displayLink.paused = NO;
}

- (void)onDisplayLink:(CADisplayLink*)link {
  fxl::TimePoint frame_start_time = fxl::TimePoint::Now();
  fxl::TimePoint frame_target_time = frame_start_time + fxl::TimeDelta::FromSecondsF(link.duration);

  _displayLink.paused = YES;

  // Note: The tag name must be "VSYNC" (it is special) so that the "Highlight
  // Vsync" checkbox in the timeline can be enabled.
  // See: https://github.com/catapult-project/catapult/blob/2091404475cbba9b786
  // 442979b6ec631305275a6/tracing/tracing/extras/vsync/vsync_auditor.html#L26
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_RELEASE
  TRACE_EVENT1("flutter", "VSYNC", "mode", "basic");
#else
  {
    fxl::TimeDelta delta = frame_target_time.ToEpochDelta();
    constexpr size_t num_chars = sizeof(int64_t) * CHAR_BIT * 3.4 + 2;
    char deadline[num_chars];
    sprintf(deadline, "%lld", delta.ToMicroseconds());
    TRACE_EVENT2("flutter", "VSYNC", "mode", "basic", "deadline", deadline);
  }
#endif

  // Note: Even though we know we are on the UI thread already (since the
  // display link was scheduled on the UI thread in the contructor), we use
  // the PostTask mechanism because the callback may have side-effects that need
  // to be addressed via a task observer. Invoking the callback by itself
  // bypasses such task observers.
  //
  // We are not using the PostTask for thread switching, but to make task
  // observers work.
  blink::Threads::UI()->PostTask(
      [callback = _pendingCallback, frame_start_time, frame_target_time]() {
        callback(frame_start_time, frame_target_time);
      });

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
