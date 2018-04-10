// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_VSYNC_WAITER_FALLBACK_H_
#define FLUTTER_SHELL_COMMON_VSYNC_WAITER_FALLBACK_H_

#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/shell/common/vsync_waiter.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/time/time_point.h"

namespace shell {

class VsyncWaiterFallback : public VsyncWaiter {
 public:
  VsyncWaiterFallback();
  ~VsyncWaiterFallback() override;

  void AsyncWaitForVsync(Callback callback) override;

 private:
  fxl::TimePoint phase_;
  Callback callback_;

  fml::WeakPtrFactory<VsyncWaiterFallback> weak_factory_;

  FXL_DISALLOW_COPY_AND_ASSIGN(VsyncWaiterFallback);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_COMMON_VSYNC_WAITER_FALLBACK_H_
