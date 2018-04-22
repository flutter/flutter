// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_TASK_RUNNER_H_
#define FLUTTER_FML_TASK_RUNNER_H_

#include "flutter/fml/macros.h"
#include "lib/fxl/memory/ref_counted.h"
#include "lib/fxl/tasks/task_runner.h"

namespace fml {

class MessageLoopImpl;

class TaskRunner final : public fxl::TaskRunner {
 public:
  void PostTask(fxl::Closure task) override;

  void PostTaskForTime(fxl::Closure task, fxl::TimePoint target_time) override;

  void PostDelayedTask(fxl::Closure task, fxl::TimeDelta delay) override;

  bool RunsTasksOnCurrentThread() override;

  static void RunNowOrPostTask(fxl::RefPtr<fxl::TaskRunner> runner,
                               fxl::Closure task);

 private:
  fxl::RefPtr<MessageLoopImpl> loop_;

  TaskRunner(fxl::RefPtr<MessageLoopImpl> loop);

  ~TaskRunner() override;

  FRIEND_MAKE_REF_COUNTED(TaskRunner);
  FRIEND_REF_COUNTED_THREAD_SAFE(TaskRunner);
  FML_DISALLOW_COPY_AND_ASSIGN(TaskRunner);
};

}  // namespace fml

#endif  // FLUTTER_FML_TASK_RUNNER_H_
