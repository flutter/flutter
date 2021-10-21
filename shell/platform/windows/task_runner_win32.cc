// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/task_runner_win32.h"

namespace flutter {

// static
std::unique_ptr<TaskRunner> TaskRunner::Create(
    CurrentTimeProc get_current_time,
    const TaskExpiredCallback& on_task_expired) {
  return std::make_unique<TaskRunnerWin32>(get_current_time, on_task_expired);
}

TaskRunnerWin32::TaskRunnerWin32(CurrentTimeProc get_current_time,
                                 const TaskExpiredCallback& on_task_expired)
    : TaskRunner(get_current_time, on_task_expired) {
  main_thread_id_ = GetCurrentThreadId();
  task_runner_window_ = TaskRunnerWin32Window::GetSharedInstance();
  task_runner_window_->AddDelegate(this);
}

TaskRunnerWin32::~TaskRunnerWin32() {
  task_runner_window_->RemoveDelegate(this);
}

bool TaskRunnerWin32::RunsTasksOnCurrentThread() const {
  return GetCurrentThreadId() == main_thread_id_;
}

std::chrono::nanoseconds TaskRunnerWin32::ProcessTasks() {
  return TaskRunner::ProcessTasks();
}

void TaskRunnerWin32::WakeUp() {
  task_runner_window_->WakeUp();
}

}  // namespace flutter
