// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/macros.h"
#include "impeller/base/work_queue.h"

namespace impeller {

class WorkQueueCommon : public WorkQueue {
 public:
  static std::shared_ptr<WorkQueueCommon> Create();

  // |WorkQueue|
  ~WorkQueueCommon();

 private:
  std::shared_ptr<fml::ConcurrentMessageLoop> loop_;

  WorkQueueCommon();

  // |WorkQueue|
  void PostTask(fml::closure task) override;

  FML_DISALLOW_COPY_AND_ASSIGN(WorkQueueCommon);
};

}  // namespace impeller
