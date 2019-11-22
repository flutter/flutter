// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/fml/task_runner.h"

#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/message_loop_impl.h"
#include "flutter/fml/message_loop_task_queues.h"

namespace fml {

TaskRunner::TaskRunner(fml::RefPtr<MessageLoopImpl> loop)
    : loop_(std::move(loop)) {}

TaskRunner::~TaskRunner() = default;

void TaskRunner::PostTask(const fml::closure& task) {
  loop_->PostTask(task, fml::TimePoint::Now());
}

void TaskRunner::PostTaskForTime(const fml::closure& task,
                                 fml::TimePoint target_time) {
  loop_->PostTask(task, target_time);
}

void TaskRunner::PostDelayedTask(const fml::closure& task,
                                 fml::TimeDelta delay) {
  loop_->PostTask(task, fml::TimePoint::Now() + delay);
}

TaskQueueId TaskRunner::GetTaskQueueId() {
  FML_DCHECK(loop_);
  return loop_->GetTaskQueueId();
}

bool TaskRunner::RunsTasksOnCurrentThread() {
  if (!fml::MessageLoop::IsInitializedForCurrentThread()) {
    return false;
  }

  const auto current_queue_id = MessageLoop::GetCurrentTaskQueueId();
  const auto loop_queue_id = loop_->GetTaskQueueId();

  if (current_queue_id == loop_queue_id) {
    return true;
  }

  auto queues = MessageLoopTaskQueues::GetInstance();
  if (queues->Owns(current_queue_id, loop_queue_id)) {
    return true;
  }
  if (queues->Owns(loop_queue_id, current_queue_id)) {
    return true;
  }

  return false;
}

void TaskRunner::RunNowOrPostTask(fml::RefPtr<fml::TaskRunner> runner,
                                  const fml::closure& task) {
  FML_DCHECK(runner);
  if (runner->RunsTasksOnCurrentThread()) {
    task();
  } else {
    runner->PostTask(std::move(task));
  }
}

}  // namespace fml
