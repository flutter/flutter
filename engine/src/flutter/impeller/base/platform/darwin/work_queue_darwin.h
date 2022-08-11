// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <dispatch/dispatch.h>

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/base/work_queue.h"

namespace impeller {

class WorkQueueDarwin final : public WorkQueue {
 public:
  static std::shared_ptr<WorkQueueDarwin> Create();

  // |WorkQueue|
  ~WorkQueueDarwin();

  bool IsValid() const;

 private:
  dispatch_queue_t queue_ = NULL;

  WorkQueueDarwin();

  // |WorkQueue|
  void PostTask(fml::closure task) override;

  FML_DISALLOW_COPY_AND_ASSIGN(WorkQueueDarwin);
};

}  // namespace impeller
