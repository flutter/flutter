// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/base/work_queue_common.h"

namespace impeller {

std::shared_ptr<WorkQueueCommon> WorkQueueCommon::Create() {
  return std::shared_ptr<WorkQueueCommon>(new WorkQueueCommon());
}

WorkQueueCommon::WorkQueueCommon()
    : loop_(fml::ConcurrentMessageLoop::Create(2u)) {}

WorkQueueCommon::~WorkQueueCommon() {
  loop_->Terminate();
}

// |WorkQueue|
void WorkQueueCommon::PostTask(fml::closure task) {
  loop_->GetTaskRunner()->PostTask(task);
}

}  // namespace impeller
