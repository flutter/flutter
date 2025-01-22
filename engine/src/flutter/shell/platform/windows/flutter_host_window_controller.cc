// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_host_window_controller.h"

#include <dwmapi.h>

#include "flutter/shell/platform/common/windowing.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"

namespace flutter {

namespace {

// Names of the messages sent by the controller in response to window events.
constexpr char kOnWindowChangedMethod[] = "onWindowChanged";
constexpr char kOnWindowCreatedMethod[] = "onWindowCreated";
constexpr char kOnWindowDestroyedMethod[] = "onWindowDestroyed";

// Keys used in the onWindow* messages sent through the channel.
constexpr char kParentViewIdKey[] = "parentViewId";
constexpr char kRelativePositionKey[] = "relativePosition";
constexpr char kSizeKey[] = "size";
constexpr char kStateKey[] = "state";
constexpr char kViewIdKey[] = "viewId";

}  // namespace

FlutterHostWindowController::FlutterHostWindowController(
    FlutterWindowsEngine* engine)
    : engine_(engine) {}

FlutterHostWindowController::~FlutterHostWindowController() {
  DestroyAllWindows();
}

std::optional<WindowMetadata> FlutterHostWindowController::CreateHostWindow(
    WindowCreationSettings const& settings) {
  auto window = std::make_unique<FlutterHostWindow>(this, settings);
  if (!window->GetWindowHandle()) {
    return std::nullopt;
  }

  // Assume first window is the main window.
  if (windows_.empty()) {
    window->SetQuitOnClose(true);
  }

  FlutterViewId const view_id = window->GetFlutterViewId();
  WindowState const state = window->GetState();
  windows_[view_id] = std::move(window);

  WindowMetadata const result = {.view_id = view_id,
                                 .archetype = settings.archetype,
                                 .size = GetWindowSize(view_id),
                                 .parent_id = std::nullopt,
                                 .state = state};

  return result;
}

bool FlutterHostWindowController::DestroyHostWindow(FlutterViewId view_id) {
  if (auto const it = windows_.find(view_id); it != windows_.end()) {
    FlutterHostWindow* const window = it->second.get();
    HWND const window_handle = window->GetWindowHandle();

    // |window| will be removed from |windows_| when WM_NCDESTROY is handled.
    PostMessage(window->GetWindowHandle(), WM_CLOSE, 0, 0);

    return true;
  }
  return false;
}

FlutterHostWindow* FlutterHostWindowController::GetHostWindow(
    FlutterViewId view_id) const {
  if (auto const it = windows_.find(view_id); it != windows_.end()) {
    return it->second.get();
  }
  return nullptr;
}

LRESULT FlutterHostWindowController::HandleMessage(HWND hwnd,
                                                   UINT message,
                                                   WPARAM wparam,
                                                   LPARAM lparam) {
  switch (message) {
    case WM_NCDESTROY: {
      auto const it = std::find_if(
          windows_.begin(), windows_.end(), [hwnd](auto const& window) {
            return window.second->GetWindowHandle() == hwnd;
          });
      if (it != windows_.end()) {
        FlutterViewId const view_id = it->first;
        bool const quit_on_close = it->second->GetQuitOnClose();

        windows_.erase(it);

        SendOnWindowDestroyed(view_id);

        if (quit_on_close) {
          DestroyAllWindows();
        }
      }
    }
      return 0;
    case WM_SIZE: {
      auto const it = std::find_if(
          windows_.begin(), windows_.end(), [hwnd](auto const& window) {
            return window.second->GetWindowHandle() == hwnd;
          });
      if (it != windows_.end()) {
        auto& [view_id, window] = *it;
        if (window->archetype_ == WindowArchetype::kRegular) {
          window->state_ = (wparam == SIZE_MAXIMIZED) ? WindowState::kMaximized
                           : (wparam == SIZE_MINIMIZED)
                               ? WindowState::kMinimized
                               : WindowState::kRestored;
        }
        SendOnWindowChanged(view_id, GetWindowSize(view_id), std::nullopt);
      }
    } break;
    default:
      break;
  }

  if (FlutterHostWindow* const window =
          FlutterHostWindow::GetThisFromHandle(hwnd)) {
    return window->HandleMessage(hwnd, message, wparam, lparam);
  }
  return DefWindowProc(hwnd, message, wparam, lparam);
}

void FlutterHostWindowController::SetMethodChannel(
    std::shared_ptr<MethodChannel<EncodableValue>> channel) {
  channel_ = std::move(channel);
}

FlutterWindowsEngine* FlutterHostWindowController::engine() const {
  return engine_;
}

void FlutterHostWindowController::DestroyAllWindows() {
  if (!windows_.empty()) {
    // Destroy windows in reverse order of creation.
    for (auto it = std::prev(windows_.end());
         it != std::prev(windows_.begin());) {
      auto const current = it--;
      auto const& [view_id, window] = *current;
      if (window->GetWindowHandle()) {
        DestroyHostWindow(view_id);
      }
    }
  }
}

Size FlutterHostWindowController::GetWindowSize(FlutterViewId view_id) const {
  HWND const hwnd = windows_.at(view_id)->GetWindowHandle();
  RECT frame_rect;
  DwmGetWindowAttribute(hwnd, DWMWA_EXTENDED_FRAME_BOUNDS, &frame_rect,
                        sizeof(frame_rect));

  // Convert to logical coordinates.
  double const dpr = FlutterDesktopGetDpiForHWND(hwnd) /
                     static_cast<double>(USER_DEFAULT_SCREEN_DPI);
  double const width = (frame_rect.right - frame_rect.left) / dpr;
  double const height = (frame_rect.bottom - frame_rect.top) / dpr;
  return {width, height};
}

void FlutterHostWindowController::SendOnWindowChanged(
    FlutterViewId view_id,
    std::optional<Size> size,
    std::optional<Size> relative_position) const {
  if (channel_) {
    EncodableMap map{{EncodableValue(kViewIdKey), EncodableValue(view_id)}};
    if (size) {
      map.insert(
          {EncodableValue(kSizeKey),
           EncodableValue(EncodableList{EncodableValue(size->width()),
                                        EncodableValue(size->height())})});
    }
    if (relative_position) {
      map.insert({EncodableValue(kRelativePositionKey),
                  EncodableValue(EncodableList{
                      EncodableValue(relative_position->width()),
                      EncodableValue(relative_position->height())})});
    }
    channel_->InvokeMethod(kOnWindowChangedMethod,
                           std::make_unique<EncodableValue>(map));
  }
}

void FlutterHostWindowController::SendOnWindowDestroyed(
    FlutterViewId view_id) const {
  if (channel_) {
    channel_->InvokeMethod(
        kOnWindowDestroyedMethod,
        std::make_unique<EncodableValue>(EncodableMap{
            {EncodableValue(kViewIdKey), EncodableValue(view_id)},
        }));
  }
}

}  // namespace flutter
