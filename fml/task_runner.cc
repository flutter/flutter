// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/task_runner.h"

#include <utility>

#include "flutter/fml/message_loop.h"
#include "flutter/fml/message_loop_impl.h"

namespace fml {

TaskRunner::TaskRunner(ftl::RefPtr<MessageLoopImpl> loop)
    : loop_(std::move(loop)) {
  FTL_CHECK(loop_);
}

TaskRunner::~TaskRunner() = default;

void TaskRunner::PostTask(ftl::Closure task) {
  loop_->PostTask(std::move(task), ftl::TimePoint::Now());
}

void TaskRunner::PostTaskForTime(ftl::Closure task,
                                 ftl::TimePoint target_time) {
  loop_->PostTask(std::move(task), target_time);
}

void TaskRunner::PostDelayedTask(ftl::Closure task, ftl::TimeDelta delay) {
  loop_->PostTask(std::move(task), ftl::TimePoint::Now() + delay);
}

bool TaskRunner::RunsTasksOnCurrentThread() {
  if (!fml::MessageLoop::IsInitializedForCurrentThread()) {
    return false;
  }
  return MessageLoop::GetCurrent().GetLoopImpl() == loop_;
}

}  // namespace fml
