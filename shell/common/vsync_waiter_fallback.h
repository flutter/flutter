// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_VSYNC_WAITER_FALLBACK_H_
#define FLUTTER_SHELL_COMMON_VSYNC_WAITER_FALLBACK_H_

#include "flutter/shell/common/vsync_waiter.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/memory/weak_ptr.h"
#include "lib/fxl/time/time_point.h"

namespace shell {

class VsyncWaiterFallback final : public VsyncWaiter {
 public:
  VsyncWaiterFallback(blink::TaskRunners task_runners);

  ~VsyncWaiterFallback() override;

 private:
  fxl::TimePoint phase_;
  fxl::WeakPtrFactory<VsyncWaiterFallback> weak_factory_;

  void AwaitVSync() override;

  FXL_DISALLOW_COPY_AND_ASSIGN(VsyncWaiterFallback);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_COMMON_VSYNC_WAITER_FALLBACK_H_
