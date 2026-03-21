// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"

#include <utility>

#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>
#include <mach/mach_time.h>

#include "flutter/common/task_runners.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/memory/task_runner_checker.h"
#include "flutter/fml/trace_event.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"

FLUTTER_ASSERT_ARC

NSString* const kCADisableMinimumFrameDurationOnPhoneKey = @"CADisableMinimumFrameDurationOnPhone";

@interface VSyncClient ()
@property(nonatomic, assign, readonly) double refreshRate;
@end

// When calculating refresh rate difference, anything within 0.1 fps is ignored.
const static double kRefreshRateDiffToIgnore = 0.1;

namespace {

fml::TimeDelta PredictionHeadroom(const fml::TimeDelta& interval) {
  if (interval <= fml::TimeDelta::Zero()) {
    return fml::TimeDelta::Zero();
  }
  const fml::TimeDelta proportional_headroom = interval / 10.0;
  const fml::TimeDelta kHeadroomCap = fml::TimeDelta::FromMilliseconds(2);
  return proportional_headroom < kHeadroomCap ? proportional_headroom : kHeadroomCap;
}

fml::TimeDelta IntervalFromRefreshRate(double refresh_rate) {
  if (refresh_rate <= 0.0) {
    return fml::TimeDelta::Zero();
  }
  return fml::TimeDelta::FromSecondsF(1.0 / refresh_rate);
}

}  // namespace

namespace flutter {

VsyncWaiterIOS::VsyncWaiterIOS(const flutter::TaskRunners& task_runners)
    : VsyncWaiter(task_runners) {
  auto callback = [this](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) {
    const fml::TimePoint start_time = recorder->GetVsyncStartTime();
    const fml::TimePoint target_time = recorder->GetVsyncTargetTime();
    FireCallback(start_time, target_time, true);
  };
  client_ = [[VSyncClient alloc] initWithTaskRunner:task_runners_.GetUITaskRunner()
                                           callback:callback];
  max_refresh_rate_ = DisplayLinkManager.displayRefreshRate;
}

VsyncWaiterIOS::~VsyncWaiterIOS() {
  // This way, we will get no more callbacks from the display link that holds a weak (non-nilling)
  // reference to this C++ object.
  [client_ invalidate];
}

void VsyncWaiterIOS::AwaitVSync() {
  double new_max_refresh_rate = DisplayLinkManager.displayRefreshRate;
  if (fabs(new_max_refresh_rate - max_refresh_rate_) > kRefreshRateDiffToIgnore) {
    max_refresh_rate_ = new_max_refresh_rate;
    [client_ setMaxRefreshRate:max_refresh_rate_];
  }
  [client_ await];
}

// |VariableRefreshRateReporter|
double VsyncWaiterIOS::GetRefreshRate() const {
  return client_.refreshRate;
}

}  // namespace flutter

@implementation VSyncClient {
  flutter::VsyncWaiter::Callback _callback;
  CADisplayLink* _displayLink;

  // Cache the most recently observed vsync times so we can predict the
  // current vsync phase when CADisplayLink is paused.
  bool _hasLastVsync;
  fml::TimePoint _lastVsyncStartTime;
  fml::TimePoint _lastVsyncTargetTime;

  // Tracks the last vsync start time delivered to avoid duplicate begin-frames
  // for the same interval.
  bool _hasLastFiredVsync;
  fml::TimePoint _lastFiredVsyncStartTime;

  // Max display refresh rate used to conservatively account for dynamic
  // 60Hz/120Hz transitions when predicting the next target.
  double _maxRefreshRate;

  // Scheduled predicted callbacks are versioned to make cancellation
  // lock-free and cheap.
  uint64_t _predictedCallbackGeneration;
  bool _hasPendingPredictedVsync;
  fml::TimePoint _pendingPredictedVsyncStartTime;
}

