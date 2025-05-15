// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_host_window_controller.h"

#include <dwmapi.h>
#include <optional>
#include <vector>

#include "embedder.h"
#include "flutter/shell/platform/common/windowing.h"
#include "flutter/shell/platform/windows/flutter_host_window.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_view_controller.h"
#include "fml/logging.h"
#include "shell/platform/windows/client_wrapper/include/flutter/flutter_view.h"
#include "shell/platform/windows/flutter_host_window.h"
#include "shell/platform/windows/flutter_windows_view.h"

namespace flutter {

FlutterHostWindowController::FlutterHostWindowController(
    FlutterWindowsEngine* engine)
    : engine_(engine) {}

void FlutterHostWindowController::Initialize(
    const WindowingInitRequest* request) {
  on_message_ = request->on_message;
  isolate_ = Isolate::Current();

  // Send messages accumulated before isolate called this method.
  for (WindowsMessage& message : pending_messages_) {
    IsolateScope scope(*isolate_);
    on_message_(&message);
  }
  pending_messages_.clear();
}

bool FlutterHostWindowController::HasTopLevelWindows() const {
  return !active_windows_.empty();
}

FlutterViewId FlutterHostWindowController::CreateRegularWindow(
    const WindowCreationRequest* request) {
  auto window = std::make_unique<FlutterHostWindow>(
      this, WindowArchetype::kRegular, request->content_size);
  if (!window->GetWindowHandle()) {
    FML_LOG(ERROR) << "Failed to create host window";
    return 0;
  }
  FlutterViewId const view_id = window->view_controller_->view()->view_id();
  active_windows_[window->GetWindowHandle()] = std::move(window);
  return view_id;
}

void FlutterHostWindowController::OnEngineShutdown() {
  // Don't send any more messages to isolate.
  on_message_ = nullptr;
  std::vector<HWND> active_handles;
  active_handles.reserve(active_windows_.size());
  for (auto& [hwnd, window] : active_windows_) {
    active_handles.push_back(hwnd);
  }
  for (auto hwnd : active_handles) {
    // This will destroy the window, which will in turn remove the
    // FlutterHostWindow from map when handling WM_NCDESTROY inside
    // HandleMessage.
    DestroyWindow(hwnd);
  }
}

std::optional<LRESULT> FlutterHostWindowController::HandleMessage(
    HWND hwnd,
    UINT message,
    WPARAM wparam,
    LPARAM lparam) {
  if (message == WM_NCDESTROY) {
    active_windows_.erase(hwnd);
  }

  FlutterWindowsView* view = engine_->GetViewFromTopLevelWindow(hwnd);
  if (!view) {
    FML_LOG(WARNING) << "Received message for unknown view";
    return std::nullopt;
  }

  WindowsMessage message_struct = {.view_id = view->view_id(),
                                   .hwnd = hwnd,
                                   .message = message,
                                   .wParam = wparam,
                                   .lParam = lparam,
                                   .result = 0,
                                   .handled = false};

  // Not initialized yet.
  if (!isolate_) {
    pending_messages_.push_back(message_struct);
    return std::nullopt;
  }

  IsolateScope scope(*isolate_);
  on_message_(&message_struct);
  if (message_struct.handled) {
    return message_struct.result;
  } else {
    return std::nullopt;
  }
}

FlutterWindowsEngine* FlutterHostWindowController::engine() const {
  return engine_;
}

}  // namespace flutter

void FlutterWindowingInitialize(int64_t engine_id,
                                const flutter::WindowingInitRequest* request) {
  flutter::FlutterWindowsEngine* engine =
      flutter::FlutterWindowsEngine::GetEngineForId(engine_id);
  engine->get_host_window_controller()->Initialize(request);
}

bool FlutterWindowingHasTopLevelWindows(int64_t engine_id) {
  flutter::FlutterWindowsEngine* engine =
      flutter::FlutterWindowsEngine::GetEngineForId(engine_id);
  return engine->get_host_window_controller()->HasTopLevelWindows();
}

int64_t FlutterCreateRegularWindow(
    int64_t engine_id,
    const flutter::WindowCreationRequest* request) {
  flutter::FlutterWindowsEngine* engine =
      flutter::FlutterWindowsEngine::GetEngineForId(engine_id);
  return engine->get_host_window_controller()->CreateRegularWindow(request);
}

HWND FlutterGetWindowHandle(int64_t engine_id, FlutterViewId view_id) {
  flutter::FlutterWindowsEngine* engine =
      flutter::FlutterWindowsEngine::GetEngineForId(engine_id);
  flutter::FlutterWindowsView* view = engine->view(view_id);
  if (view == nullptr) {
    return nullptr;
  } else {
    return GetAncestor(view->GetWindowHandle(), GA_ROOT);
  }
}

FlutterWindowSize FlutterGetWindowContentSize(HWND hwnd) {
  RECT rect;
  GetClientRect(hwnd, &rect);
  double const dpr = FlutterDesktopGetDpiForHWND(hwnd) /
                     static_cast<double>(USER_DEFAULT_SCREEN_DPI);
  double const width = rect.right / dpr;
  double const height = rect.bottom / dpr;
  return {
      .width = rect.right / dpr,
      .height = rect.bottom / dpr,
  };
}

int64_t FlutterGetWindowState(HWND hwnd) {
  if (IsIconic(hwnd)) {
    return static_cast<int64_t>(flutter::WindowState::kMinimized);
  } else if (IsZoomed(hwnd)) {
    return static_cast<int64_t>(flutter::WindowState::kMaximized);
  } else {
    return static_cast<int64_t>(flutter::WindowState::kRestored);
  }
}

void FlutterSetWindowState(HWND hwnd, int64_t state) {
  switch (static_cast<flutter::WindowState>(state)) {
    case flutter::WindowState::kRestored:
      ShowWindow(hwnd, SW_RESTORE);
      break;
    case flutter::WindowState::kMaximized:
      ShowWindow(hwnd, SW_MAXIMIZE);
      break;
    case flutter::WindowState::kMinimized:
      ShowWindow(hwnd, SW_MINIMIZE);
      break;
  }
}

void FlutterSetWindowContentSize(HWND hwnd,
                                 const flutter::FlutterWindowSizing* size) {
  flutter::FlutterHostWindow* window =
      flutter::FlutterHostWindow::GetThisFromHandle(hwnd);
  if (window) {
    window->SetContentSize(*size);
  }
}
