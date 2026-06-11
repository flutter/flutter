// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/windows_frame_clock.h"

#include <dxgi1_2.h>

#include <wrl/client.h>
#include <chrono>
#include <utility>

#include "flutter/fml/logging.h"

namespace flutter {

namespace {

constexpr DWORD kCompositorClockWaitTimeoutMs = 100;

using DCompositionWaitForCompositorClockProc =
    DWORD(WINAPI*)(UINT count, const HANDLE* handles, DWORD timeoutInMs);

DCompositionWaitForCompositorClockProc GetDCompositionWaitForCompositorClock() {
  static DCompositionWaitForCompositorClockProc wait_proc = [] {
    HMODULE dcomp = ::LoadLibraryW(L"dcomp.dll");
    if (!dcomp) {
      return static_cast<DCompositionWaitForCompositorClockProc>(nullptr);
    }
    return reinterpret_cast<DCompositionWaitForCompositorClockProc>(
        ::GetProcAddress(dcomp, "DCompositionWaitForCompositorClock"));
  }();
  return wait_proc;
}

bool WaitForDCompositionClock() {
  auto wait_proc = GetDCompositionWaitForCompositorClock();
  if (!wait_proc) {
    return false;
  }
  return wait_proc(0, nullptr, kCompositorClockWaitTimeoutMs) == WAIT_OBJECT_0;
}

HMONITOR GetNearestMonitor(HWND hwnd) {
  if (hwnd) {
    return ::MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
  }
  return ::MonitorFromPoint(POINT{0, 0}, MONITOR_DEFAULTTOPRIMARY);
}

Microsoft::WRL::ComPtr<IDXGIOutput> GetOutputForMonitor(HMONITOR monitor) {
  if (!monitor) {
    return nullptr;
  }

  Microsoft::WRL::ComPtr<IDXGIFactory1> factory;
  if (FAILED(::CreateDXGIFactory1(IID_PPV_ARGS(&factory)))) {
    return nullptr;
  }

  for (UINT adapter_index = 0;; ++adapter_index) {
    Microsoft::WRL::ComPtr<IDXGIAdapter1> adapter;
    if (factory->EnumAdapters1(adapter_index, &adapter) ==
        DXGI_ERROR_NOT_FOUND) {
      break;
    }

    for (UINT output_index = 0;; ++output_index) {
      Microsoft::WRL::ComPtr<IDXGIOutput> output;
      if (adapter->EnumOutputs(output_index, &output) == DXGI_ERROR_NOT_FOUND) {
        break;
      }

      DXGI_OUTPUT_DESC desc = {};
      if (SUCCEEDED(output->GetDesc(&desc)) && desc.Monitor == monitor) {
        return output;
      }
    }
  }

  return nullptr;
}

bool WaitForOutputVBlank(HWND hwnd) {
  auto output = GetOutputForMonitor(GetNearestMonitor(hwnd));
  return output && SUCCEEDED(output->WaitForVBlank());
}

}  // namespace

WindowsFrameClock::WindowsFrameClock(
    TaskRunner* task_runner,
    CurrentTimeProc get_current_time,
    FrameIntervalProvider frame_interval_provider,
    VsyncWaiter vsync_waiter)
    : task_runner_(task_runner),
      get_current_time_(get_current_time),
      frame_interval_provider_(std::move(frame_interval_provider)),
      vsync_waiter_(std::move(vsync_waiter)) {
  FML_DCHECK(task_runner_);
  FML_DCHECK(get_current_time_);
  FML_DCHECK(frame_interval_provider_);

  request_event_ = ::CreateEvent(nullptr, FALSE, FALSE, nullptr);
  stop_event_ = ::CreateEvent(nullptr, TRUE, FALSE, nullptr);
  FML_CHECK(request_event_);
  FML_CHECK(stop_event_);

  thread_ = std::thread(&WindowsFrameClock::ThreadMain, this);
}

WindowsFrameClock::~WindowsFrameClock() {
  {
    std::scoped_lock lock(mutex_);
    stopped_ = true;
  }

  ::SetEvent(stop_event_);
  if (thread_.joinable()) {
    thread_.join();
  }

  ::CloseHandle(request_event_);
  ::CloseHandle(stop_event_);
}

void WindowsFrameClock::SetFramePacingWindow(HWND hwnd) {
  std::scoped_lock lock(mutex_);
  pacing_window_ = hwnd;
}

void WindowsFrameClock::AwaitVsync(intptr_t baton, VsyncCallback callback) {
  if (!callback) {
    return;
  }

  PendingRequest request{baton, std::move(callback)};

  {
    std::scoped_lock lock(mutex_);
    if (stopped_) {
      return;
    }
    if (pending_request_) {
      FML_LOG(ERROR) << "Received multiple Windows vsync requests before the "
                        "previous request completed.";
      return;
    }
    pending_request_ = std::move(request);
  }

  ::SetEvent(request_event_);
}

void WindowsFrameClock::DispatchVsync(PendingRequest request) {
  const uint64_t frame_start_time = get_current_time_();
  HWND pacing_window = nullptr;
  {
    std::scoped_lock lock(mutex_);
    pacing_window = pacing_window_;
  }
  const uint64_t frame_target_time =
      frame_start_time + frame_interval_provider_(pacing_window).count();

  request.callback(request.baton, frame_start_time, frame_target_time);
}

bool WindowsFrameClock::WaitForDisplayVsync(HWND hwnd) {
  if (vsync_waiter_) {
    return vsync_waiter_(hwnd);
  }
  if (WaitForOutputVBlank(hwnd)) {
    return true;
  }
  return WaitForDCompositionClock();
}

bool WindowsFrameClock::WaitForFallbackInterval() {
  auto interval = std::chrono::duration_cast<std::chrono::milliseconds>(
      frame_interval_provider_(nullptr));
  if (interval.count() < 1) {
    interval = std::chrono::milliseconds(1);
  }

  DWORD wait_result =
      ::WaitForSingleObject(stop_event_, static_cast<DWORD>(interval.count()));
  return wait_result == WAIT_OBJECT_0;
}

void WindowsFrameClock::ThreadMain() {
  HANDLE request_or_stop[] = {stop_event_, request_event_};

  while (true) {
    DWORD wait_result =
        ::WaitForMultipleObjects(2, request_or_stop, FALSE, INFINITE);
    if (wait_result == WAIT_OBJECT_0) {
      return;
    }
    if (wait_result != WAIT_OBJECT_0 + 1) {
      FML_LOG(ERROR) << "Windows frame clock request wait failed.";
      continue;
    }

    PendingRequest request;
    HWND pacing_window = nullptr;
    {
      std::scoped_lock lock(mutex_);
      if (stopped_) {
        return;
      }
      if (!pending_request_) {
        continue;
      }
      request = std::move(*pending_request_);
      pending_request_.reset();
      pacing_window = pacing_window_;
    }

    if (!WaitForDisplayVsync(pacing_window)) {
      if (WaitForFallbackInterval()) {
        return;
      }
    }

    DispatchVsync(std::move(request));
  }
}

}  // namespace flutter
