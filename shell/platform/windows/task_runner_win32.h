// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TASK_RUNNER_WIN32_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TASK_RUNNER_WIN32_H_

#include <windows.h>

#include <chrono>
#include <deque>
#include <functional>
#include <mutex>
#include <queue>
#include <thread>
#include <variant>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/windows/task_runner.h"
#include "flutter/shell/platform/windows/task_runner_win32_window.h"

namespace flutter {

// A custom task runner that integrates with user32 GetMessage semantics so that
// host app can own its own message loop and flutter still gets to process
// tasks on a timely basis.
class TaskRunnerWin32 : public TaskRunner,
                        public TaskRunnerWin32Window::Delegate {
 public:
  // Creates a new task runner with the given main thread ID, current time
  // provider, and callback for tasks that are ready to be run.
  TaskRunnerWin32(DWORD main_thread_id,
                  CurrentTimeProc get_current_time,
                  const TaskExpiredCallback& on_task_expired);

  virtual ~TaskRunnerWin32();

  // |TaskRunner|
  bool RunsTasksOnCurrentThread() const override;

  // |TaskRunner|
  void PostFlutterTask(FlutterTask flutter_task,
                       uint64_t flutter_target_time_nanos) override;

  // |TaskRunner|
  void PostTask(TaskClosure task) override;

  // |TaskRunnerWin32Window::Delegate|
  std::chrono::nanoseconds ProcessTasks() override;

 private:
  typedef std::variant<FlutterTask, TaskClosure> TaskVariant;

  struct Task {
    uint64_t order;
    TaskTimePoint fire_time;
    TaskVariant variant;

    struct Comparer {
      bool operator()(const Task& a, const Task& b) {
        if (a.fire_time == b.fire_time) {
          return a.order > b.order;
        }
        return a.fire_time > b.fire_time;
      }
    };
  };

  // Enqueues the given task.
  void EnqueueTask(Task task);

  // Returns a TaskTimePoint computed from the given target time from Flutter.
  TaskTimePoint TimePointFromFlutterTime(
      uint64_t flutter_target_time_nanos) const;

  DWORD main_thread_id_;
  CurrentTimeProc get_current_time_;
  TaskExpiredCallback on_task_expired_;
  std::mutex task_queue_mutex_;
  std::priority_queue<Task, std::deque<Task>, Task::Comparer> task_queue_;
  std::shared_ptr<TaskRunnerWin32Window> task_runner_window_;

  TaskRunnerWin32(const TaskRunnerWin32&) = delete;

  TaskRunnerWin32& operator=(const TaskRunnerWin32&) = delete;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TASK_RUNNER_WIN32_H_
