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
#include "flutter/fml/trace_event.h"

namespace flutter {

VsyncWaiterIOS::VsyncWaiterIOS(flutter::TaskRunners task_runners)
    : VsyncWaiter(std::move(task_runners)) {
  auto callback = [this](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) {
    const fml::TimePoint start_time = recorder->GetVsyncStartTime();
    const fml::TimePoint target_time = recorder->GetVsyncTargetTime();
    FireCallback(start_time, target_time, true);
  };
  client_ =
      fml::scoped_nsobject{[[VSyncClient alloc] initWithTaskRunner:task_runners_.GetUITaskRunner()
                                                          callback:callback]};
}

VsyncWaiterIOS::~VsyncWaiterIOS() {
  // This way, we will get no more callbacks from the display link that holds a weak (non-nilling)
  // reference to this C++ object.
  [client_.get() invalidate];
}

void VsyncWaiterIOS::AwaitVSync() {
  [client_.get() await];
}

// |VariableRefreshRateReporter|
double VsyncWaiterIOS::GetRefreshRate() const {
  return [client_.get() getRefreshRate];
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
    callback_ = std::move(callback);
    display_link_ = fml::scoped_nsobject<CADisplayLink> {
      [[CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLink:)] retain]
    };
    display_link_.get().paused = YES;

    [self setMaxRefreshRateIfEnabled];

    task_runner->PostTask([client = [self retain]]() {
      [client->display_link_.get() addToRunLoop:[NSRunLoop currentRunLoop]
                                        forMode:NSRunLoopCommonModes];
      [client release];
    });
  }

  return self;
}

- (void)setMaxRefreshRateIfEnabled {
  NSNumber* minimumFrameRateDisabled =
      [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CADisableMinimumFrameDurationOnPhone"];
  if (![minimumFrameRateDisabled boolValue]) {
    return;
  }
  double maxFrameRate = fmax([DisplayLinkManager displayRefreshRate], 60);
  double minFrameRate = fmax(maxFrameRate / 2, 60);

  if (@available(iOS 15.0, *)) {
    display_link_.get().preferredFrameRateRange =
        CAFrameRateRangeMake(minFrameRate, maxFrameRate, maxFrameRate);
  } else if (@available(iOS 10.0, *)) {
    display_link_.get().preferredFramesPerSecond = maxFrameRate;
  }
}

- (void)await {
  display_link_.get().paused = NO;
}

- (void)onDisplayLink:(CADisplayLink*)link {
  TRACE_EVENT0("flutter", "VSYNC");

  CFTimeInterval delay = CACurrentMediaTime() - link.timestamp;
  fml::TimePoint frame_start_time = fml::TimePoint::Now() - fml::TimeDelta::FromSecondsF(delay);

  CFTimeInterval duration;
  if (@available(iOS 10.0, *)) {
    duration = link.targetTimestamp - link.timestamp;
  } else {
    duration = link.duration;
  }
  fml::TimePoint frame_target_time = frame_start_time + fml::TimeDelta::FromSecondsF(duration);

  std::unique_ptr<flutter::FrameTimingsRecorder> recorder =
      std::make_unique<flutter::FrameTimingsRecorder>();

  current_refresh_rate_ = round(1 / (frame_target_time - frame_start_time).ToSecondsF());

  recorder->RecordVsync(frame_start_time, frame_target_time);
  display_link_.get().paused = YES;
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
  if (@available(iOS 10.3, *)) {
    fml::scoped_nsobject<CADisplayLink> display_link = fml::scoped_nsobject<CADisplayLink> {
      [[CADisplayLink displayLinkWithTarget:[[[DisplayLinkManager alloc] init] autorelease]
                                   selector:@selector(onDisplayLink:)] retain]
    };
    display_link.get().paused = YES;
    auto preferredFPS = display_link.get().preferredFramesPerSecond;  // iOS 10.0

    // From Docs:
    // The default value for preferredFramesPerSecond is 0. When this value is 0, the preferred
    // frame rate is equal to the maximum refresh rate of the display, as indicated by the
    // maximumFramesPerSecond property.

    if (preferredFPS != 0) {
      return preferredFPS;
    }

    return [UIScreen mainScreen].maximumFramesPerSecond;  // iOS 10.3
  } else {
    return 60.0;
  }
}

- (void)onDisplayLink:(CADisplayLink*)link {
  // no-op.
}

@end
