// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/vsync_waiter.h"

#include <vector>

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
    if (vsync_fire_sequence_number_ > vsync_fire_consumed_sequence_number_) {
      return;
    }
    if (!pre_frame_callbacks_.empty() || !secondary_callbacks_.empty()) {
      // Return directly as a callback has already armed the vsync waiter.
      return;
    }
  }
  AwaitVSync();
}

bool VsyncWaiter::CanRegisterCallbackForCurrentVsync() {
  std::scoped_lock lock(callback_mutex_);
  return vsync_fire_sequence_number_ > vsync_fire_consumed_sequence_number_;
}

void VsyncWaiter::SchedulePreFrameCallback(uintptr_t id,
                                           const fml::closure& callback) {
  FML_DCHECK(task_runners_.GetUITaskRunner()->RunsTasksOnCurrentThread());

  if (!callback) {
    return;
  }

  TRACE_EVENT0("flutter", "SchedulePreFrameCallback");

  {
    std::scoped_lock lock(callback_mutex_);
    const bool callbacks_originally_empty =
        pre_frame_callbacks_.empty() && secondary_callbacks_.empty();
    auto [_, inserted] = pre_frame_callbacks_.emplace(id, callback);
    if (!inserted) {
      TRACE_EVENT_INSTANT0("flutter",
                           "MultipleCallsToPreFrameVsyncInFrameInterval");
      return;
    }
    if (vsync_fire_sequence_number_ > vsync_fire_consumed_sequence_number_) {
      if (!callbacks_originally_empty) {
        return;
      }
    } else if (callback_ || !callbacks_originally_empty) {
      return;
    }
  }
  AwaitVSyncForSecondaryCallback();
}

void VsyncWaiter::ScheduleSecondaryCallback(uintptr_t id,
                                            const fml::closure& callback) {
  FML_DCHECK(task_runners_.GetUITaskRunner()->RunsTasksOnCurrentThread());

  if (!callback) {
    return;
  }

  TRACE_EVENT0("flutter", "ScheduleSecondaryCallback");

  {
    std::scoped_lock lock(callback_mutex_);
    const bool callbacks_originally_empty =
        pre_frame_callbacks_.empty() && secondary_callbacks_.empty();
    auto [_, inserted] = secondary_callbacks_.emplace(id, callback);
    if (!inserted) {
      // Multiple schedules must result in a single callback per frame interval.
      TRACE_EVENT_INSTANT0("flutter",
                           "MultipleCallsToSecondaryVsyncInFrameInterval");
      return;
    }
    if (vsync_fire_sequence_number_ > vsync_fire_consumed_sequence_number_) {
      if (!callbacks_originally_empty) {
        return;
      }
    } else if (callback_) {
      // Return directly as `AwaitVSync` is already called by
      // `AsyncWaitForVsync`.
      return;
    } else if (!callbacks_originally_empty) {
      // Return directly as another callback has already armed the vsync
      // waiter.
      return;
    }
  }
  AwaitVSyncForSecondaryCallback();
}

void VsyncWaiter::FireCallback(fml::TimePoint frame_start_time,
                               fml::TimePoint frame_target_time,
                               bool pause_secondary_tasks) {
  FML_DCHECK(fml::TimePoint::Now() >= frame_start_time);

  bool had_primary_callback = false;
  uint64_t vsync_fire_sequence_number = 0;
  std::vector<fml::closure> pre_frame_callbacks;
  std::vector<fml::closure> secondary_callbacks;

  {
    std::scoped_lock lock(callback_mutex_);
    had_primary_callback = static_cast<bool>(callback_);
    for (auto& pair : pre_frame_callbacks_) {
      pre_frame_callbacks.push_back(std::move(pair.second));
    }
    pre_frame_callbacks_.clear();
    for (auto& pair : secondary_callbacks_) {
      secondary_callbacks.push_back(std::move(pair.second));
    }
    secondary_callbacks_.clear();
    // Do not take callback_ until after the pre-frame callbacks have run. They
    // may synchronously process input and register a primary callback that can
    // still be rendered for this vsync. Track the generation so consuming an
    // older callback cannot close a newer vsync's registration window.
    if (had_primary_callback || !pre_frame_callbacks.empty()) {
      vsync_fire_sequence_number = ++vsync_fire_sequence_number_;
    }
  }

  if (!had_primary_callback && pre_frame_callbacks.empty() &&
      secondary_callbacks.empty()) {
    // This means that the vsync waiter implementation fired a callback for a
    // request we did not make. This is a paranoid check but we still want to
    // make sure we catch misbehaving vsync implementations.
    TRACE_EVENT_INSTANT0("flutter", "MismatchedFrameCallback");
    return;
  }

  const bool may_have_primary_callback =
      had_primary_callback || !pre_frame_callbacks.empty();
  if (may_have_primary_callback && pause_secondary_tasks) {
    PauseDartEventLoopTasks();
  }

  for (auto& pre_frame_callback : pre_frame_callbacks) {
    task_runners_.GetUITaskRunner()->PostTask(std::move(pre_frame_callback));
  }

  if (may_have_primary_callback) {
    fml::TaskQueueId ui_task_queue_id =
        task_runners_.GetUITaskRunner()->GetTaskQueueId();
    std::shared_ptr<VsyncWaiter> waiter = shared_from_this();
    task_runners_.GetUITaskRunner()->PostTask(
        [waiter, ui_task_queue_id, frame_start_time, frame_target_time,
         pause_secondary_tasks, vsync_fire_sequence_number]() {
          Callback callback;
          {
            std::scoped_lock lock(waiter->callback_mutex_);
            waiter->callback_.swap(callback);
            if (vsync_fire_sequence_number >
                waiter->vsync_fire_consumed_sequence_number_) {
              waiter->vsync_fire_consumed_sequence_number_ =
                  vsync_fire_sequence_number;
            }
          }

          if (callback) {
            const uint64_t flow_identifier = fml::tracing::TraceNonce();

            // The base trace ensures that flows have a root to begin from if
            // one does not exist. The trace viewer will ignore traces that
            // have no base event trace. While all our message loops insert a
            // base trace (MessageLoop::RunExpiredTasks), embedders may not.
            TRACE_EVENT0_WITH_FLOW_IDS("flutter", "VsyncFireCallback",
                                       /*flow_id_count=*/1,
                                       /*flow_ids=*/&flow_identifier);
            TRACE_FLOW_BEGIN("flutter", kVsyncFlowName, flow_identifier);
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
          }
          if (pause_secondary_tasks) {
            ResumeDartEventLoopTasks(ui_task_queue_id);
          }
        });
  }

  for (auto& secondary_callback : secondary_callbacks) {
    task_runners_.GetUITaskRunner()->PostTask(secondary_callback);
  }
}

void VsyncWaiter::PauseDartEventLoopTasks() {
  auto ui_task_queue_id = task_runners_.GetUITaskRunner()->GetTaskQueueId();
  auto task_queues = fml::MessageLoopTaskQueues::GetInstance();
  if (ui_task_queue_id.is_valid()) {
    task_queues->PauseSecondarySource(ui_task_queue_id);
  }
}

void VsyncWaiter::ResumeDartEventLoopTasks(fml::TaskQueueId ui_task_queue_id) {
  auto task_queues = fml::MessageLoopTaskQueues::GetInstance();
  if (ui_task_queue_id.is_valid()) {
    task_queues->ResumeSecondarySource(ui_task_queue_id);
  }
}

}  // namespace flutter
