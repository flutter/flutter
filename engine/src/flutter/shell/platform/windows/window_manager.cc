// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/window_manager.h"

#include <dwmapi.h>
#include <optional>
#include <vector>

#include "embedder.h"
#include "flutter/shell/platform/common/windowing.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_view_controller.h"
#include "flutter/shell/platform/windows/host_window.h"
#include "fml/logging.h"
#include "shell/platform/windows/client_wrapper/include/flutter/flutter_view.h"
#include "shell/platform/windows/flutter_windows_view.h"
#include "shell/platform/windows/host_window.h"

namespace flutter {

WindowManager::WindowManager(FlutterWindowsEngine* engine) : engine_(engine) {}

void WindowManager::Initialize(const WindowingInitRequest* request) {
  on_message_ = request->on_message;
  isolate_ = Isolate::Current();
}

bool WindowManager::HasTopLevelWindows() const {
  return !active_windows_.empty();
}

FlutterViewId WindowManager::CreateRegularWindow(
    const WindowCreationRequest* request) {
  auto window =
      HostWindow::CreateRegularWindow(this, engine_, request->content_size);
  if (!window || !window->GetWindowHandle()) {
    FML_LOG(ERROR) << "Failed to create host window";
    return -1;
  }
  FlutterViewId const view_id = window->view_controller_->view()->view_id();
  active_windows_[window->GetWindowHandle()] = std::move(window);
  return view_id;
}

void WindowManager::OnEngineShutdown() {
  // Don't send any more messages to isolate.
  on_message_ = nullptr;
  std::vector<HWND> active_handles;
  active_handles.reserve(active_windows_.size());
  for (auto& [hwnd, window] : active_windows_) {
    active_handles.push_back(hwnd);
  }
  for (auto hwnd : active_handles) {
    // This will destroy the window, which will in turn remove the
    // HostWindow from map when handling WM_NCDESTROY inside
    // HandleMessage.
    DestroyWindow(hwnd);
  }
}

std::optional<LRESULT> WindowManager::HandleMessage(HWND hwnd,
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

}  // namespace flutter

void InternalFlutterWindows_WindowManager_Initialize(
    int64_t engine_id,
    const flutter::WindowingInitRequest* request) {
  flutter::FlutterWindowsEngine* engine =
      flutter::FlutterWindowsEngine::GetEngineForId(engine_id);
  engine->window_manager()->Initialize(request);
}

bool InternalFlutterWindows_WindowManager_HasTopLevelWindows(
    int64_t engine_id) {
  flutter::FlutterWindowsEngine* engine =
      flutter::FlutterWindowsEngine::GetEngineForId(engine_id);
  return engine->window_manager()->HasTopLevelWindows();
}

FlutterViewId InternalFlutterWindows_WindowManager_CreateRegularWindow(
    int64_t engine_id,
    const flutter::WindowCreationRequest* request) {
  flutter::FlutterWindowsEngine* engine =
      flutter::FlutterWindowsEngine::GetEngineForId(engine_id);
  return engine->window_manager()->CreateRegularWindow(request);
}

HWND InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
    int64_t engine_id,
    FlutterViewId view_id) {
  flutter::FlutterWindowsEngine* engine =
      flutter::FlutterWindowsEngine::GetEngineForId(engine_id);
  flutter::FlutterWindowsView* view = engine->view(view_id);
  if (view == nullptr) {
    return nullptr;
  } else {
    return GetAncestor(view->GetWindowHandle(), GA_ROOT);
  }
}

FlutterWindowSize InternalFlutterWindows_WindowManager_GetWindowContentSize(
    HWND hwnd) {
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

void InternalFlutterWindows_WindowManager_SetWindowContentSize(
    HWND hwnd,
    const flutter::WindowSizing* size) {
  flutter::HostWindow* window = flutter::HostWindow::GetThisFromHandle(hwnd);
  if (window) {
    window->SetContentSize(*size);
  }
}
