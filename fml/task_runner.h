// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_TASK_RUNNER_H_
#define FLUTTER_FML_TASK_RUNNER_H_

#include "lib/ftl/macros.h"
#include "lib/ftl/memory/ref_counted.h"
#include "lib/ftl/tasks/task_runner.h"

namespace fml {

class MessageLoopImpl;

class TaskRunner : public ftl::TaskRunner {
 public:
  void PostTask(ftl::Closure task) override;

  void PostTaskForTime(ftl::Closure task, ftl::TimePoint target_time) override;

  void PostDelayedTask(ftl::Closure task, ftl::TimeDelta delay) override;

  bool RunsTasksOnCurrentThread() override;

 private:
  ftl::RefPtr<MessageLoopImpl> loop_;

  TaskRunner(ftl::RefPtr<MessageLoopImpl> loop);

  ~TaskRunner();

  FRIEND_MAKE_REF_COUNTED(TaskRunner);
  FRIEND_REF_COUNTED_THREAD_SAFE(TaskRunner);
  FTL_DISALLOW_COPY_AND_ASSIGN(TaskRunner);
};

}  // namespace fml

#endif  // FLUTTER_FML_TASK_RUNNER_H_
