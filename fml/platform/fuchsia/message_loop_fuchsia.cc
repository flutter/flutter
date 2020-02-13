// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/fuchsia/message_loop_fuchsia.h"

#include <lib/async-loop/default.h>
#include <lib/async/cpp/task.h>
#include <lib/zx/time.h>

namespace fml {

MessageLoopFuchsia::MessageLoopFuchsia()
    : loop_(&kAsyncLoopConfigAttachToCurrentThread) {}

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

  auto status = async::PostDelayedTask(
      loop_.dispatcher(), [this]() { RunExpiredTasksNow(); }, due_time);
  FML_DCHECK(status == ZX_OK);
}

}  // namespace fml
