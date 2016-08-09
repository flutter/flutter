// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file provides an interface for "task runners", which are used within the
// EDK itself.

#ifndef MOJO_EDK_PLATFORM_TASK_RUNNER_H_
#define MOJO_EDK_PLATFORM_TASK_RUNNER_H_

#include <functional>

#include "mojo/edk/util/ref_counted.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace platform {

// Interface for "task runners", which can be used to schedule tasks to be run
// asynchronously (possibly on a different thread). Implementations must be
// thread-safe.
class TaskRunner : public util::RefCountedThreadSafe<TaskRunner> {
 public:
  virtual ~TaskRunner() {}

  // Posts a task to this task runner (i.e., schedule the task). The task must
  // be run (insofar as this can be guaranteed). (This must not run the task
  // synchronously.)
  virtual void PostTask(std::function<void()>&& task) = 0;

  // Returns true if this task runner may run tasks on the current thread, false
  // otherwise (e.g., if this task runner only runs tasks on a different
  // thread).
  virtual bool RunsTasksOnCurrentThread() const = 0;

 protected:
  TaskRunner() {}

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(TaskRunner);
};

}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_TASK_RUNNER_H_
