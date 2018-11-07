// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/vsync_waiter.h"

#include "flutter/fml/task_runner.h"
#include "flutter/fml/trace_event.h"

namespace shell {

VsyncWaiter::VsyncWaiter(blink::TaskRunners task_runners)
    : task_runners_(std::move(task_runners)) {}

VsyncWaiter::~VsyncWaiter() = default;

void VsyncWaiter::AsyncWaitForVsync(Callback callback) {
  {
    std::lock_guard<std::mutex> lock(callback_mutex_);
    callback_ = std::move(callback);
  }
  AwaitVSync();
}

void VsyncWaiter::FireCallback(fml::TimePoint frame_start_time,
                               fml::TimePoint frame_target_time) {
  Callback callback;

  {
    std::lock_guard<std::mutex> lock(callback_mutex_);
    callback = std::move(callback_);
  }

  if (!callback) {
    return;
  }

  task_runners_.GetUITaskRunner()->PostTask(
      [callback, frame_start_time, frame_target_time]() {
#if defined(OS_FUCHSIA)
        // In general, traces on Fuchsia are recorded across the whole system.
        // Because of this, emitting a "VSYNC" event per flutter process is
        // undesirable, as the events will collide with each other.  We
        // instead let another area of the system emit them.
        TRACE_EVENT0("flutter", "vsync callback");
#else
        // Note: The tag name must be "VSYNC" (it is special) so that the
        // "Highlight Vsync" checkbox in the timeline can be enabled.
        TRACE_EVENT0("flutter", "VSYNC");
#endif
        callback(frame_start_time, frame_target_time);
      });
}

}  // namespace shell
