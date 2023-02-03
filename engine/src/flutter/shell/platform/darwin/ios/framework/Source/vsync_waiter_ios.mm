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

// When calculating refresh rate diffrence, anything within 0.1 fps is ignored.
const static double kRefreshRateDiffToIgnore = 0.1;

namespace flutter {

VsyncWaiterIOS::VsyncWaiterIOS(const flutter::TaskRunners& task_runners)
    : VsyncWaiter(task_runners) {
  auto callback = [this](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) {
    const fml::TimePoint start_time = recorder->GetVsyncStartTime();
    const fml::TimePoint target_time = recorder->GetVsyncTargetTime();
    FireCallback(start_time, target_time, true);
  };
  client_ =
      fml::scoped_nsobject{[[VSyncClient alloc] initWithTaskRunner:task_runners_.GetUITaskRunner()
                                                          callback:callback]};
  max_refresh_rate_ = [DisplayLinkManager displayRefreshRate];
}

VsyncWaiterIOS::~VsyncWaiterIOS() {
  // This way, we will get no more callbacks from the display link that holds a weak (non-nilling)
  // reference to this C++ object.
  [client_.get() invalidate];
}

void VsyncWaiterIOS::AwaitVSync() {
  double new_max_refresh_rate = [DisplayLinkManager displayRefreshRate];
  if (fml::TaskRunnerChecker::RunsOnTheSameThread(
          task_runners_.GetRasterTaskRunner()->GetTaskQueueId(),
          task_runners_.GetPlatformTaskRunner()->GetTaskQueueId())) {
    // Pressure tested on iPhone 13 pro, the oldest iPhone that supports refresh rate greater than
    // 60fps. A flutter app can handle fast scrolling on 80 fps with 6 PlatformViews in the scene at
    // the same time.
    new_max_refresh_rate = 80;
  }
  if (fabs(new_max_refresh_rate - max_refresh_rate_) > kRefreshRateDiffToIgnore) {
    max_refresh_rate_ = new_max_refresh_rate;
    [client_.get() setMaxRefreshRate:max_refresh_rate_];
  }
  [client_.get() await];
}

// |VariableRefreshRateReporter|
double VsyncWaiterIOS::GetRefreshRate() const {
  return [client_.get() getRefreshRate];
}

fml::scoped_nsobject<VSyncClient> VsyncWaiterIOS::GetVsyncClient() const {
  return client_;
}

}  // namespace flutter

@implementation VSyncClient {
  flutter::VsyncWaiter::Callback callback_;
  fml::scoped_nsobject<CADisplayLink> display_link_;
  double current_refresh_rate_;
}

- (instancetype)initWithTaskRunner:(fml::RefPtr<fml::TaskRunner>)task_runner
                          callback:(flutter::VsyncWaiter::Callback)callback {
  self = [super init];

  if (self) {
    current_refresh_rate_ = [DisplayLinkManager displayRefreshRate];
    _allowPauseAfterVsync = YES;
    callback_ = std::move(callback);
    display_link_ = fml::scoped_nsobject<CADisplayLink> {
      [[CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLink:)] retain]
    };
    display_link_.get().paused = YES;

    [self setMaxRefreshRate:[DisplayLinkManager displayRefreshRate]];

    task_runner->PostTask([client = [self retain]]() {
      [client->display_link_.get() addToRunLoop:[NSRunLoop currentRunLoop]
                                        forMode:NSRunLoopCommonModes];
      [client release];
    });
  }

  return self;
}

- (void)setMaxRefreshRate:(double)refreshRate {
  if (!DisplayLinkManager.maxRefreshRateEnabledOnIPhone) {
    return;
  }
  double maxFrameRate = fmax(refreshRate, 60);
  double minFrameRate = fmax(maxFrameRate / 2, 60);
  if (@available(iOS 15.0, *)) {
    display_link_.get().preferredFrameRateRange =
        CAFrameRateRangeMake(minFrameRate, maxFrameRate, maxFrameRate);
  } else {
    display_link_.get().preferredFramesPerSecond = maxFrameRate;
  }
}

- (void)await {
  display_link_.get().paused = NO;
}

- (void)pause {
  display_link_.get().paused = YES;
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

  current_refresh_rate_ = round(1 / (frame_target_time - frame_start_time).ToSecondsF());

  recorder->RecordVsync(frame_start_time, frame_target_time);
  if (_allowPauseAfterVsync) {
    display_link_.get().paused = YES;
  }
  callback_(std::move(recorder));
}

- (void)invalidate {
  [display_link_.get() invalidate];
}

- (void)dealloc {
  [self invalidate];

  [super dealloc];
}

- (double)getRefreshRate {
  return current_refresh_rate_;
}

- (CADisplayLink*)getDisplayLink {
  return display_link_.get();
}

@end

@implementation DisplayLinkManager

+ (double)displayRefreshRate {
  fml::scoped_nsobject<CADisplayLink> display_link = fml::scoped_nsobject<CADisplayLink> {
    [[CADisplayLink displayLinkWithTarget:[[[DisplayLinkManager alloc] init] autorelease]
                                 selector:@selector(onDisplayLink:)] retain]
  };
  display_link.get().paused = YES;
  auto preferredFPS = display_link.get().preferredFramesPerSecond;

  // From Docs:
  // The default value for preferredFramesPerSecond is 0. When this value is 0, the preferred
  // frame rate is equal to the maximum refresh rate of the display, as indicated by the
  // maximumFramesPerSecond property.

  if (preferredFPS != 0) {
    return preferredFPS;
  }

  return [UIScreen mainScreen].maximumFramesPerSecond;
}

- (void)onDisplayLink:(CADisplayLink*)link {
  // no-op.
}

+ (BOOL)maxRefreshRateEnabledOnIPhone {
  return [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CADisableMinimumFrameDurationOnPhone"]
      boolValue];
}

@end
