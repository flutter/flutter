// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#define FML_USED_ON_EMBEDDER

#include <initializer_list>

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/shell/common/switches.h"

#include "gtest/gtest.h"
#include "thread_host.h"
#include "vsync_waiter.h"

namespace flutter {
namespace testing {

class TestVsyncWaiter : public VsyncWaiter {
 public:
  explicit TestVsyncWaiter(const TaskRunners& task_runners)
      : VsyncWaiter(task_runners) {}

  int await_vsync_call_count_ = 0;

 protected:
  void AwaitVSync() override { await_vsync_call_count_++; }
};

}  // namespace testing
}  // namespace flutter
