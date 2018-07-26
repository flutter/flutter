// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_TASK_RUNNER_H_
#define FLUTTER_FML_TASK_RUNNER_H_

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/time/time_point.h"

namespace fml {

class MessageLoopImpl;

class TaskRunner : public fml::RefCountedThreadSafe<TaskRunner> {
 public:
  void PostTask(fml::closure task);

  void PostTaskForTime(fml::closure task, fml::TimePoint target_time);

  void PostDelayedTask(fml::closure task, fml::TimeDelta delay);

  bool RunsTasksOnCurrentThread();

  static void RunNowOrPostTask(fml::RefPtr<fml::TaskRunner> runner,
                               fml::closure task);

 private:
  fml::RefPtr<MessageLoopImpl> loop_;

  TaskRunner(fml::RefPtr<MessageLoopImpl> loop);

  ~TaskRunner();

  FML_FRIEND_MAKE_REF_COUNTED(TaskRunner);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(TaskRunner);
  FML_DISALLOW_COPY_AND_ASSIGN(TaskRunner);
};

}  // namespace fml

#endif  // FLUTTER_FML_TASK_RUNNER_H_
