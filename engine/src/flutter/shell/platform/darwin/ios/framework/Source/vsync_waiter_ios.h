// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_VSYNC_WAITER_IOS_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_VSYNC_WAITER_IOS_H_

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/vsync_waiter.h"

@class VSyncClient;

namespace flutter {

class VsyncWaiterIOS final : public VsyncWaiter {
 public:
  VsyncWaiterIOS(flutter::TaskRunners task_runners);

  ~VsyncWaiterIOS() override;

 private:
  fml::scoped_nsobject<VSyncClient> client_;

  // |VsyncWaiter|
  void AwaitVSync() override;

  // |VsyncWaiter|
  float GetDisplayRefreshRate() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(VsyncWaiterIOS);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_VSYNC_WAITER_IOS_H_
