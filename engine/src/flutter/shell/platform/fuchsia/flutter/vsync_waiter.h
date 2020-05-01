// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_VSYNC_WAITER_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_VSYNC_WAITER_H_

#include <lib/async/cpp/wait.h>

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/shell/common/vsync_waiter.h"
#include "flutter_runner_product_configuration.h"

namespace flutter_runner {

class VsyncWaiter final : public flutter::VsyncWaiter {
 public:
  static constexpr zx_signals_t SessionPresentSignal = ZX_EVENT_SIGNALED;

  VsyncWaiter(std::string debug_label,
              zx_handle_t session_present_handle,
              flutter::TaskRunners task_runners,
              fml::TimeDelta vsync_offset);

  ~VsyncWaiter() override;

  static fml::TimePoint SnapToNextPhase(
      const fml::TimePoint now,
      const fml::TimePoint last_frame_presentation_time,
      const fml::TimeDelta presentation_interval);

 private:
  const std::string debug_label_;
  async::Wait session_wait_;
  fml::TimeDelta vsync_offset_ = fml::TimeDelta::FromMicroseconds(0);

  fml::WeakPtrFactory<VsyncWaiter> weak_factory_;

  // For accessing the VsyncWaiter via the UI thread, necessary for the callback
  // for AwaitVSync()
  std::unique_ptr<fml::WeakPtrFactory<VsyncWaiter>> weak_factory_ui_;

  // |flutter::VsyncWaiter|
  void AwaitVSync() override;

  void FireCallbackWhenSessionAvailable();

  void FireCallbackNow();

  FML_DISALLOW_COPY_AND_ASSIGN(VsyncWaiter);
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_VSYNC_WAITER_H_
