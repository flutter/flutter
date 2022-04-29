// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/event_watcher_win32.h"

namespace flutter {

EventWatcherWin32::EventWatcherWin32(std::function<void()> callback)
    : callback_(callback) {
  handle_ = CreateEvent(NULL, TRUE, FALSE, NULL);

  RegisterWaitForSingleObject(&handle_for_wait_, handle_, &CallbackForWait,
                              reinterpret_cast<void*>(this), INFINITE,
                              WT_EXECUTEONLYONCE | WT_EXECUTEINWAITTHREAD);
}

EventWatcherWin32::~EventWatcherWin32() {
  UnregisterWait(handle_for_wait_);
  CloseHandle(handle_);
}

HANDLE EventWatcherWin32::GetHandle() {
  return handle_;
}

// static
VOID CALLBACK EventWatcherWin32::CallbackForWait(PVOID context, BOOLEAN) {
  EventWatcherWin32* self = reinterpret_cast<EventWatcherWin32*>(context);
  ResetEvent(self->handle_);
  self->callback_();
}

}  // namespace flutter
