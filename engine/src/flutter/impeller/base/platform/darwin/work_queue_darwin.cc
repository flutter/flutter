// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/base/platform/darwin/work_queue_darwin.h"

namespace impeller {

std::shared_ptr<WorkQueueDarwin> WorkQueueDarwin::Create() {
  auto queue = std::shared_ptr<WorkQueueDarwin>(new WorkQueueDarwin());
  if (!queue->IsValid()) {
    return nullptr;
  }
  return queue;
}

WorkQueueDarwin::WorkQueueDarwin()
    : queue_(::dispatch_queue_create(
          "io.flutter.impeller.wq",
          ::dispatch_queue_attr_make_with_qos_class(
              DISPATCH_QUEUE_CONCURRENT_WITH_AUTORELEASE_POOL,
              QOS_CLASS_USER_INITIATED,
              -1))) {}

WorkQueueDarwin::~WorkQueueDarwin() = default;

bool WorkQueueDarwin::IsValid() const {
  return queue_ != NULL;
}

// |WorkQueue|
void WorkQueueDarwin::PostTask(fml::closure task) {
  dispatch_async(queue_, ^() {
    task();
  });
}

}  // namespace impeller
