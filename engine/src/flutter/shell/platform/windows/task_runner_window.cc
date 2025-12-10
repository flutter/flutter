// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/task_runner_window.h"

#include <timeapi.h>
#include <algorithm>
#include <chrono>
#include <functional>
#include <mutex>
#include <thread>

#include "flutter/fml/logging.h"

namespace flutter {

TimerThread::TimerThread(std::function<void()> callback)
    : callback_(std::move(callback)),
      next_fire_time_(
          std::chrono::time_point<std::chrono::high_resolution_clock>::max()) {}

void TimerThread::Start() {
  FML_DCHECK(!thread_);
  thread_ =
      std::make_optional<std::thread>(&TimerThread::TimerThreadMain, this);
}

void TimerThread::Stop() {
  if (!thread_) {
    return;
  }
  {
    std::lock_guard<std::mutex> lock(mutex_);
    callback_ = nullptr;
  }
  cv_.notify_all();
  thread_->join();
}

TimerThread::~TimerThread() {
  // Ensure that Stop() has been called if Start() has been called.
  FML_DCHECK(callback_ == nullptr || !thread_);
}

// Schedules the callback to be called at specified time point. If there is
// already a callback scheduled earlier than the specified time point, does
// nothing.
void TimerThread::ScheduleAt(
    std::chrono::time_point<std::chrono::high_resolution_clock> time_point) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (time_point < next_fire_time_) {
    next_fire_time_ = time_point;
  }
  ++schedule_counter_;
  cv_.notify_all();
}

void TimerThread::TimerThreadMain() {
  std::unique_lock<std::mutex> lock(mutex_);
  while (callback_ != nullptr) {
    cv_.wait_until(lock, next_fire_time_, [this]() {
      return std::chrono::high_resolution_clock::now() >= next_fire_time_ ||
             callback_ == nullptr;
    });
    auto scheduled_count = schedule_counter_;
    if (callback_) {
      lock.unlock();
      callback_();
      lock.lock();
    }
    // If nothing was scheduled in the meanwhile park the timer.
    if (scheduled_count == schedule_counter_ &&
        next_fire_time_ <= std::chrono::high_resolution_clock::now()) {
      next_fire_time_ =
          std::chrono::time_point<std::chrono::high_resolution_clock>::max();
    }
  }
}

// Timer used for PollOnce timeout.
static const uintptr_t kPollTimeoutTimerId = 1;

TaskRunnerWindow::TaskRunnerWindow() : timer_thread_([this]() { OnTimer(); }) {
  WNDCLASS window_class = RegisterWindowClass();
  window_handle_ =
      CreateWindowEx(0, window_class.lpszClassName, L"", 0, 0, 0, 0, 0,
                     HWND_MESSAGE, nullptr, window_class.hInstance, nullptr);

  if (window_handle_) {
    SetWindowLongPtr(window_handle_, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(this));
    timer_thread_.Start();
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
}

TaskRunnerWindow::~TaskRunnerWindow() {
  timer_thread_.Stop();

  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
  UnregisterClass(window_class_name_.c_str(), nullptr);
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
    SetTimer(std::chrono::milliseconds(1));
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
    timer_thread_.ScheduleAt(
        std::chrono::time_point<std::chrono::high_resolution_clock>::max());
  } else {
    timer_thread_.ScheduleAt(std::chrono::high_resolution_clock::now() + when);
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
