// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vsync_waiter.h"

#include <lib/async/default.h>
#include "flutter/fml/trace_event.h"

#include "vsync_recorder.h"

namespace flutter_runner {

VsyncWaiter::VsyncWaiter(std::string debug_label,
                         zx_handle_t session_present_handle,
                         flutter::TaskRunners task_runners)
    : flutter::VsyncWaiter(task_runners),
      debug_label_(std::move(debug_label)),
      session_wait_(session_present_handle, SessionPresentSignal),
      weak_factory_(this) {
  auto wait_handler = [&](async_dispatcher_t* dispatcher,   //
                          async::Wait* wait,                //
                          zx_status_t status,               //
                          const zx_packet_signal_t* signal  //
                      ) {
    if (status != ZX_OK) {
      FML_LOG(ERROR) << "Vsync wait failed.";
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

static fml::TimePoint SnapToNextPhase(fml::TimePoint value,
                                      fml::TimePoint phase,
                                      fml::TimeDelta interval) {
  fml::TimeDelta offset = (phase - value) % interval;
  if (offset < fml::TimeDelta::Zero()) {
    offset = offset + interval;
  }
  return value + offset;
}

void VsyncWaiter::AwaitVSync() {
  VsyncInfo vsync_info = VsyncRecorder::GetInstance().GetCurrentVsyncInfo();

  fml::TimePoint now = fml::TimePoint::Now();
  fml::TimePoint next_vsync = SnapToNextPhase(now, vsync_info.presentation_time,
                                              vsync_info.presentation_interval);
  task_runners_.GetUITaskRunner()->PostDelayedTask(
      [self = weak_factory_.GetWeakPtr()] {
        if (self) {
          self->FireCallbackWhenSessionAvailable();
        }
      },
      next_vsync - now);
}

void VsyncWaiter::FireCallbackWhenSessionAvailable() {
  TRACE_EVENT0("flutter", "VsyncWaiter::FireCallbackWhenSessionAvailable");
  FML_DCHECK(task_runners_.GetUITaskRunner()->RunsTasksOnCurrentThread());
  if (session_wait_.Begin(async_get_default_dispatcher()) != ZX_OK) {
    FML_LOG(ERROR) << "Could not begin wait for Vsync.";
  }
}

void VsyncWaiter::FireCallbackNow() {
  FML_DCHECK(task_runners_.GetUITaskRunner()->RunsTasksOnCurrentThread());

  VsyncInfo vsync_info = VsyncRecorder::GetInstance().GetCurrentVsyncInfo();

  fml::TimePoint now = fml::TimePoint::Now();
  fml::TimePoint next_vsync = SnapToNextPhase(now, vsync_info.presentation_time,
                                              vsync_info.presentation_interval);
  fml::TimePoint previous_vsync = next_vsync - vsync_info.presentation_interval;

  FireCallback(previous_vsync, next_vsync);
}

}  // namespace flutter_runner
