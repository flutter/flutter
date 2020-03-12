// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/vsync_waiter.h"

#include "flutter/fml/task_runner.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

static constexpr const char* kVsyncFlowName = "VsyncFlow";

#if defined(OS_FUCHSIA)
//  ________  _________  ________  ________
// |\   ____\|\___   ___\\   __  \|\   __  \
// \ \  \___|\|___ \  \_\ \  \|\  \ \  \|\  \
//  \ \_____  \   \ \  \ \ \  \\\  \ \   ____\
//   \|____|\  \   \ \  \ \ \  \\\  \ \  \___|
//     ____\_\  \   \ \__\ \ \_______\ \__\
//    |\_________\   \|__|  \|_______|\|__|
//    \|_________|
//
// Fuchsia benchmarks depend on this trace event's name.  Please do not change
// it without checking that the changes are compatible with Fuchsia benchmarks
// first!
static constexpr const char* kVsyncTraceName = "vsync callback";
#else
static constexpr const char* kVsyncTraceName = "VsyncProcessCallback";
#endif

VsyncWaiter::VsyncWaiter(TaskRunners task_runners)
    : task_runners_(std::move(task_runners)) {}

VsyncWaiter::~VsyncWaiter() = default;

// Public method invoked by the animator.
void VsyncWaiter::AsyncWaitForVsync(const Callback& callback) {
  if (!callback) {
    return;
  }

  TRACE_EVENT0("flutter", "AsyncWaitForVsync");

  {
    std::scoped_lock lock(callback_mutex_);
    if (callback_) {
      // The animator may request a frame more than once within a frame
      // interval. Multiple calls to request frame must result in a single
      // callback per frame interval.
      TRACE_EVENT_INSTANT0("flutter", "MultipleCallsToVsyncInFrameInterval");
      return;
    }
    callback_ = std::move(callback);
    if (secondary_callback_) {
      // Return directly as `AwaitVSync` is already called by
      // `ScheduleSecondaryCallback`.
      return;
    }
  }
  AwaitVSync();
}

void VsyncWaiter::ScheduleSecondaryCallback(const fml::closure& callback) {
  FML_DCHECK(task_runners_.GetUITaskRunner()->RunsTasksOnCurrentThread());

  if (!callback) {
    return;
  }

  TRACE_EVENT0("flutter", "ScheduleSecondaryCallback");

  {
    std::scoped_lock lock(callback_mutex_);
    if (secondary_callback_) {
      // Multiple schedules must result in a single callback per frame interval.
      TRACE_EVENT_INSTANT0("flutter",
                           "MultipleCallsToSecondaryVsyncInFrameInterval");
      return;
    }
    secondary_callback_ = std::move(callback);
    if (callback_) {
      // Return directly as `AwaitVSync` is already called by
      // `AsyncWaitForVsync`.
      return;
    }
  }
  AwaitVSync();
}

void VsyncWaiter::FireCallback(fml::TimePoint frame_start_time,
                               fml::TimePoint frame_target_time) {
  Callback callback;
  fml::closure secondary_callback;

  {
    std::scoped_lock lock(callback_mutex_);
    callback = std::move(callback_);
    secondary_callback = std::move(secondary_callback_);
  }

  if (!callback && !secondary_callback) {
    // This means that the vsync waiter implementation fired a callback for a
    // request we did not make. This is a paranoid check but we still want to
    // make sure we catch misbehaving vsync implementations.
    TRACE_EVENT_INSTANT0("flutter", "MismatchedFrameCallback");
    return;
  }

  if (callback) {
    auto flow_identifier = fml::tracing::TraceNonce();

    // The base trace ensures that flows have a root to begin from if one does
    // not exist. The trace viewer will ignore traces that have no base event
    // trace. While all our message loops insert a base trace trace
    // (MessageLoop::RunExpiredTasks), embedders may not.
    TRACE_EVENT0("flutter", "VsyncFireCallback");

    TRACE_FLOW_BEGIN("flutter", kVsyncFlowName, flow_identifier);

    task_runners_.GetUITaskRunner()->PostTaskForTime(
        [callback, flow_identifier, frame_start_time, frame_target_time]() {
          FML_TRACE_EVENT("flutter", kVsyncTraceName, "StartTime",
                          frame_start_time, "TargetTime", frame_target_time);
          fml::tracing::TraceEventAsyncComplete(
              "flutter", "VsyncSchedulingOverhead", fml::TimePoint::Now(),
              frame_start_time);
          callback(frame_start_time, frame_target_time);
          TRACE_FLOW_END("flutter", kVsyncFlowName, flow_identifier);
        },
        frame_start_time);
  }

  if (secondary_callback) {
    task_runners_.GetUITaskRunner()->PostTaskForTime(
        std::move(secondary_callback), frame_start_time);
  }
}

float VsyncWaiter::GetDisplayRefreshRate() const {
  return kUnknownRefreshRateFPS;
}

}  // namespace flutter
