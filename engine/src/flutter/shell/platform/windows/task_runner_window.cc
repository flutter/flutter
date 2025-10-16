// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/task_runner_window.h"

#include <timeapi.h>
#include <algorithm>
#include <chrono>

#include "flutter/fml/logging.h"

namespace flutter {

// Timer used for PollOnce timeout.
static const uintptr_t kPollTimeoutTimerId = 1;

TaskRunnerWindow::TaskRunnerWindow() {
  WNDCLASS window_class = RegisterWindowClass();
  window_handle_ =
      CreateWindowEx(0, window_class.lpszClassName, L"", 0, 0, 0, 0, 0,
                     HWND_MESSAGE, nullptr, window_class.hInstance, nullptr);

  timer_ = CreateThreadpoolTimer(TimerProc, this, nullptr);
  if (!timer_) {
    FML_LOG(ERROR) << "Failed to create threadpool timer, error: "
                   << GetLastError();
    FML_CHECK(timer_);
  }

  if (window_handle_) {
    SetWindowLongPtr(window_handle_, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(this));
  } else {
    auto error = GetLastError();
    LPWSTR message = nullptr;
    size_t size = FormatMessageW(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
            FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL, error, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        reinterpret_cast<LPWSTR>(&message), 0, NULL);
    OutputDebugString(message);
    LocalFree(message);
  }

  thread_id_ = GetCurrentThreadId();

  // Increase timer precision for this process (the call only affects
  // current process since Windows 10, version 2004).
  timeBeginPeriod(1);
}

TaskRunnerWindow::~TaskRunnerWindow() {
  SetThreadpoolTimer(timer_, nullptr, 0, 0);
  // Ensures that no callbacks will run after CloseThreadpoolTimer.
  // https://learn.microsoft.com/en-us/windows/win32/api/threadpoolapiset/nf-threadpoolapiset-closethreadpooltimer#remarks
  WaitForThreadpoolTimerCallbacks(timer_, TRUE);
  CloseThreadpoolTimer(timer_);

  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
  UnregisterClass(window_class_name_.c_str(), nullptr);

  timeEndPeriod(1);
}

void TaskRunnerWindow::OnTimer() {
  if (!PostMessage(window_handle_, WM_NULL, 0, 0)) {
    FML_LOG(ERROR) << "Failed to post message to main thread.";
  }
}

void TaskRunnerWindow::TimerProc(PTP_CALLBACK_INSTANCE instance,
                                 PVOID context,
                                 PTP_TIMER timer) {
  reinterpret_cast<TaskRunnerWindow*>(context)->OnTimer();
}

std::shared_ptr<TaskRunnerWindow> TaskRunnerWindow::GetSharedInstance() {
  static std::weak_ptr<TaskRunnerWindow> instance;
  auto res = instance.lock();
  if (!res) {
    // can't use make_shared with private contructor
    res.reset(new TaskRunnerWindow());
    instance = res;
  }
  return res;
}

void TaskRunnerWindow::WakeUp() {
  // When waking up from main thread while there are messages in the message
  // queue use timer to post the WM_NULL message from background thread. This
  // gives message loop chance to process input events before WM_NULL is
  // processed - which is necessary because messages scheduled through
  // PostMessage take precedence over input event messages. Otherwise await
  // Future.delayed(Duration.zero) deadlocks the main thread. (See
  // https://github.com/flutter/flutter/issues/173843)
  if (thread_id_ == GetCurrentThreadId() && GetQueueStatus(QS_ALLEVENTS) != 0) {
    SetTimer(std::chrono::nanoseconds::zero());
    return;
  }

  if (!PostMessage(window_handle_, WM_NULL, 0, 0)) {
    FML_LOG(ERROR) << "Failed to post message to main thread.";
  }
}

void TaskRunnerWindow::AddDelegate(Delegate* delegate) {
  delegates_.push_back(delegate);
  SetTimer(std::chrono::nanoseconds::zero());
}

void TaskRunnerWindow::RemoveDelegate(Delegate* delegate) {
  auto i = std::find(delegates_.begin(), delegates_.end(), delegate);
  if (i != delegates_.end()) {
    delegates_.erase(i);
  }
}

void TaskRunnerWindow::PollOnce(std::chrono::milliseconds timeout) {
  MSG msg;
  ::SetTimer(window_handle_, kPollTimeoutTimerId, timeout.count(), nullptr);
  if (GetMessage(&msg, window_handle_, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }
  ::KillTimer(window_handle_, kPollTimeoutTimerId);
}

void TaskRunnerWindow::ProcessTasks() {
  auto next = std::chrono::nanoseconds::max();
  auto delegates_copy(delegates_);
  for (auto delegate : delegates_copy) {
    // if not removed in the meanwhile
    if (std::find(delegates_.begin(), delegates_.end(), delegate) !=
        delegates_.end()) {
      next = std::min(next, delegate->ProcessTasks());
    }
  }
  SetTimer(next);
}

void TaskRunnerWindow::SetTimer(std::chrono::nanoseconds when) {
  if (when == std::chrono::nanoseconds::max()) {
    SetThreadpoolTimer(timer_, nullptr, 0, 0);
  } else {
    auto microseconds =
        std::chrono::duration_cast<std::chrono::microseconds>(when).count();
    ULARGE_INTEGER ticks;
    ticks.QuadPart = -static_cast<LONGLONG>(microseconds * 10);
    FILETIME ft;
    ft.dwLowDateTime = ticks.LowPart;
    ft.dwHighDateTime = ticks.HighPart;
    SetThreadpoolTimer(timer_, &ft, 0, 0);
  }
}

WNDCLASS TaskRunnerWindow::RegisterWindowClass() {
  window_class_name_ = L"FlutterTaskRunnerWindow";

  WNDCLASS window_class{};
  window_class.hCursor = nullptr;
  window_class.lpszClassName = window_class_name_.c_str();
  window_class.style = 0;
  window_class.cbClsExtra = 0;
  window_class.cbWndExtra = 0;
  window_class.hInstance = GetModuleHandle(nullptr);
  window_class.hIcon = nullptr;
  window_class.hbrBackground = 0;
  window_class.lpszMenuName = nullptr;
  window_class.lpfnWndProc = WndProc;
  RegisterClass(&window_class);
  return window_class;
}

LRESULT
TaskRunnerWindow::HandleMessage(UINT const message,
                                WPARAM const wparam,
                                LPARAM const lparam) noexcept {
  switch (message) {
    case WM_NULL:
      ProcessTasks();
      return 0;
  }
  return DefWindowProcW(window_handle_, message, wparam, lparam);
}

LRESULT TaskRunnerWindow::WndProc(HWND const window,
                                  UINT const message,
                                  WPARAM const wparam,
                                  LPARAM const lparam) noexcept {
  if (auto* that = reinterpret_cast<TaskRunnerWindow*>(
          GetWindowLongPtr(window, GWLP_USERDATA))) {
    return that->HandleMessage(message, wparam, lparam);
  } else {
    return DefWindowProc(window, message, wparam, lparam);
  }
}

}  // namespace flutter
