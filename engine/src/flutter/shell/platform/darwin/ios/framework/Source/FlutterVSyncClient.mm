// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterVSyncClient.h"

#import <UIKit/UIKit.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/common/framework/Source/FlutterTracing.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunner+FML.h"

FLUTTER_ASSERT_ARC

NSString* const kCADisableMinimumFrameDurationOnPhoneKey = @"CADisableMinimumFrameDurationOnPhone";

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
  FML_DCHECK(callback);
  FML_DCHECK(taskRunner);
  fml::RefPtr<fml::TaskRunner> task_runner = taskRunner.taskRunner;
  FML_DCHECK(task_runner);

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
    task_runner->PostTask([weakSelf]() {
      FlutterVSyncClient* strongSelf = weakSelf;
      if (strongSelf) {
        [strongSelf.displayLink addToRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
      }
    });
  }

  return self;
}

- (void)setMaxRefreshRate:(double)refreshRate {
  if (!_isVariableRefreshRateEnabled) {
    return;
  }
  double maxFrameRate = fmax(refreshRate, 60);
  double minFrameRate = fmax(maxFrameRate / 2, 60);
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
  [FlutterTracing tracePlatformVsyncWithStartTime:link.timestamp targetTime:link.targetTimestamp];

  CFTimeInterval duration = link.targetTimestamp - link.timestamp;
  if (duration > 0) {
    _refreshRate = round(1 / duration);
  }

  if (_allowPauseAfterVsync) {
    link.paused = YES;
  }
  _callback(link.timestamp, link.targetTimestamp);
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
  auto preferredFPS = displayLink.preferredFramesPerSecond;

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
