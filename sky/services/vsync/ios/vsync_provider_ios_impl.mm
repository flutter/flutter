// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/vsync/ios/vsync_provider_ios_impl.h"
#include "base/trace_event/trace_event.h"

#include <Foundation/Foundation.h>
#include <QuartzCore/CADisplayLink.h>
#include <mach/mach_time.h>
#include <vector>

@interface VSyncClient : NSObject

@end

static inline uint64_t CurrentTimeMicroseconds() {
  static mach_timebase_info_data_t timebase = {0};

  if (timebase.denom == 0) {
    (void)mach_timebase_info(&timebase);
  }

  return (mach_absolute_time() * 1e-3 * timebase.numer) / timebase.denom;
}

@implementation VSyncClient {
  CADisplayLink* _displayLink;
  std::vector<::vsync::VSyncProvider::AwaitVSyncCallback> _pendingCallbacks;
  BOOL _traceLevel;
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

- (void)await:(::vsync::VSyncProvider::AwaitVSyncCallback)callback {
  _pendingCallbacks.push_back(callback);
  _displayLink.paused = NO;
}

- (void)onDisplayLink:(CADisplayLink*)link {
  TRACE_COUNTER1("vsync", "PlatformVSync", _traceLevel = !_traceLevel);
  _displayLink.paused = YES;
  uint64_t micros = CurrentTimeMicroseconds();
  for (const auto& callback : _pendingCallbacks) {
    callback.Run(micros);
  }
  _pendingCallbacks.clear();
}

- (void)dealloc {
  [_displayLink invalidate];
  [_displayLink release];

  [super dealloc];
}

@end

namespace sky {
namespace services {
namespace vsync {

VsyncProviderIOSImpl::VsyncProviderIOSImpl(
    mojo::InterfaceRequest<::vsync::VSyncProvider> request)
    : binding_(this, request.Pass()), client_([[VSyncClient alloc] init]) {}

VsyncProviderIOSImpl::~VsyncProviderIOSImpl() {
  [client_ release];
}

void VsyncProviderIOSImpl::AwaitVSync(const AwaitVSyncCallback& callback) {
  [client_ await:callback];
}

}  // namespace vsync
}  // namespace services
}  // namespace sky
