// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TASK_RUNNER_WIN32_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TASK_RUNNER_WIN32_H_

#include <windows.h>

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
  TaskRunnerWin32(CurrentTimeProc get_current_time,
                  const TaskExpiredCallback& on_task_expired);
  virtual ~TaskRunnerWin32();

  // |TaskRunner|
  bool RunsTasksOnCurrentThread() const override;

  // |TaskRunnerWin32Window::Delegate|
  std::chrono::nanoseconds ProcessTasks() override;

 protected:
  // |TaskRunner|
  void WakeUp() override;

 private:
  DWORD main_thread_id_;
  std::shared_ptr<TaskRunnerWin32Window> task_runner_window_;

  TaskRunnerWin32(const TaskRunnerWin32&) = delete;
  TaskRunnerWin32& operator=(const TaskRunnerWin32&) = delete;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TASK_RUNNER_WIN32_H_
