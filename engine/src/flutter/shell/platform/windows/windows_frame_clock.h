// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOWS_FRAME_CLOCK_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOWS_FRAME_CLOCK_H_

#include <windows.h>

#include <chrono>
#include <cstdint>
#include <functional>
#include <mutex>
#include <optional>
#include <thread>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/windows/task_runner.h"

namespace flutter {

// Produces begin-frame signals for the Windows embedder.
//
// This class is intentionally only a frame clock. It does not use DXGI
// frame-latency waitable objects, since those are presentation backpressure
// signals rather than a reliable animation clock.
class WindowsFrameClock {
 public:
  using CurrentTimeProc = uint64_t (*)();
  using FrameIntervalProvider =
      std::function<std::chrono::nanoseconds(HWND hwnd)>;
  using VsyncWaiter = std::function<bool(HWND)>;
  using VsyncCallback = std::function<void(intptr_t baton,
                                           uint64_t frame_start_time_nanos,
                                           uint64_t frame_target_time_nanos)>;

  WindowsFrameClock(TaskRunner* task_runner,
                    CurrentTimeProc get_current_time,
                    FrameIntervalProvider frame_interval_provider,
                    VsyncWaiter vsync_waiter = nullptr);
  ~WindowsFrameClock();

  void SetFramePacingWindow(HWND hwnd);
  void AwaitVsync(intptr_t baton, VsyncCallback callback);

 private:
  struct PendingRequest {
    intptr_t baton = 0;
    VsyncCallback callback;
  };

  void ThreadMain();
  void DispatchVsync(PendingRequest request);
  bool WaitForDisplayVsync(HWND hwnd);
  bool WaitForFallbackInterval();

  TaskRunner* task_runner_ = nullptr;
  CurrentTimeProc get_current_time_ = nullptr;
  FrameIntervalProvider frame_interval_provider_;
  VsyncWaiter vsync_waiter_;

  HANDLE request_event_ = nullptr;
  HANDLE stop_event_ = nullptr;
  HWND pacing_window_ = nullptr;

  std::mutex mutex_;
  std::optional<PendingRequest> pending_request_;
  bool stopped_ = false;
  std::thread thread_;

  FML_DISALLOW_COPY_AND_ASSIGN(WindowsFrameClock);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOWS_FRAME_CLOCK_H_
