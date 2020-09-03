// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vsync_waiter.h"

#include <cstdint>

#include <lib/async/default.h>

#include "flutter/fml/logging.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/trace_event.h"

#include "flutter_runner_product_configuration.h"
#include "vsync_recorder.h"

namespace flutter_runner {

VsyncWaiter::VsyncWaiter(std::string debug_label,
                         zx_handle_t session_present_handle,
                         flutter::TaskRunners task_runners,
                         fml::TimeDelta vsync_offset)
    : flutter::VsyncWaiter(task_runners),
      debug_label_(std::move(debug_label)),
      session_wait_(session_present_handle, SessionPresentSignal),
      vsync_offset_(vsync_offset),
      weak_factory_ui_(nullptr),
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

  // Generate a WeakPtrFactory for use with the UI thread. This does not need
  // to wait on a latch because we only ever use the WeakPtrFactory on the UI
  // thread so we have ordering guarantees (see ::AwaitVSync())
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetUITaskRunner(), fml::MakeCopyable([this]() mutable {
        this->weak_factory_ui_ =
            std::make_unique<fml::WeakPtrFactory<VsyncWaiter>>(this);
      }));
  session_wait_.set_handler(wait_handler);

  if (vsync_offset_ >= fml::TimeDelta::FromSeconds(1)) {
    FML_LOG(WARNING) << "Given vsync_offset is extremely high: "
                     << vsync_offset_.ToMilliseconds() << "ms";
  } else {
    FML_LOG(INFO) << "Set vsync_offset to " << vsync_offset_.ToMicroseconds()
                  << "us";
  }
}

VsyncWaiter::~VsyncWaiter() {
  session_wait_.Cancel();

  fml::AutoResetWaitableEvent ui_latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetUITaskRunner(),
      fml::MakeCopyable(
          [weak_factory_ui = std::move(weak_factory_ui_), &ui_latch]() mutable {
            weak_factory_ui.reset();
            ui_latch.Signal();
          }));
  ui_latch.Wait();
}

/// Returns the system time at which the next frame is likely to be presented.
///
/// Consider the following scenarios, where in both the
/// scenarious the result will be the same.
///
/// Scenario 1:
/// presentation_interval is 2
/// ^     ^     ^     ^     ^
/// +     +     +     +     +
/// 0--1--2--3--4--5--6--7--8--9--
/// +        +  +
/// |        |  +---------> result: next_presentation_time
/// |        v
/// v        now
/// last_presentation_time
///
/// Scenario 2:
/// presentation_interval is 2
/// ^     ^     ^     ^     ^
/// +     +     +     +     +
/// 0--1--2--3--4--5--6--7--8--9--
///       +  +  +
///       |  |  +--------->result: next_presentation_time
///       |  |
///       |  +>now
///       |
///       +->last_presentation_time
fml::TimePoint VsyncWaiter::SnapToNextPhase(
    const fml::TimePoint now,
    const fml::TimePoint last_frame_presentation_time,
    const fml::TimeDelta presentation_interval) {
  if (presentation_interval <= fml::TimeDelta::Zero()) {
    FML_LOG(ERROR) << "Presentation interval must be positive. The value was: "
                   << presentation_interval.ToMilliseconds() << "ms.";
    return now;
  }

  if (last_frame_presentation_time >= now) {
    FML_LOG(ERROR)
        << "Last frame was presented in the future. Clamping to now.";
    return now + presentation_interval;
  }

  const fml::TimeDelta time_since_last_presentation =
      now - last_frame_presentation_time;
  // this will be the most likely scenario if we are rendering at a good
  // frame rate, short circuiting the other checks in this case.
  if (time_since_last_presentation < presentation_interval) {
    return last_frame_presentation_time + presentation_interval;
  } else {
    const int64_t num_phases_passed =
        (time_since_last_presentation / presentation_interval);
    return last_frame_presentation_time +
           (presentation_interval * (num_phases_passed + 1));
  }
}

void VsyncWaiter::AwaitVSync() {
  VsyncInfo vsync_info = VsyncRecorder::GetInstance().GetCurrentVsyncInfo();

  fml::TimePoint now = fml::TimePoint::Now();
  fml::TimePoint last_presentation_time =
      VsyncRecorder::GetInstance().GetLastPresentationTime();

  fml::TimePoint next_vsync =
      VsyncRecorder::GetInstance().GetCurrentVsyncInfo().presentation_time;

  if (next_vsync <= now) {
    next_vsync = SnapToNextPhase(now, last_presentation_time,
                                 vsync_info.presentation_interval);
  }

  auto next_vsync_start_time = next_vsync - vsync_offset_;

  if (now >= next_vsync_start_time)
    next_vsync_start_time =
        next_vsync_start_time + vsync_info.presentation_interval;

  fml::TimeDelta delta = next_vsync_start_time - now;

  task_runners_.GetUITaskRunner()->PostDelayedTask(
      [&weak_factory_ui = this->weak_factory_ui_] {
        if (!weak_factory_ui) {
          FML_LOG(WARNING) << "WeakPtrFactory for VsyncWaiter is null, likely "
                              "due to the VsyncWaiter being destroyed.";
          return;
        }
        auto self = weak_factory_ui->GetWeakPtr();
        if (self) {
          self->FireCallbackWhenSessionAvailable();
        }
      },
      delta);
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
  fml::TimePoint last_presentation_time =
      VsyncRecorder::GetInstance().GetLastPresentationTime();
  fml::TimePoint next_vsync =
      VsyncRecorder::GetInstance().GetCurrentVsyncInfo().presentation_time;

  if (next_vsync <= now) {
    next_vsync = SnapToNextPhase(now, last_presentation_time,
                                 vsync_info.presentation_interval);
  }
  fml::TimePoint previous_vsync = next_vsync - vsync_info.presentation_interval;

  FireCallback(previous_vsync, next_vsync);
}

}  // namespace flutter_runner
