// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/win32_window_proc_delegate_manager.h"

#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

Win32WindowProcDelegateManager::Win32WindowProcDelegateManager() = default;
Win32WindowProcDelegateManager::~Win32WindowProcDelegateManager() = default;

void Win32WindowProcDelegateManager::RegisterTopLevelWindowProcDelegate(
    FlutterDesktopWindowProcCallback delegate,
    void* user_data) {
  top_level_window_proc_handlers_[delegate] = user_data;
}

void Win32WindowProcDelegateManager::UnregisterTopLevelWindowProcDelegate(
    FlutterDesktopWindowProcCallback delegate) {
  top_level_window_proc_handlers_.erase(delegate);
}

std::optional<LRESULT> Win32WindowProcDelegateManager::OnTopLevelWindowProc(
    HWND hwnd,
    UINT message,
    WPARAM wparam,
    LPARAM lparam) {
  std::optional<LRESULT> result;
  for (const auto& [handler, user_data] : top_level_window_proc_handlers_) {
    LPARAM handler_result;
    // Stop as soon as any delegate indicates that it has handled the message.
    if (handler(hwnd, message, wparam, lparam, user_data, &handler_result)) {
      result = handler_result;
      break;
    }
  }
  return result;
}

}  // namespace flutter
