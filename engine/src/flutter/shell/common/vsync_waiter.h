// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_VSYNC_WAITER_H_
#define FLUTTER_SHELL_COMMON_VSYNC_WAITER_H_

#include <functional>
#include <memory>
#include <mutex>
#include <unordered_map>

#include "flutter/common/task_runners.h"
#include "flutter/flow/frame_timings.h"
#include "flutter/fml/time/time_point.h"

namespace flutter {

/// Abstract Base Class that represents a platform specific mechanism for
/// getting callbacks when a vsync event happens.
///
/// @see VsyncWaiterAndroid
/// @see VsyncWaiterEmbedder
class VsyncWaiter : public std::enable_shared_from_this<VsyncWaiter> {
 public:
  using Callback = std::function<void(std::unique_ptr<FrameTimingsRecorder>)>;

  virtual ~VsyncWaiter();

  void AsyncWaitForVsync(const Callback& callback);

  /// Returns whether a primary callback registered now can participate in a
  /// platform vsync that has fired but has not yet been consumed on the UI task
  /// runner.
  bool CanRegisterCallbackForCurrentVsync();

  /// Adds a callback for key |id| to run immediately before the primary frame
  /// callback at the next vsync. A primary callback registered synchronously
  /// while a pre-frame callback is running participates in the same vsync.
  void SchedulePreFrameCallback(uintptr_t id, const fml::closure& callback);

  /// Add a secondary callback for key |id| for the next vsync.
  ///
  /// See also |Animator::ScheduleMaybeClearTraceFlowIds|.
  void ScheduleSecondaryCallback(uintptr_t id, const fml::closure& callback);

 protected:
  // On some backends, the |FireCallback| needs to be made from a static C
  // method.
  friend class VsyncWaiterAndroid;
  friend class VsyncWaiterEmbedder;

  const TaskRunners task_runners_;

  explicit VsyncWaiter(const TaskRunners& task_runners);

  // There are two distinct situations where VsyncWaiter wishes to awaken at
  // the next vsync. Although the functionality can be the same, the intent is
  // different, therefore it makes sense to have a method for each intent.

  // The intent of AwaitVSync() is that the Animator wishes to produce a frame.
  // The underlying implementation can choose to be aware of this intent when
  // it comes to implementing backpressure and other scheduling invariants.
  //
  // Implementations are meant to override this method and arm their vsync
  // latches when in response to this invocation. On vsync, they are meant to
  // invoke the |FireCallback| method once (and only once) with the appropriate
  // arguments. This method should not block the current thread.
  virtual void AwaitVSync() = 0;

  // The intent of AwaitVSyncForSecondaryCallback() is simply to wake up at the
  // next vsync.
  //
  // Because there is no association with frame scheduling, underlying
  // implementations do not need to worry about maintaining invariants or
  // backpressure. The default implementation is to simply follow the same logic
  // as AwaitVSync().
  virtual void AwaitVSyncForSecondaryCallback() { AwaitVSync(); }

  // Schedules the pre-frame, primary, and secondary callbacks on the UI task
  // runner in that order. Needs to be invoked as close to the
  // `frame_start_time` as possible.
  void FireCallback(fml::TimePoint frame_start_time,
                    fml::TimePoint frame_target_time,
                    bool pause_secondary_tasks = true);

 private:
  std::mutex callback_mutex_;
  Callback callback_;
  // The latest platform vsync generation posted to the UI task runner and the
  // latest generation whose primary callback task has begun. Their difference
  // preserves the registration window even if another platform vsync arrives
  // while the UI thread is still processing the previous generation.
  uint64_t vsync_fire_sequence_number_ = 0;
  uint64_t vsync_fire_consumed_sequence_number_ = 0;
  std::unordered_map<uintptr_t, fml::closure> pre_frame_callbacks_;
  std::unordered_map<uintptr_t, fml::closure> secondary_callbacks_;

  void PauseDartEventLoopTasks();
  static void ResumeDartEventLoopTasks(fml::TaskQueueId ui_task_queue_id);

  FML_DISALLOW_COPY_AND_ASSIGN(VsyncWaiter);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_VSYNC_WAITER_H_