- (instancetype)initWithTaskRunner:(fml::RefPtr<fml::TaskRunner>)task_runner
                          callback:(flutter::VsyncWaiter::Callback)callback {
  FML_DCHECK(task_runner);

  if (self = [super init]) {
    _refreshRate = DisplayLinkManager.displayRefreshRate;
    _maxRefreshRate = fmax(_refreshRate, 60);
    _allowPauseAfterVsync = YES;
    _hasLastVsync = false;
    _hasLastFiredVsync = false;
    _predictedCallbackGeneration = 0;
    _hasPendingPredictedVsync = false;
    _callback = std::move(callback);
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLink:)];
    _displayLink.paused = YES;

    [self setMaxRefreshRate:DisplayLinkManager.displayRefreshRate];

    // Strongly retain the captured link until it is added to the runloop.
    CADisplayLink* localDisplayLink = _displayLink;
    task_runner->PostTask([localDisplayLink]() {
      [localDisplayLink addToRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
    });
  }

  return self;
}

- (void)setMaxRefreshRate:(double)refreshRate {
  _maxRefreshRate = fmax(refreshRate, 60);
  if (!DisplayLinkManager.maxRefreshRateEnabledOnIPhone) {
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

- (void)cancelPendingPredictedCallback {
  _predictedCallbackGeneration++;
  _hasPendingPredictedVsync = false;
}

- (void)firePredictedCallbackIfValidForGeneration:(uint64_t)generation
                                   phaseStartTime:(fml::TimePoint)phase_start_time
                                  phaseTargetTime:(fml::TimePoint)phase_target_time {
  if (generation != _predictedCallbackGeneration || !_hasPendingPredictedVsync) {
    return;
  }
  _hasPendingPredictedVsync = false;

  if (!_allowPauseAfterVsync || _displayLink == nil || !_displayLink.isPaused) {
    return;
  }

  const fml::TimeDelta interval = phase_target_time - phase_start_time;
  if (interval <= fml::TimeDelta::Zero()) {
    _displayLink.paused = NO;
    return;
  }

  const fml::TimePoint now = fml::TimePoint::Now();
  // Revalidate at callback time; if we're too close or late, fall back to a
  // real CADisplayLink tick so we don't miss the frame.
  if ((phase_target_time - now) <= PredictionHeadroom(interval)) {
    _displayLink.paused = NO;
    return;
  }

  if (_hasLastFiredVsync && phase_start_time <= _lastFiredVsyncStartTime) {
    return;
  }

  TRACE_EVENT2_INT("flutter", "PlatformVsyncPredicted", "frame_start_time",
                   phase_start_time.ToEpochDelta().ToMicroseconds(), "frame_target_time",
                   phase_target_time.ToEpochDelta().ToMicroseconds());

  std::unique_ptr<flutter::FrameTimingsRecorder> recorder =
      std::make_unique<flutter::FrameTimingsRecorder>();

  _refreshRate = round(1 / interval.ToSecondsF());

  // Update caches to keep future predictions stable and close to now.
  _hasLastVsync = true;
  _lastVsyncStartTime = phase_start_time;
  _lastVsyncTargetTime = phase_target_time;

  _hasLastFiredVsync = true;
  _lastFiredVsyncStartTime = phase_start_time;

  recorder->RecordVsync(phase_start_time, phase_target_time);
  _callback(std::move(recorder));
}

- (BOOL)maybeSchedulePredictedCallback {
  // Only attempt this optimization in "pause after vsync" mode. Other clients
  // intentionally run CADisplayLink continuously and should not be
  // short-circuited.
  if (!_allowPauseAfterVsync) {
    return NO;
  }
  if (_displayLink == nil || !_displayLink.isPaused) {
    return NO;
  }
  if (!_hasLastVsync) {
    return NO;
  }

  const fml::TimeDelta interval = _lastVsyncTargetTime - _lastVsyncStartTime;
  if (interval <= fml::TimeDelta::Zero()) {
    return NO;
  }

  const fml::TimePoint now = fml::TimePoint::Now();
  const fml::TimeDelta elapsed = now - _lastVsyncStartTime;
  if (elapsed < fml::TimeDelta::Zero()) {
    return NO;
  }

  const int64_t interval_us = interval.ToMicroseconds();
  if (interval_us <= 0) {
    return NO;
  }
  const int64_t elapsed_us = elapsed.ToMicroseconds();
  const int64_t intervals_passed = elapsed_us / interval_us;

  const fml::TimePoint phase_start_time =
      _lastVsyncStartTime + fml::TimeDelta::FromMicroseconds(interval_us * intervals_passed);
  const fml::TimePoint phase_target_time = phase_start_time + interval;

  // Ensure there is still time to target the upcoming vsync boundary.
  if (phase_target_time <= now) {
    return NO;
  }

  // Avoid firing twice for the same predicted phase.
  if (_hasLastFiredVsync && phase_start_time <= _lastFiredVsyncStartTime) {
    return NO;
  }

  if (_hasPendingPredictedVsync && phase_start_time <= _pendingPredictedVsyncStartTime) {
    return YES;
  }

  // Dynamic refresh rates can switch between 60Hz and 120Hz. Use the earliest
  // plausible interval from the configured max refresh rate to avoid over-
  // predicting a slower cadence.
  const fml::TimeDelta headroom = PredictionHeadroom(interval);
  fml::TimePoint fire_time = phase_target_time - headroom - headroom;
  const fml::TimeDelta min_possible_interval = IntervalFromRefreshRate(_maxRefreshRate);
  if (min_possible_interval > fml::TimeDelta::Zero() && min_possible_interval < interval) {
    const fml::TimePoint conservative_target = phase_start_time + min_possible_interval;
    const fml::TimeDelta conservative_headroom = PredictionHeadroom(min_possible_interval);
    const fml::TimePoint conservative_fire =
        conservative_target - conservative_headroom - conservative_headroom;
    if (conservative_fire < fire_time) {
      fire_time = conservative_fire;
    }
  }

  if (fire_time <= now) {
    return NO;
  }

  _hasPendingPredictedVsync = true;
  _pendingPredictedVsyncStartTime = phase_start_time;
  const uint64_t generation = ++_predictedCallbackGeneration;

  VSyncClient* client = self;
  const fml::TimeDelta delay = fire_time - now;
  const int64_t delay_ns = delay > fml::TimeDelta::Zero() ? delay.ToNanoseconds() : 0;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay_ns), dispatch_get_main_queue(), ^{
    [client firePredictedCallbackIfValidForGeneration:generation
                                       phaseStartTime:phase_start_time
                                      phaseTargetTime:phase_target_time];
  });
  return YES;
}

