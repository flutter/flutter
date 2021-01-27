// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/task_runner_winuwp.h"

#include <atomic>
#include <utility>

namespace flutter {

// static
std::unique_ptr<TaskRunner> TaskRunner::Create(
    DWORD main_thread_id,
    CurrentTimeProc get_current_time,
    const TaskExpiredCallback& on_task_expired) {
  return std::make_unique<TaskRunnerWinUwp>(main_thread_id, on_task_expired);
}

TaskRunnerWinUwp::TaskRunnerWinUwp(DWORD main_thread_id,
                                   const TaskExpiredCallback& on_task_expired)
    : main_thread_id_(main_thread_id),
      on_task_expired_(std::move(on_task_expired)) {
  dispatcher_ =
      winrt::Windows::UI::Core::CoreWindow::GetForCurrentThread().Dispatcher();
}

TaskRunnerWinUwp::~TaskRunnerWinUwp() = default;

bool TaskRunnerWinUwp::RunsTasksOnCurrentThread() const {
  return GetCurrentThreadId() == main_thread_id_;
}

void TaskRunnerWinUwp::PostFlutterTask(FlutterTask flutter_task,
                                       uint64_t flutter_target_time_nanos) {
  // TODO: Handle the target time. See
  // https://github.com/flutter/flutter/issues/70890.

  dispatcher_.RunAsync(
      winrt::Windows::UI::Core::CoreDispatcherPriority::Normal,
      [this, flutter_task]() { on_task_expired_(&flutter_task); });
}

void TaskRunnerWinUwp::PostTask(TaskClosure task) {
  // TODO: Handle the target time. See PostFlutterTask()

  dispatcher_.RunAsync(winrt::Windows::UI::Core::CoreDispatcherPriority::Normal,
                       [task]() { task(); });
}

}  // namespace flutter
