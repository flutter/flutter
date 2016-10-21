// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_GLU_BASE_TASK_RUNNER_H_
#define FLUTTER_GLU_BASE_TASK_RUNNER_H_

#include "base/memory/ref_counted.h"
#include "lib/ftl/tasks/task_runner.h"

namespace base {
class TaskRunner;
}  // namespace base

namespace glue {

class TaskRunnerAdaptor : public ftl::TaskRunner {
 public:
  explicit TaskRunnerAdaptor(scoped_refptr<base::TaskRunner> runner);

  void PostTask(ftl::Closure task) override;
  void PostTaskForTime(ftl::Closure task, ftl::TimePoint target_time) override;
  void PostDelayedTask(ftl::Closure task, ftl::TimeDelta delay) override;
  bool RunsTasksOnCurrentThread() override;

 protected:
  ~TaskRunnerAdaptor() override;

 private:
  scoped_refptr<base::TaskRunner> runner_;
};

}  // namespace glue

#endif  // FLUTTER_GLU_BASE_TASK_RUNNER_H_