- (void)await {
  if ([self maybeSchedulePredictedCallback]) {
    return;
  }
  [self cancelPendingPredictedCallback];
  _displayLink.paused = NO;
}

- (void)pause {
  [self cancelPendingPredictedCallback];
  _displayLink.paused = YES;
}

- (void)onDisplayLink:(CADisplayLink*)link {
  [self cancelPendingPredictedCallback];

  CFTimeInterval delay = CACurrentMediaTime() - link.timestamp;
  fml::TimePoint frame_start_time = fml::TimePoint::Now() - fml::TimeDelta::FromSecondsF(delay);

  CFTimeInterval duration = link.targetTimestamp - link.timestamp;
  fml::TimePoint frame_target_time = frame_start_time + fml::TimeDelta::FromSecondsF(duration);

  // Cache the observed interval for later prediction when paused.
  _hasLastVsync = true;
  _lastVsyncStartTime = frame_start_time;
  _lastVsyncTargetTime = frame_target_time;
  // This callback delivers a begin-frame for frame_start_time.
  _hasLastFiredVsync = true;
  _lastFiredVsyncStartTime = frame_start_time;

  TRACE_EVENT2_INT("flutter", "PlatformVsync", "frame_start_time",
                   frame_start_time.ToEpochDelta().ToMicroseconds(), "frame_target_time",
                   frame_target_time.ToEpochDelta().ToMicroseconds());

  std::unique_ptr<flutter::FrameTimingsRecorder> recorder =
      std::make_unique<flutter::FrameTimingsRecorder>();

  _refreshRate = round(1 / (frame_target_time - frame_start_time).ToSecondsF());

  recorder->RecordVsync(frame_start_time, frame_target_time);
  if (_allowPauseAfterVsync) {
    link.paused = YES;
  }
  _callback(std::move(recorder));
}

- (void)invalidate {
  [self cancelPendingPredictedCallback];
  [_displayLink invalidate];
  _displayLink = nil;  // Break retain cycle.
  // Clear cached phase state so await() falls back to display link callbacks.
  _hasLastVsync = false;
  _hasLastFiredVsync = false;
}

- (CADisplayLink*)getDisplayLink {
  return _displayLink;
}

@end

@implementation DisplayLinkManager

+ (double)displayRefreshRate {
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
