// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_host_window_controller.h"

#include <dwmapi.h>

#include "flutter/shell/platform/common/windowing.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_view_controller.h"

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
    FML_LOG(ERROR) << "Failed to create host window";
    return std::nullopt;
  }

  // Assume first window is the main window.
  if (windows_.empty()) {
    window->quit_on_close_ = true;
  }

  FlutterViewId const view_id = window->GetFlutterViewId();
  std::optional<WindowState> const state = window->GetState();
  std::optional<Point> relative_position = window->GetRelativePosition();
  windows_[view_id] = std::move(window);

  WindowMetadata result = {.view_id = view_id,
                           .archetype = settings.archetype,
                           .size = GetViewSize(view_id),
                           .parent_id = std::nullopt,
                           .state = std::nullopt};
  if (settings.archetype == WindowArchetype::kRegular) {
    result.state = state;
  }
  if (settings.archetype == WindowArchetype::kPopup) {
    result.parent_id = settings.parent_view_id;
    result.relative_position = relative_position;
  }

  return result;
}

bool FlutterHostWindowController::ModifyHostWindow(
    FlutterViewId view_id,
    WindowModificationSettings const& settings) const {
  FlutterHostWindow* const window = GetHostWindow(view_id);
  if (!window) {
    FML_LOG(ERROR) << "Failed to find window with view ID " << view_id;
    return false;
  }

  std::optional<Size> changed_size;
  Size const size_before = GetViewSize(view_id);

  if (settings.size.has_value()) {
    window->SetClientSize(*settings.size);
  }
  if (settings.title.has_value()) {
    window->SetTitle(*settings.title);
  }
  if (settings.state.has_value()) {
    window->SetState(*settings.state);
  }

  Size const size_after = GetViewSize(view_id);
  if (size_before != size_after) {
    changed_size = size_after;
  }

  if (changed_size) {
    SendOnWindowChanged(view_id, changed_size, std::nullopt);
  }

  return true;
}

bool FlutterHostWindowController::DestroyHostWindow(
    FlutterViewId view_id) const {
  FlutterHostWindow* const window = GetHostWindow(view_id);
  if (!window) {
    FML_LOG(ERROR) << "Failed to find window with view ID " << view_id;
    return false;
  }

  // |window| will be removed from |windows_| when WM_NCDESTROY is handled.
  PostMessage(window->GetWindowHandle(), WM_CLOSE, 0, 0);

  return true;
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
        bool const quit_on_close = it->second->quit_on_close_;

        windows_.erase(it);

        SendOnWindowDestroyed(view_id);

        if (quit_on_close) {
          DestroyAllWindows();
        }
      }
    }
      return 0;
    case WM_ACTIVATE:
      if (wparam != WA_INACTIVE) {
        if (FlutterHostWindow* const window =
                FlutterHostWindow::GetThisFromHandle(hwnd)) {
          if (window->GetArchetype() != WindowArchetype::kPopup) {
            // If a non-popup window is activated, close popups for all windows.
            auto it = windows_.begin();
            while (it != windows_.end()) {
              std::size_t const num_popups_closed =
                  it->second->CloseOwnedPopups();
              if (num_popups_closed > 0) {
                it = windows_.begin();
              } else {
                ++it;
              }
            }
          } else {
            // If a popup window is activated, close its owned popups.
            window->CloseOwnedPopups();
          }
        }
      }
      break;
    case WM_ACTIVATEAPP:
      if (wparam == FALSE) {
        if (FlutterHostWindow* const window =
                FlutterHostWindow::GetThisFromHandle(hwnd)) {
          // Close owned popups if a window belonging to a different application
          // is being activated.
          window->CloseOwnedPopups();
        }
      }
      break;
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
        SendOnWindowChanged(view_id, GetViewSize(view_id), std::nullopt);
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

Size FlutterHostWindowController::GetViewSize(FlutterViewId view_id) const {
  HWND const window_handle = GetHostWindow(view_id)->GetWindowHandle();
  RECT rect;
  GetClientRect(window_handle, &rect);
  double const dpr = FlutterDesktopGetDpiForHWND(window_handle) /
                     static_cast<double>(USER_DEFAULT_SCREEN_DPI);
  double const width = rect.right / dpr;
  double const height = rect.bottom / dpr;
  return {width, height};
}

void FlutterHostWindowController::SendOnWindowChanged(
    FlutterViewId view_id,
    std::optional<Size> size,
    std::optional<Point> relative_position) const {
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
                  EncodableValue(
                      EncodableList{EncodableValue(relative_position->x()),
                                    EncodableValue(relative_position->y())})});
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
