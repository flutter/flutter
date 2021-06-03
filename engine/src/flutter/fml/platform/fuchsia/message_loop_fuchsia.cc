// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/fuchsia/message_loop_fuchsia.h"

#include <lib/async-loop/default.h>
#include <lib/async/cpp/task.h>
#include <lib/async/default.h>
#include <lib/zx/time.h>
#include "flutter/fml/platform/fuchsia/task_observers.h"

namespace fml {

namespace {

// See comment on `ExecuteAfterTaskObservers` for explanation.
static void LoopEpilogue(async_loop_t*, void*) {
  ExecuteAfterTaskObservers();
}

constexpr async_loop_config_t kLoopConfig = {
    .make_default_for_current_thread = false,
    .epilogue = &LoopEpilogue,
};

}  // namespace

MessageLoopFuchsia::MessageLoopFuchsia() : loop_(&kLoopConfig) {
  async_set_default_dispatcher(loop_.dispatcher());
}

MessageLoopFuchsia::~MessageLoopFuchsia() {
  // It is only safe to unset the current thread's default dispatcher if it is
  // already pointing to this loop.
  if (async_get_default_dispatcher() == loop_.dispatcher()) {
    async_set_default_dispatcher(nullptr);
  }
}

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
