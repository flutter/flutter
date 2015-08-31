// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/vsync/ios/vsync_provider_impl.h"

#include <Foundation/Foundation.h>
#include <QuartzCore/CADisplayLink.h>
#include <mach/mach_time.h>

@interface VSyncClient : NSObject

@end

static inline uint64_t CurrentTimeMicrosSeconds() {
  static mach_timebase_info_data_t timebase = {0};

  if (timebase.denom == 0) {
    (void)mach_timebase_info(&timebase);
  }

  return (mach_absolute_time() * 1e-3 * timebase.numer) / timebase.denom;
}

@implementation VSyncClient {
  CADisplayLink* _displayLink;
  ::vsync::VSyncProvider::AwaitVSyncCallback _pendingCallback;
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
  _pendingCallback = callback;
  _displayLink.paused = NO;
}

- (void)onDisplayLink:(CADisplayLink*)link {
  _displayLink.paused = YES;
  _pendingCallback.Run(CurrentTimeMicrosSeconds());
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

VsyncProviderImpl::VsyncProviderImpl(
    mojo::InterfaceRequest<::vsync::VSyncProvider> request)
    : binding_(this, request.Pass()), client_([[VSyncClient alloc] init]) {}

VsyncProviderImpl::~VsyncProviderImpl() {
  [client_ release];
}

void VsyncProviderImpl::AwaitVSync(const AwaitVSyncCallback& callback) {
  [client_ await:callback];
}

void VSyncProviderFactory::Create(
    mojo::ApplicationConnection* connection,
    mojo::InterfaceRequest<::vsync::VSyncProvider> request) {
  new VsyncProviderImpl(request.Pass());
}

}  // namespace vsync
}  // namespace services
}  // namespace sky
