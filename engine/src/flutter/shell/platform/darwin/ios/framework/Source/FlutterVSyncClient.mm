// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterVSyncClient.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterVSyncClient+FML.h"

#import <UIKit/UIKit.h>

#include "flutter/fml/trace_event.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"

FLUTTER_ASSERT_ARC

NSString* const kCADisableMinimumFrameDurationOnPhoneKey = @"CADisableMinimumFrameDurationOnPhone";

@implementation FlutterVSyncClient {
  flutter::VsyncWaiter::Callback _callback;
  CADisplayLink* _displayLink;
}

- (instancetype)initWithTaskRunner:(fml::RefPtr<fml::TaskRunner>)task_runner
                          callback:(flutter::VsyncWaiter::Callback)callback {
  FML_DCHECK(task_runner);

  if (self = [super init]) {
    _refreshRate = FlutterDisplayLinkManager.displayRefreshRate;
    _allowPauseAfterVsync = YES;
    _callback = std::move(callback);
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLink:)];
    _displayLink.paused = YES;

    [self setMaxRefreshRate:FlutterDisplayLinkManager.displayRefreshRate];

    // Capture a weak reference to self to ensure we don't add the display link
    // to the run loop if the client has already been deallocated.
    CADisplayLink* localDisplayLink = _displayLink;
    __weak FlutterVSyncClient* weakSelf = self;
    task_runner->PostTask([localDisplayLink, weakSelf]() {
      FlutterVSyncClient* strongSelf = weakSelf;
      if (strongSelf) {
        [localDisplayLink addToRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
      }
    });
  }

  return self;
}

- (void)setMaxRefreshRate:(double)refreshRate {
  if (!FlutterDisplayLinkManager.maxRefreshRateEnabledOnIPhone) {
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
  CFTimeInterval delay = CACurrentMediaTime() - link.timestamp;
  fml::TimePoint frame_start_time = fml::TimePoint::Now() - fml::TimeDelta::FromSecondsF(delay);

  CFTimeInterval duration = link.targetTimestamp - link.timestamp;
  fml::TimePoint frame_target_time = frame_start_time + fml::TimeDelta::FromSecondsF(duration);

  TRACE_EVENT2_INT("flutter", "PlatformVsync", "frame_start_time",
                   frame_start_time.ToEpochDelta().ToMicroseconds(), "frame_target_time",
                   frame_target_time.ToEpochDelta().ToMicroseconds());

  std::unique_ptr<flutter::FrameTimingsRecorder> recorder =
      std::make_unique<flutter::FrameTimingsRecorder>();

  if (duration > 0) {
    _refreshRate = round(1 / duration);
  }

  recorder->RecordVsync(frame_start_time, frame_target_time);

  if (_allowPauseAfterVsync) {
    link.paused = YES;
  }
  _callback(std::move(recorder));
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
