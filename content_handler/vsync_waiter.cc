// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "third_party/flutter/content_handler/vsync_waiter.h"

#include "lib/fsl/tasks/message_loop.h"

namespace flutter {

VsyncWaiter::VsyncWaiter(std::string debug_label,
                         zx_handle_t session_present_handle,
                         blink::TaskRunners task_runners)
    : shell::VsyncWaiter(task_runners),
      debug_label_(std::move(debug_label)),
      session_wait_(session_present_handle, SessionPresentSignal),
      phase_(fxl::TimePoint::Now()),
      weak_factory_(this) {
  auto wait_handler = [&](async_t* async,                   //
                          async::Wait* wait,                //
                          zx_status_t status,               //
                          const zx_packet_signal_t* signal  //
                      ) {
    if (status != ZX_OK) {
      FXL_LOG(ERROR) << "Vsync wait failed.";
      return;
    }

    wait->Cancel();

    FireCallbackNow();
  };

  session_wait_.set_handler(wait_handler);
}

VsyncWaiter::~VsyncWaiter() {
  session_wait_.Cancel();
}

static constexpr fxl::TimeDelta kFrameInterval =
    fxl::TimeDelta::FromSecondsF(1.0 / 60.0);

static fxl::TimePoint SnapToNextPhase(fxl::TimePoint value,
                                      fxl::TimePoint phase,
                                      fxl::TimeDelta interval) {
  fxl::TimeDelta offset = (phase - value) % interval;
  if (offset != fxl::TimeDelta::Zero()) {
    offset = offset + interval;
  }
  return value + offset;
}

void VsyncWaiter::AwaitVSync() {
  fxl::TimePoint now = fxl::TimePoint::Now();
  fxl::TimePoint next = SnapToNextPhase(now, phase_, kFrameInterval);
  task_runners_.GetUITaskRunner()->PostDelayedTask(
      [self = weak_factory_.GetWeakPtr()] {
        if (self) {
          self->FireCallbackWhenSessionAvailable();
        }
      },
      next - now);
}

void VsyncWaiter::FireCallbackWhenSessionAvailable() {
  FXL_DCHECK(task_runners_.GetUITaskRunner()->RunsTasksOnCurrentThread());
  if (session_wait_.Begin(fsl::MessageLoop::GetCurrent()->async()) != ZX_OK) {
    FXL_LOG(ERROR) << "Could not begin wait for Vsync.";
  }
}

void VsyncWaiter::FireCallbackNow() {
  FXL_DCHECK(task_runners_.GetUITaskRunner()->RunsTasksOnCurrentThread());

  auto now = fxl::TimePoint::Now();

  // We don't know the display refresh rate on this platform. Since the target
  // time is advisory, assume kFrameInterval.
  auto next = now + kFrameInterval;

  phase_ = now;

  FireCallback(now, next);
}

}  // namespace flutter
