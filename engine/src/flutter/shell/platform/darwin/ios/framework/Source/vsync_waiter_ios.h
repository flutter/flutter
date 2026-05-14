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
