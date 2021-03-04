// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TASK_RUNNER_WIN32_WINDOW_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TASK_RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <chrono>
#include <memory>
#include <string>
#include <vector>

namespace flutter {

// Hidden HWND responsible for processing flutter tasks on main thread
class TaskRunnerWin32Window {
 public:
  class Delegate {
   public:
    virtual std::chrono::nanoseconds ProcessTasks() = 0;
  };

  static std::shared_ptr<TaskRunnerWin32Window> GetSharedInstance();

  // Triggers processing delegate tasks on main thread
  void WakeUp();

  void AddDelegate(Delegate* delegate);
  void RemoveDelegate(Delegate* delegate);

  ~TaskRunnerWin32Window();

 private:
  TaskRunnerWin32Window();

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

  HWND window_handle_;
  std::wstring window_class_name_;
  std::vector<Delegate*> delegates_;
};
}  // namespace flutter

#endif
