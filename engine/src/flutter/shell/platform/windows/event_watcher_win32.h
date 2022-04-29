// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_EVENT_WATCHER_WIN32_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_EVENT_WATCHER_WIN32_H_

#include <Windows.h>

#include <functional>

namespace flutter {

// A win32 `HANDLE` wrapper for use as a one-time callback.
class EventWatcherWin32 {
 public:
  explicit EventWatcherWin32(std::function<void()> callback);
  ~EventWatcherWin32();

  // Returns `HANDLE`, which can be used to register an event listener.
  HANDLE GetHandle();

 private:
  static VOID CALLBACK CallbackForWait(PVOID context, BOOLEAN);

  std::function<void()> callback_;

  HANDLE handle_;
  HANDLE handle_for_wait_;

  EventWatcherWin32(const EventWatcherWin32&) = delete;
  EventWatcherWin32& operator=(const EventWatcherWin32&) = delete;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_EVENT_WATCHER_WIN32_H_
