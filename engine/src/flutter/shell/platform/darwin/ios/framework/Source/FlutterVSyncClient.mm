// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterVSyncClient.h"

#import <UIKit/UIKit.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/common/framework/Source/FlutterTracing.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunner.h"

FLUTTER_ASSERT_ARC

NSString* const kCADisableMinimumFrameDurationOnPhoneKey = @"CADisableMinimumFrameDurationOnPhone";
static const double kDefaultRefreshRate = 60.0;

@implementation FlutterVSyncClient {
  void (^_callback)(CFTimeInterval startTime, CFTimeInterval targetTime);
  CADisplayLink* _displayLink;
  BOOL _isVariableRefreshRateEnabled;
}

- (instancetype)initWithTaskRunner:(FlutterFMLTaskRunner*)taskRunner
      isVariableRefreshRateEnabled:(BOOL)isVariableRefreshRateEnabled
                    maxRefreshRate:(double)maxRefreshRate
                          callback:(void (^)(CFTimeInterval startTime,
                                             CFTimeInterval targetTime))callback {
  NSAssert(callback, @"callback must not be nil");
  NSAssert(taskRunner, @"taskRunner must not be nil");

  if (self = [super init]) {
    _refreshRate = maxRefreshRate;
    _isVariableRefreshRateEnabled = isVariableRefreshRateEnabled;
    _allowPauseAfterVsync = YES;
    _callback = callback;
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLink:)];
    _displayLink.paused = YES;

    [self setMaxRefreshRate:maxRefreshRate];

    // Capture a weak reference to self to ensure we don't add the display link
    // to the run loop if the client has already been deallocated.
    __weak FlutterVSyncClient* weakSelf = self;
    [taskRunner postTask:^{
      FlutterVSyncClient* strongSelf = weakSelf;
      if (strongSelf) {
        [strongSelf.displayLink addToRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
      }
    }];
  }

  return self;
}

- (void)setMaxRefreshRate:(double)refreshRate {
  if (!_isVariableRefreshRateEnabled) {
    return;
  }
  double maxFrameRate = fmax(refreshRate, kDefaultRefreshRate);
  double minFrameRate = fmax(maxFrameRate / 2, kDefaultRefreshRate);
  if (@available(iOS 15.0, *)) {
    _displayLink.preferredFrameRateRange =
        CAFrameRateRangeMake(minFrameRate, maxFrameRate, maxFrameRate);
  } else {
    _displayLink.preferredFramesPerSecond = maxFrameRate;
  }
}

- (void)await {
  _displayLink.paused = NO;
}

- (void)pause {
  _displayLink.paused = YES;
}

- (void)onDisplayLink:(CADisplayLink*)link {
  // CADisplayLink timestamps use the CACurrentMediaTime() monotonic clock (seconds since boot).
  // CACurrentMediaTime() is based on mach_absolute_time, whereas the core engine uses
  // fml::TimePoint, which is implemented with std::chrono::steady_clock, which uses
  // mach_continuous_time under the hood. Thus, the values passed to the engine in the vsync
  // callback need to be rebased to fml::TimePoint's epoch.
  //
  // According to Apple's docs, before the first frame is delivered, or when the display link is
  // paused, both timestamp and targetTimestamp properties are 0.0. To guarantee consistent frame
  // progression, we guard against zero values and fall back to CACurrentMediaTime().
  CFTimeInterval timestamp = link.timestamp;
  if (timestamp == 0.0) {
    timestamp = CACurrentMediaTime();
  }

  // targetTimestamp is the anticipated presentation time of the next screen refresh. If
  // targetTimestamp is zero or less than/equal to timestamp (which also occurs on paused/unpaused
  // transitions), synthesize a projected target time based on the current refresh rate.
  CFTimeInterval targetTimestamp = link.targetTimestamp;
  if (targetTimestamp <= timestamp) {
    double effectiveRefreshRate = _refreshRate > 0.0 ? _refreshRate : kDefaultRefreshRate;
    targetTimestamp = timestamp + (1.0 / effectiveRefreshRate);
  }
  CFTimeInterval duration = targetTimestamp - timestamp;

  [FlutterTracing tracePlatformVsyncWithStartTime:timestamp targetTime:targetTimestamp];

  // In steady-state, duration reflects the hardware refresh interval (e.g., ~0.01667s for 60Hz).
  // We dynamically recalculate the refresh rate from the frame duration to adjust to ProMotion
  // display refresh rate shifts.
  //
  // Round to nearest whole Hz value to ensure we don't introduce frame timing issues due to
  // floating point error. e.g. 59.998, 60.004, 59.995, ... --> 60.000, 60.000, 60.000, ...
  if (duration > 0) {
    double roundedRefreshRate = round(1.0 / duration);
    if (roundedRefreshRate > 0.0) {
      _refreshRate = roundedRefreshRate;
    }
  }

  if (_allowPauseAfterVsync) {
    link.paused = YES;
  }
  _callback(timestamp, targetTimestamp);
}

- (void)dealloc {
  [self invalidate];
}

- (void)invalidate {
  [_displayLink invalidate];
  _displayLink = nil;
}

- (CADisplayLink*)displayLink {
  return _displayLink;
}

@end

@implementation FlutterDisplayLinkManager

+ (double)displayRefreshRate {
  // TODO(cbracken): This code is incorrect. https://github.com/flutter/flutter/issues/185759
  //
  // We create a new CADisplayLink, call `preferredFramesPerSecond` on it, then immediately throw it
  // away. As noted below, the default value for `preferredFramesPerSecond` is zero, in which case,
  // we just return UIScreen.mainScreen.maximumFramesPerSecond in all cases; everything before that
  // line can be deleted.
  //
  // If we intend to support configurable preferred FPS, then we should provide API for it. We
  // should delete this code either way.

  CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:[[[self class] alloc] init]
                                                           selector:@selector(onDisplayLink:)];
  displayLink.paused = YES;
  NSInteger preferredFPS = displayLink.preferredFramesPerSecond;

  // From Docs:
  // The default value for preferredFramesPerSecond is 0. When this value is 0, the preferred
  // frame rate is equal to the maximum refresh rate of the display, as indicated by the
  // maximumFramesPerSecond property.

  if (preferredFPS != 0) {
    return preferredFPS;
  }

  return UIScreen.mainScreen.maximumFramesPerSecond;
}

- (void)onDisplayLink:(CADisplayLink*)link {
  // no-op.
}

+ (BOOL)maxRefreshRateEnabledOnIPhone {
  return [[NSBundle.mainBundle objectForInfoDictionaryKey:kCADisableMinimumFrameDurationOnPhoneKey]
      boolValue];
}

@end
