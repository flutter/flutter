// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"

#import "flutter/shell/platform/darwin/common/InternalFlutterSwiftCommon/InternalFlutterSwiftCommon.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/InternalFlutterSwift/InternalFlutterSwift.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunner+FML.h"

FLUTTER_ASSERT_ARC

// When calculating refresh rate diffrence, anything within 0.1 fps is ignored.
const static double kRefreshRateDiffToIgnore = 0.1;

extern bool FlutterDispatchingTouches;
extern bool FlutterDidPresentSurface;

namespace flutter {

VsyncWaiterIOS::VsyncWaiterIOS(const flutter::TaskRunners& task_runners,
                               FlutterDisplayLinkManager* display_link_manager)
    : VsyncWaiter(task_runners), display_link_manager_(display_link_manager) {
  FML_DCHECK(display_link_manager);
  auto vsyncCallback = ^(CFTimeInterval startTime, CFTimeInterval targetTime) {
    if (!waiting_for_vsync_) {
      if (--idle_countdown_ == 0) {
        [client_ pause];
      }
      return;
    }
    waiting_for_vsync_ = false;
    idle_countdown_ = 10;

    // Compute delay using the same CACurrentMediaTime() clock.
    CFTimeInterval delay = CACurrentMediaTime() - startTime;
    if (delay < 0.0) {
      delay = 0.0;
    }

    // Align the start time to the C++ steady_clock used by fml::TimePoint.
    fml::TimePoint start_time = fml::TimePoint::Now() - fml::TimeDelta::FromSecondsF(delay);

    // Snap to the nearest whole Hz value to avoid floating point errors.
    CFTimeInterval duration =
        VsyncWaiterIOS::SnapDuration(targetTime - startTime, max_refresh_rate_);

    // Align target time to the C++ steady_clock used by fml::TimePoint.
    fml::TimePoint target_time = start_time + fml::TimeDelta::FromSecondsF(duration);
    FireCallback(start_time, target_time, true);

    if (block_until_frame_available_) {
      block_until_frame_available_ = false;
      FlutterDidPresentSurface = false;
      CFTimeInterval startTime = CACurrentMediaTime();
      while (!FlutterDidPresentSurface && CACurrentMediaTime() - startTime < 0.5) {
        [FlutterRunLoop.mainRunLoop pollFlutterMessagesOnce];
      }
    }
  };
  FlutterFMLTaskRunner* uiTaskRunner =
      [[FlutterFMLTaskRunner alloc] initWithTaskRunner:task_runners_.GetUITaskRunner()];
  client_ = [[FlutterVSyncClient alloc]
                initWithTaskRunner:uiTaskRunner
      isVariableRefreshRateEnabled:display_link_manager_.maxRefreshRateEnabledOnIPhone
                    maxRefreshRate:display_link_manager_.displayRefreshRate
                          callback:vsyncCallback];
  client_.allowPauseAfterVsync = false;
  max_refresh_rate_ = display_link_manager_.displayRefreshRate;
}

VsyncWaiterIOS::~VsyncWaiterIOS() {
  // This way, we will get no more callbacks from the display link that holds a weak (non-nilling)
  // reference to this C++ object.
  [client_ invalidate];
}

void VsyncWaiterIOS::AwaitVSync() {
  double new_max_refresh_rate = display_link_manager_.displayRefreshRate;
  if (fabs(new_max_refresh_rate - max_refresh_rate_) > kRefreshRateDiffToIgnore) {
    max_refresh_rate_ = new_max_refresh_rate;
    [client_ setMaxRefreshRate:max_refresh_rate_];
  }

  if (client_.displayLink.paused) {
    [client_ await];
    FireCallback(fml::TimePoint::Now(), fml::TimePoint::Now(), false);
  } else {
    waiting_for_vsync_ = true;
    if (FlutterDispatchingTouches) {
      block_until_frame_available_ = true;
    }
  }
}

// |VariableRefreshRateReporter|
double VsyncWaiterIOS::GetRefreshRate() const {
  return client_.refreshRate;
}

CFTimeInterval VsyncWaiterIOS::SnapDuration(CFTimeInterval duration, double max_refresh_rate) {
  if (duration > 0.0) {
    double roundedRefreshRate = round(1.0 / duration);
    return 1.0 / roundedRefreshRate;
  }
  double fallbackRefreshRate = max_refresh_rate > 0.0 ? max_refresh_rate : 60.0;
  return 1.0 / fallbackRefreshRate;
}

}  // namespace flutter
