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

namespace shell {

class VsyncWaiter : public std::enable_shared_from_this<VsyncWaiter> {
 public:
  using Callback = std::function<void(fml::TimePoint frame_start_time,
                                      fml::TimePoint frame_target_time)>;

  virtual ~VsyncWaiter();

  void AsyncWaitForVsync(Callback callback);

  void FireCallback(fml::TimePoint frame_start_time,
                    fml::TimePoint frame_target_time);

 protected:
  const blink::TaskRunners task_runners_;
  std::mutex callback_mutex_;
  Callback callback_;

  VsyncWaiter(blink::TaskRunners task_runners);

  virtual void AwaitVSync() = 0;

  FML_DISALLOW_COPY_AND_ASSIGN(VsyncWaiter);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_COMMON_VSYNC_WAITER_H_
