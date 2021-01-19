// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TASK_RUNNER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TASK_RUNNER_H_

#include <windows.h>

#include <chrono>
#include <memory>

#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

typedef uint64_t (*CurrentTimeProc)();

// Abstract custom task runner for scheduling custom tasks.
class TaskRunner {
 public:
  using TaskTimePoint = std::chrono::steady_clock::time_point;
  using TaskExpiredCallback = std::function<void(const FlutterTask*)>;
  using TaskClosure = std::function<void()>;

  virtual ~TaskRunner() = default;

  // Returns if the current thread is the UI thread.
  virtual bool RunsTasksOnCurrentThread() const = 0;

  // Post a Flutter engine task to the event loop for delayed execution.
  virtual void PostFlutterTask(FlutterTask flutter_task,
                               uint64_t flutter_target_time_nanos) = 0;

  // Post a task to the event loop.
  virtual void PostTask(TaskClosure task) = 0;

  // Post a task to the event loop or run it immediately if this is being called
  // from the main thread.
  void RunNowOrPostTask(TaskClosure task) {
    if (RunsTasksOnCurrentThread()) {
      task();
    } else {
      PostTask(std::move(task));
    }
  }

  // Creates a new task runner with the given main thread ID, current time
  // provider, and callback for tasks that are ready to be run.
  static std::unique_ptr<TaskRunner> Create(
      DWORD main_thread_id,
      CurrentTimeProc get_current_time,
      const TaskExpiredCallback& on_task_expired);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TASK_RUNNER_H_
