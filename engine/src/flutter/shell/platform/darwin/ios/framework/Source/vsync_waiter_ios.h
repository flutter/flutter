// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_VSYNC_WAITER_IOS_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_VSYNC_WAITER_IOS_H_

#include "flutter/fml/macros.h"
#include "flutter/shell/common/variable_refresh_rate_reporter.h"
#include "flutter/shell/common/vsync_waiter.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterVSyncClient.h"

namespace flutter {

class VsyncWaiterIOS final : public VsyncWaiter,
                             public VariableRefreshRateReporter {
 public:
  explicit VsyncWaiterIOS(const flutter::TaskRunners& task_runners);

  ~VsyncWaiterIOS() override;

  // |VariableRefreshRateReporter|
  double GetRefreshRate() const override;

  // @brief Snaps the duration to the nearest whole Hz value and provides safe
  //        fallbacks. This ensures we don't introduce frame timing issues due
  //        to floating point error. e.g.
  //        59.998, 60.004, 59.995, ... --> 60.000
  //
  //        Additionally, guards against divide-by-zero and non-positive
  //        durations, which can occur on paused/unpaused transitions.
  //
  // Visible for testing.
  static CFTimeInterval SnapDuration(CFTimeInterval duration,
                                     double max_refresh_rate);

 private:
  // |VsyncWaiter|
  // Made public for testing.
  void AwaitVSync() override;

 private:
  FlutterVSyncClient* client_;
  double max_refresh_rate_;

  FML_DISALLOW_COPY_AND_ASSIGN(VsyncWaiterIOS);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_VSYNC_WAITER_IOS_H_
