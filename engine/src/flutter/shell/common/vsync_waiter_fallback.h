// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_VSYNC_WAITER_FALLBACK_H_
#define FLUTTER_SHELL_COMMON_VSYNC_WAITER_FALLBACK_H_

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/shell/common/vsync_waiter.h"

namespace shell {

class VsyncWaiterFallback final : public VsyncWaiter {
 public:
  VsyncWaiterFallback(blink::TaskRunners task_runners);

  ~VsyncWaiterFallback() override;

 private:
  fml::TimePoint phase_;
  fml::WeakPtrFactory<VsyncWaiterFallback> weak_factory_;

  // |shell::VsyncWaiter|
  void AwaitVSync() override;

  FML_DISALLOW_COPY_AND_ASSIGN(VsyncWaiterFallback);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_COMMON_VSYNC_WAITER_FALLBACK_H_
