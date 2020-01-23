// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/fuchsia/message_loop_fuchsia.h"

#include <lib/async-loop/default.h>
#include <lib/zx/time.h>

namespace fml {

MessageLoopFuchsia::MessageLoopFuchsia()
    : loop_(&kAsyncLoopConfigAttachToCurrentThread) {
  auto handler = [this](async_dispatcher_t* dispatcher, async::Task* task,
                        zx_status_t status) { RunExpiredTasksNow(); };
  task_.set_handler(handler);
}

MessageLoopFuchsia::~MessageLoopFuchsia() = default;

void MessageLoopFuchsia::Run() {
  loop_.Run();
}

void MessageLoopFuchsia::Terminate() {
  loop_.Quit();
}

void MessageLoopFuchsia::WakeUp(fml::TimePoint time_point) {
  fml::TimePoint now = fml::TimePoint::Now();
  zx::duration due_time{0};
  if (time_point > now) {
    due_time = zx::nsec((time_point - now).ToNanoseconds());
  }

  std::scoped_lock lock(task_mutex_);

  auto status = task_.Cancel();
  FML_DCHECK(status == ZX_OK || status == ZX_ERR_NOT_FOUND);

  status = task_.PostDelayed(loop_.dispatcher(), due_time);
  FML_DCHECK(status == ZX_OK);
}

}  // namespace fml
