// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_WINRT_TASK_RUNNER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_WINRT_TASK_RUNNER_H_

#include <windows.h>

#include <third_party/cppwinrt/generated/winrt/Windows.UI.Core.h>

#include <chrono>
#include <functional>
#include <thread>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/windows/task_runner.h"

namespace flutter {

// A custom task runner that uses a CoreDispatcher to schedule
// flutter tasks.
class TaskRunnerWinUwp : public TaskRunner {
 public:
  TaskRunnerWinUwp(DWORD main_thread_id,
                   const TaskExpiredCallback& on_task_expired);

  ~TaskRunnerWinUwp();

  TaskRunnerWinUwp(const TaskRunnerWinUwp&) = delete;
  TaskRunnerWinUwp& operator=(const TaskRunnerWinUwp&) = delete;

  // |TaskRunner|
  bool RunsTasksOnCurrentThread() const override;

  // |TaskRunner|
  void PostFlutterTask(FlutterTask flutter_task,
                       uint64_t flutter_target_time_nanos) override;

  // |TaskRunner|
  void PostTask(TaskClosure task) override;

 private:
  DWORD main_thread_id_;
  TaskExpiredCallback on_task_expired_;

  winrt::Windows::UI::Core::CoreDispatcher dispatcher_{nullptr};
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_WINRT_TASK_RUNNER_H_
