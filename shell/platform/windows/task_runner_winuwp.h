// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TASK_RUNNER_WINUWP_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TASK_RUNNER_WINUWP_H_

#include <third_party/cppwinrt/generated/winrt/Windows.Foundation.h>
#include <third_party/cppwinrt/generated/winrt/Windows.System.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/windows/task_runner.h"

namespace flutter {

// A custom task runner that uses a DispatcherQueue.
class TaskRunnerWinUwp : public TaskRunner {
 public:
  TaskRunnerWinUwp(CurrentTimeProc get_current_time,
                   const TaskExpiredCallback& on_task_expired);
  virtual ~TaskRunnerWinUwp();

  // |TaskRunner|
  bool RunsTasksOnCurrentThread() const override;

 protected:
  // |TaskRunner|
  void WakeUp() override;

 private:
  void OnTick(winrt::Windows::System::DispatcherQueueTimer const&,
              winrt::Windows::Foundation::IInspectable const&);

  void ProcessTasksAndScheduleNext();

  winrt::Windows::System::DispatcherQueue dispatcher_queue_{nullptr};
  winrt::Windows::System::DispatcherQueueTimer dispatcher_queue_timer_{nullptr};

  TaskRunnerWinUwp(const TaskRunnerWinUwp&) = delete;
  TaskRunnerWinUwp& operator=(const TaskRunnerWinUwp&) = delete;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TASK_RUNNER_WINUWP_H_
