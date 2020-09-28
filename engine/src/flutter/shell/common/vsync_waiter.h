// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_VSYNC_WAITER_H_
#define FLUTTER_SHELL_COMMON_VSYNC_WAITER_H_

#include <functional>
#include <memory>
#include <mutex>

#include "flutter/common/task_runners.h"
#include "flutter/fml/time/time_point.h"

namespace flutter {

/// Abstract Base Class that represents a platform specific mechanism for
/// getting callbacks when a vsync event happens.
class VsyncWaiter : public std::enable_shared_from_this<VsyncWaiter> {
 public:
  using Callback = std::function<void(fml::TimePoint frame_start_time,
                                      fml::TimePoint frame_target_time)>;

  virtual ~VsyncWaiter();

  void AsyncWaitForVsync(const Callback& callback);

  /// Add a secondary callback for the next vsync.
  ///
  /// See also |PointerDataDispatcher::ScheduleSecondaryVsyncCallback|.
  void ScheduleSecondaryCallback(const fml::closure& callback);

  static constexpr float kUnknownRefreshRateFPS = 0.0;

  // Get the display's maximum refresh rate in the unit of frame per second.
  // Return kUnknownRefreshRateFPS if the refresh rate is unknown.
  virtual float GetDisplayRefreshRate() const;

 protected:
  // On some backends, the |FireCallback| needs to be made from a static C
  // method.
  friend class VsyncWaiterAndroid;
  friend class VsyncWaiterEmbedder;

  const TaskRunners task_runners_;

  VsyncWaiter(TaskRunners task_runners);

  // Implementations are meant to override this method and arm their vsync
  // latches when in response to this invocation. On vsync, they are meant to
  // invoke the |FireCallback| method once (and only once) with the appropriate
  // arguments. This method should not block the current thread.
  virtual void AwaitVSync() = 0;

  void FireCallback(fml::TimePoint frame_start_time,
                    fml::TimePoint frame_target_time);

 private:
  std::mutex callback_mutex_;
  Callback callback_;

  std::mutex secondary_callback_mutex_;
  fml::closure secondary_callback_;

  FML_DISALLOW_COPY_AND_ASSIGN(VsyncWaiter);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_VSYNC_WAITER_H_
