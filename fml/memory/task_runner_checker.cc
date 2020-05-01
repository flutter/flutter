// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/memory/task_runner_checker.h"

namespace fml {

TaskRunnerChecker::TaskRunnerChecker()
    : initialized_queue_id_(InitTaskQueueId()){};

TaskRunnerChecker::~TaskRunnerChecker() = default;

bool TaskRunnerChecker::RunsOnCreationTaskRunner() const {
  FML_CHECK(fml::MessageLoop::IsInitializedForCurrentThread());

  const auto current_queue_id = MessageLoop::GetCurrentTaskQueueId();

  if (current_queue_id == initialized_queue_id_) {
    return true;
  }

  auto queues = MessageLoopTaskQueues::GetInstance();
  if (queues->Owns(current_queue_id, initialized_queue_id_)) {
    return true;
  }
  if (queues->Owns(initialized_queue_id_, current_queue_id)) {
    return true;
  }
  return false;
};

TaskQueueId TaskRunnerChecker::InitTaskQueueId() {
  MessageLoop::EnsureInitializedForCurrentThread();
  return MessageLoop::GetCurrentTaskQueueId();
};

}  // namespace fml
