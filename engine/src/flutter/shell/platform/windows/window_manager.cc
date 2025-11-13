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

FlutterViewId WindowManager::CreateRegularWindow(
    const RegularWindowCreationRequest* request) {
  auto window = HostWindow::CreateRegularWindow(
      this, engine_, request->preferred_size, request->preferred_constraints,
      request->title);
  if (!window || !window->GetWindowHandle()) {
    FML_LOG(ERROR) << "Failed to create host window";
    return -1;
  }
  FlutterViewId const view_id = window->view_controller_->view()->view_id();
  active_windows_[window->GetWindowHandle()] = std::move(window);
  return view_id;
}

FlutterViewId WindowManager::CreateDialogWindow(
    const DialogWindowCreationRequest* request) {
  auto window = HostWindow::CreateDialogWindow(
      this, engine_, request->preferred_size, request->preferred_constraints,
      request->title, request->parent_or_null);
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

FlutterViewId InternalFlutterWindows_WindowManager_CreateRegularWindow(
    int64_t engine_id,
    const flutter::RegularWindowCreationRequest* request) {
  flutter::FlutterWindowsEngine* engine =
      flutter::FlutterWindowsEngine::GetEngineForId(engine_id);
  return engine->window_manager()->CreateRegularWindow(request);
}

FLUTTER_EXPORT
FlutterViewId InternalFlutterWindows_WindowManager_CreateDialogWindow(
    int64_t engine_id,
    const flutter::DialogWindowCreationRequest* request) {
  flutter::FlutterWindowsEngine* engine =
      flutter::FlutterWindowsEngine::GetEngineForId(engine_id);
  return engine->window_manager()->CreateDialogWindow(request);
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

flutter::ActualWindowSize
InternalFlutterWindows_WindowManager_GetWindowContentSize(HWND hwnd) {
  return flutter::HostWindow::GetWindowContentSize(hwnd);
}

void InternalFlutterWindows_WindowManager_SetWindowSize(
    HWND hwnd,
    const flutter::WindowSizeRequest* size) {
  flutter::HostWindow* window = flutter::HostWindow::GetThisFromHandle(hwnd);
  if (window) {
    window->SetContentSize(*size);
  }
}

void InternalFlutterWindows_WindowManager_SetWindowConstraints(
    HWND hwnd,
    const flutter::WindowConstraints* constraints) {
  flutter::HostWindow* window = flutter::HostWindow::GetThisFromHandle(hwnd);
  if (window) {
    window->SetConstraints(*constraints);
  }
}

void InternalFlutterWindows_WindowManager_SetFullscreen(
    HWND hwnd,
    const flutter::FullscreenRequest* request) {
  flutter::HostWindow* window = flutter::HostWindow::GetThisFromHandle(hwnd);
  const std::optional<FlutterEngineDisplayId> display_id =
      request->has_display_id
          ? std::optional<FlutterEngineDisplayId>(request->display_id)
          : std::nullopt;
  if (window) {
    window->SetFullscreen(request->fullscreen, display_id);
  }
}

bool InternalFlutterWindows_WindowManager_GetFullscreen(HWND hwnd) {
  flutter::HostWindow* window = flutter::HostWindow::GetThisFromHandle(hwnd);
  if (window) {
    return window->GetFullscreen();
  }

  return false;
}
