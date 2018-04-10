// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/task_runner.h"

#include <utility>

#include "flutter/fml/message_loop.h"
#include "flutter/fml/message_loop_impl.h"

namespace fml {

TaskRunner::TaskRunner(fxl::RefPtr<MessageLoopImpl> loop)
    : loop_(std::move(loop)) {
  FXL_CHECK(loop_);
}

TaskRunner::~TaskRunner() = default;

void TaskRunner::PostTask(fxl::Closure task) {
  loop_->PostTask(std::move(task), fxl::TimePoint::Now());
}

void TaskRunner::PostTaskForTime(fxl::Closure task,
                                 fxl::TimePoint target_time) {
  loop_->PostTask(std::move(task), target_time);
}

void TaskRunner::PostDelayedTask(fxl::Closure task, fxl::TimeDelta delay) {
  loop_->PostTask(std::move(task), fxl::TimePoint::Now() + delay);
}

bool TaskRunner::RunsTasksOnCurrentThread() {
  if (!fml::MessageLoop::IsInitializedForCurrentThread()) {
    return false;
  }
  return MessageLoop::GetCurrent().GetLoopImpl() == loop_;
}

}  // namespace fml
