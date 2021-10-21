// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/task_runner_winuwp.h"

namespace flutter {

// static
std::unique_ptr<TaskRunner> TaskRunner::Create(
    CurrentTimeProc get_current_time,
    const TaskExpiredCallback& on_task_expired) {
  return std::make_unique<TaskRunnerWinUwp>(get_current_time, on_task_expired);
}

TaskRunnerWinUwp::TaskRunnerWinUwp(CurrentTimeProc get_current_time,
                                   const TaskExpiredCallback& on_task_expired)
    : TaskRunner(get_current_time, on_task_expired) {
  dispatcher_queue_ =
      winrt::Windows::System::DispatcherQueue::GetForCurrentThread();
  dispatcher_queue_timer_ = dispatcher_queue_.CreateTimer();
  dispatcher_queue_timer_.Tick({this, &TaskRunnerWinUwp::OnTick});
}

TaskRunnerWinUwp::~TaskRunnerWinUwp() = default;

bool TaskRunnerWinUwp::RunsTasksOnCurrentThread() const {
  return dispatcher_queue_.HasThreadAccess();
}

void TaskRunnerWinUwp::WakeUp() {
  dispatcher_queue_.TryEnqueue([this]() { ProcessTasksAndScheduleNext(); });
}

void TaskRunnerWinUwp::OnTick(
    winrt::Windows::System::DispatcherQueueTimer const&,
    winrt::Windows::Foundation::IInspectable const&) {
  ProcessTasks();
}

void TaskRunnerWinUwp::ProcessTasksAndScheduleNext() {
  auto next = ProcessTasks();

  if (next == std::chrono::nanoseconds::max()) {
    dispatcher_queue_timer_.Stop();
  } else {
    dispatcher_queue_timer_.Interval(
        std::chrono::duration_cast<winrt::Windows::Foundation::TimeSpan>(next));
    dispatcher_queue_timer_.Start();
  }
}

}  // namespace flutter
