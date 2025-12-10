// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TASK_RUNNER_WINDOW_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TASK_RUNNER_WINDOW_H_

#include <windows.h>

#include <chrono>
#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"

namespace flutter {

// Background timer thread. Necessary because neither SetTimer nor
// CreateThreadpoolTimer have good enough accuracy not to affect the
// framerate.
class TimerThread {
 public:
  explicit TimerThread(std::function<void()> callback);

  void Start();
  void Stop();

  ~TimerThread();

  // Schedules the callback to be called at specified time point. If there is
  // already a callback scheduled earlier than the specified time point, does
  // nothing.
  void ScheduleAt(
      std::chrono::time_point<std::chrono::high_resolution_clock> time_point);

 private:
  void TimerThreadMain();

  std::mutex mutex_;
  std::condition_variable cv_;
  std::function<void()> callback_;
  uint64_t schedule_counter_ = 0;
  std::chrono::time_point<std::chrono::high_resolution_clock> next_fire_time_;
  std::optional<std::thread> thread_;
};

// Hidden HWND responsible for processing flutter tasks on main thread
class TaskRunnerWindow {
 public:
  class Delegate {
   public:
    // Executes expired task, and returns the duration until the next task
    // deadline if exists, otherwise returns `std::chrono::nanoseconds::max()`.
    //
    // Each platform implementation must call this to schedule the tasks.
    virtual std::chrono::nanoseconds ProcessTasks() = 0;
  };

  static std::shared_ptr<TaskRunnerWindow> GetSharedInstance();

  // Triggers processing delegate tasks on main thread
  void WakeUp();

  void AddDelegate(Delegate* delegate);
  void RemoveDelegate(Delegate* delegate);

  void PollOnce(std::chrono::milliseconds timeout);

  ~TaskRunnerWindow();

 private:
  TaskRunnerWindow();

  void ProcessTasks();

  void SetTimer(std::chrono::nanoseconds when);

  WNDCLASS RegisterWindowClass();

  LRESULT
  HandleMessage(UINT const message,
                WPARAM const wparam,
                LPARAM const lparam) noexcept;

  static LRESULT CALLBACK WndProc(HWND const window,
                                  UINT const message,
                                  WPARAM const wparam,
                                  LPARAM const lparam) noexcept;

  void OnTimer();

  static void TimerProc(PTP_CALLBACK_INSTANCE Instance,
                        PVOID Context,
                        PTP_TIMER Timer);

  HWND window_handle_;
  std::wstring window_class_name_;
  std::vector<Delegate*> delegates_;
  DWORD thread_id_ = 0;
  TimerThread timer_thread_;

  FML_DISALLOW_COPY_AND_ASSIGN(TaskRunnerWindow);
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TASK_RUNNER_WINDOW_H_
