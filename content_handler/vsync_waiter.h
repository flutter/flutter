// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <lib/async/cpp/wait.h>

#include "flutter/shell/common/vsync_waiter.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/memory/weak_ptr.h"

namespace flutter {

class VsyncWaiter final : public shell::VsyncWaiter {
 public:
  static constexpr zx_signals_t SessionPresentSignal = ZX_EVENT_SIGNALED;

  VsyncWaiter(std::string debug_label,
              zx_handle_t session_present_handle,
              blink::TaskRunners task_runners);

  ~VsyncWaiter() override;

 private:
  const std::string debug_label_;
  async::Wait session_wait_;
  fxl::TimePoint phase_;
  fxl::WeakPtrFactory<VsyncWaiter> weak_factory_;

  // |shell::VsyncWaiter|
  void AwaitVSync() override;

  void FireCallbackWhenSessionAvailable();

  void FireCallbackNow();

  FXL_DISALLOW_COPY_AND_ASSIGN(VsyncWaiter);
};

}  // namespace flutter
