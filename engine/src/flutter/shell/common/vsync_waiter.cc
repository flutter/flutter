// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/vsync_waiter.h"

#include "flow/frame_timings.h"
#include "flutter/fml/task_runner.h"
#include "flutter/fml/trace_event.h"
#include "fml/logging.h"
#include "fml/message_loop_task_queues.h"
#include "fml/task_queue_id.h"
#include "fml/time/time_point.h"

namespace flutter {

static constexpr const char* kVsyncFlowName = "VsyncFlow";

static constexpr const char* kVsyncTraceName = "VsyncProcessCallback";

VsyncWaiter::VsyncWaiter(const TaskRunners& task_runners)
    : task_runners_(task_runners) {}

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
    callback_ = callback;
  }
  AwaitVSync();
}

void VsyncWaiter::FireCallback(fml::TimePoint frame_start_time,
                               fml::TimePoint frame_target_time) {
  FML_DCHECK(fml::TimePoint::Now() >= frame_start_time);

  Callback callback;

  {
    std::scoped_lock lock(callback_mutex_);
    callback_.swap(callback);
  }

  if (!callback) {
    // This means that the vsync waiter implementation fired a callback for a
    // request we did not make. This is a paranoid check but we still want to
    // make sure we catch misbehaving vsync implementations.
    TRACE_EVENT_INSTANT0("flutter", "MismatchedFrameCallback");
    return;
  }

  if (callback) {
    const uint64_t flow_identifier = fml::tracing::TraceNonce();

    // The base trace ensures that flows have a root to begin from if one does
    // not exist. The trace viewer will ignore traces that have no base event
    // trace. While all our message loops insert a base trace trace
    // (MessageLoop::RunExpiredTasks), embedders may not.
    TRACE_EVENT0_WITH_FLOW_IDS("flutter", "VsyncFireCallback",
                               /*flow_id_count=*/1,
                               /*flow_ids=*/&flow_identifier);

    TRACE_FLOW_BEGIN("flutter", kVsyncFlowName, flow_identifier);

    task_runners_.GetUITaskRunner()->PostTask(
        [callback, flow_identifier, frame_start_time, frame_target_time]() {
          FML_TRACE_EVENT_WITH_FLOW_IDS(
              "flutter", kVsyncTraceName, /*flow_id_count=*/1,
              /*flow_ids=*/&flow_identifier, "StartTime", frame_start_time,
              "TargetTime", frame_target_time);
          std::unique_ptr<FrameTimingsRecorder> frame_timings_recorder =
              std::make_unique<FrameTimingsRecorder>();
          frame_timings_recorder->RecordVsync(frame_start_time,
                                              frame_target_time);
          callback(std::move(frame_timings_recorder));
          TRACE_FLOW_END("flutter", kVsyncFlowName, flow_identifier);
        });
  }
}

}  // namespace flutter
