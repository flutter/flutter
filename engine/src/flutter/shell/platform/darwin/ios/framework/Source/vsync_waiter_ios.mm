// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunner+FML.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterVSyncClient.h"

FLUTTER_ASSERT_ARC

// When calculating refresh rate diffrence, anything within 0.1 fps is ignored.
const static double kRefreshRateDiffToIgnore = 0.1;

namespace flutter {

VsyncWaiterIOS::VsyncWaiterIOS(const flutter::TaskRunners& task_runners)
    : VsyncWaiter(task_runners) {
  auto vsyncCallback = ^(CFTimeInterval startTime, CFTimeInterval targetTime) {
    fml::TimePoint start_time = fml::TimePoint() + fml::TimeDelta::FromSecondsF(startTime);
    fml::TimePoint target_time = fml::TimePoint() + fml::TimeDelta::FromSecondsF(targetTime);
    FireCallback(start_time, target_time, true);
  };
  FlutterFMLTaskRunner* uiTaskRunner =
      [[FlutterFMLTaskRunner alloc] initWithTaskRunner:task_runners_.GetUITaskRunner()];
  client_ = [[FlutterVSyncClient alloc]
                initWithTaskRunner:uiTaskRunner
      isVariableRefreshRateEnabled:FlutterDisplayLinkManager.maxRefreshRateEnabledOnIPhone
                    maxRefreshRate:FlutterDisplayLinkManager.displayRefreshRate
                          callback:vsyncCallback];
  max_refresh_rate_ = FlutterDisplayLinkManager.displayRefreshRate;
}

VsyncWaiterIOS::~VsyncWaiterIOS() {
  // This way, we will get no more callbacks from the display link that holds a weak (non-nilling)
  // reference to this C++ object.
  [client_ invalidate];
}

void VsyncWaiterIOS::AwaitVSync() {
  double new_max_refresh_rate = FlutterDisplayLinkManager.displayRefreshRate;
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
