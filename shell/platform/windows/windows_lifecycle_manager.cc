// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "windows_lifecycle_manager.h"

#include <TlHelp32.h>
#include <WinUser.h>
#include <Windows.h>
#include <tchar.h>

#include "flutter/shell/platform/windows/flutter_windows_engine.h"

namespace flutter {

WindowsLifecycleManager::WindowsLifecycleManager(FlutterWindowsEngine* engine)
    : engine_(engine) {}

WindowsLifecycleManager::~WindowsLifecycleManager() {}

void WindowsLifecycleManager::Quit(UINT exit_code) const {
  ::PostQuitMessage(exit_code);
}

bool WindowsLifecycleManager::WindowProc(HWND hwnd,
                                         UINT msg,
                                         WPARAM wpar,
                                         LPARAM lpar,
                                         LRESULT* result) {
  switch (msg) {
    case WM_CLOSE:
      if (IsLastWindowOfProcess()) {
        engine_->RequestApplicationQuit(ExitType::cancelable, 0);
      }
      return true;
  }
  return false;
}

class ThreadSnapshot {
 public:
  ThreadSnapshot() {
    thread_snapshot_ = ::CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
  }
  ~ThreadSnapshot() {
    if (thread_snapshot_ != INVALID_HANDLE_VALUE) {
      ::CloseHandle(thread_snapshot_);
    }
  }

  std::optional<THREADENTRY32> GetFirstThread() {
    if (thread_snapshot_ == INVALID_HANDLE_VALUE) {
      FML_LOG(ERROR) << "Failed to get thread snapshot";
      return std::nullopt;
    }
    THREADENTRY32 thread;
    thread.dwSize = sizeof(thread);
    if (!::Thread32First(thread_snapshot_, &thread)) {
      DWORD error_num = ::GetLastError();
      char msg[256];
      ::FormatMessageA(
          FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, NULL,
          error_num, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), msg, 256,
          nullptr);
      FML_LOG(ERROR) << "Failed to get thread(" << error_num << "): " << msg;
      return std::nullopt;
    }
    return thread;
  }

  bool GetNextThread(THREADENTRY32& thread) {
    if (thread_snapshot_ == INVALID_HANDLE_VALUE) {
      return false;
    }
    return ::Thread32Next(thread_snapshot_, &thread);
  }

 private:
  HANDLE thread_snapshot_;
};

static int64_t NumWindowsForThread(const THREADENTRY32& thread) {
  int64_t num_windows = 0;
  ::EnumThreadWindows(
      thread.th32ThreadID,
      [](HWND hwnd, LPARAM lparam) {
        int64_t* windows_ptr = reinterpret_cast<int64_t*>(lparam);
        if (::GetParent(hwnd) == nullptr) {
          (*windows_ptr)++;
        }
        return *windows_ptr <= 1 ? TRUE : FALSE;
      },
      reinterpret_cast<LPARAM>(&num_windows));
  return num_windows;
}

bool WindowsLifecycleManager::IsLastWindowOfProcess() {
  DWORD pid = ::GetCurrentProcessId();
  ThreadSnapshot thread_snapshot;
  std::optional<THREADENTRY32> first_thread = thread_snapshot.GetFirstThread();
  if (!first_thread.has_value()) {
    FML_LOG(ERROR) << "No first thread found";
    return true;
  }

  int num_windows = 0;
  THREADENTRY32 thread = *first_thread;
  do {
    if (thread.th32OwnerProcessID == pid) {
      num_windows += NumWindowsForThread(thread);
      if (num_windows > 1) {
        return false;
      }
    }
  } while (thread_snapshot.GetNextThread(thread));

  return num_windows <= 1;
}

}  // namespace flutter
