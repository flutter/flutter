// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/host_window_dialog.h"

#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_view_controller.h"
#include "flutter/shell/platform/windows/window_proc_delegate_manager.h"

namespace flutter {

// static
DWORD HostWindowDialog::GetWindowStyleForDialog(
    std::optional<HWND> const& owner_window,
    bool resizable) {
  DWORD window_style = WS_OVERLAPPED | WS_CAPTION;
  if (resizable) {
    window_style |= WS_THICKFRAME;
  }
  if (!owner_window) {
    // If the dialog has no owner, add a minimize box and a system menu.
    window_style |= WS_MINIMIZEBOX | WS_SYSMENU;
  }
  return window_style;
}

// static
DWORD HostWindowDialog::GetExtendedWindowStyleForDialog(
    std::optional<HWND> const& owner_window) {
  DWORD extended_window_style = WS_EX_DLGMODALFRAME;
  if (owner_window) {
    // If the owner window has WS_EX_TOOLWINDOW style, apply the same
    // style to the dialog.
    if (GetWindowLongPtr(*owner_window, GWL_EXSTYLE) & WS_EX_TOOLWINDOW) {
      extended_window_style |= WS_EX_TOOLWINDOW;
    }
  }
  return extended_window_style;
}

HostWindowDialog::HostWindowDialog(WindowManager* window_manager,
                                   FlutterWindowsEngine* engine,
                                   const WindowSizeRequest& preferred_size,
                                   const BoxConstraints& constraints,
                                   LPCWSTR title,
                                   std::optional<HWND> const& owner_window,
                                   bool sized_to_content,
                                   bool resizable)
    : HostWindow(window_manager, engine),
      resizable_(resizable),
      view_alive_(std::make_shared<int>(0)) {
  FML_CHECK(sized_to_content || preferred_size.has_preferred_view_size);
  InitializeFlutterView(HostWindowInitializationParams{
      .archetype = WindowArchetype::kDialog,
      .window_style = GetWindowStyleForDialog(owner_window, resizable),
      .extended_window_style = GetExtendedWindowStyleForDialog(owner_window),
      .box_constraints = constraints,
      .initial_window_rect =
          GetInitialRect(engine, preferred_size, constraints, owner_window,
                         sized_to_content, resizable),
      .title = title,
      .owner_window = owner_window,
      .sizing_delegate = sized_to_content ? this : nullptr,
      .is_sized_to_content = sized_to_content,
  });

  auto hwnd = window_handle_;
  if (owner_window) {
    if (HMENU hMenu = GetSystemMenu(hwnd, FALSE)) {
      EnableMenuItem(hMenu, SC_CLOSE, MF_BYCOMMAND | MF_GRAYED);
    }
  }

  if (owner_window) {
    UpdateModalState();
  }
}

void HostWindowDialog::DidUpdateViewSize(int32_t width, int32_t height) {
  // This is called from the raster thread.
  std::weak_ptr<int> weak_view_alive = view_alive_;
  engine_->task_runner()->PostTask([this, width, height, weak_view_alive]() {
    auto const view_alive = weak_view_alive.lock();
    if (!view_alive) {
      return;
    }
    if (width_ == width && height_ == height) {
      return;
    }
    if (is_being_destroyed_) {
      return;
    }
    width_ = width;
    height_ = height;

    // Convert physical pixels to logical pixels.
    UINT const dpi = GetDpiForWindow(window_handle_);
    double const scale = static_cast<double>(dpi) / 96.0;
    WindowSizeRequest const size{
        .has_preferred_view_size = true,
        .preferred_view_width = width / scale,
        .preferred_view_height = height / scale,
    };
    SetContentSize(size);

    if (resizable_) {
      // For resizable windows, stop tracking content size after the initial
      // frame so subsequent user-initiated resizes are forwarded to Flutter.
      view_controller_->view()->SetSizedToContent(false);
    }
  });
}

WindowRect HostWindowDialog::GetWorkArea() const {
  constexpr int32_t kDefaultWorkAreaSize = 10000;
  WindowRect work_area = {0, 0, kDefaultWorkAreaSize, kDefaultWorkAreaSize};
  HMONITOR const monitor =
      MonitorFromWindow(window_handle_, MONITOR_DEFAULTTONEAREST);
  if (monitor) {
    MONITORINFO monitor_info = {};
    monitor_info.cbSize = sizeof(monitor_info);
    if (GetMonitorInfo(monitor, &monitor_info)) {
      work_area.left = monitor_info.rcWork.left;
      work_area.top = monitor_info.rcWork.top;
      work_area.width = monitor_info.rcWork.right - monitor_info.rcWork.left;
      work_area.height = monitor_info.rcWork.bottom - monitor_info.rcWork.top;
    }
  }
  return work_area;
}

// static
Rect HostWindowDialog::GetInitialRect(FlutterWindowsEngine* engine,
                                      const WindowSizeRequest& preferred_size,
                                      const BoxConstraints& constraints,
                                      std::optional<HWND> const& owner_window,
                                      bool sized_to_content,
                                      bool resizable) {
  auto const window_style = GetWindowStyleForDialog(owner_window, resizable);
  auto const extended_window_style =
      GetExtendedWindowStyleForDialog(owner_window);

  double client_width;
  double client_height;
  if (sized_to_content) {
    // Use the minimum constraint as the initial window size. The window will
    // be resized to match the rendered content after the first frame.
    client_width = std::max(1.0, constraints.smallest().width());
    client_height = std::max(1.0, constraints.smallest().height());
  } else {
    client_width = preferred_size.preferred_view_width;
    client_height = preferred_size.preferred_view_height;
  }

  std::optional<Size> const window_size =
      HostWindow::GetWindowSizeForClientSize(
          *engine->windows_proc_table(), Size(client_width, client_height),
          constraints.smallest(), constraints.biggest(), window_style,
          extended_window_style, owner_window);

  Point window_origin = {CW_USEDEFAULT, CW_USEDEFAULT};
  if (!sized_to_content && owner_window && window_size.has_value()) {
    // Center dialog in the owner's frame.
    RECT frame;
    DwmGetWindowAttribute(*owner_window, DWMWA_EXTENDED_FRAME_BOUNDS, &frame,
                          sizeof(frame));
    window_origin = {(frame.left + frame.right - window_size->width()) * 0.5,
                     (frame.top + frame.bottom - window_size->height()) * 0.5};
  }

  return {window_origin,
          window_size ? *window_size : Size{CW_USEDEFAULT, CW_USEDEFAULT}};
}

LRESULT HostWindowDialog::HandleMessage(HWND hwnd,
                                        UINT message,
                                        WPARAM wparam,
                                        LPARAM lparam) {
  switch (message) {
    case WM_DESTROY:
      is_being_destroyed_ = true;
      if (HostWindow* const owner_window = GetOwnerWindow()) {
        UpdateModalState();
        FocusRootViewOf(owner_window);
      }
      break;

    case WM_ACTIVATE:
      // Forward the message to Dart before handling it on the C++ side.
      // This ensures that Dart-side handlers (e.g. popup dismiss logic)
      // can observe activation changes caused by dialog windows.
      if (auto const result =
              engine_->window_proc_delegate_manager()->OnTopLevelWindowProc(
                  window_handle_, message, wparam, lparam)) {
        return *result;
      }

      if (LOWORD(wparam) != WA_INACTIVE) {
        // Prevent disabled window from being activated using the task
        // switcher.
        if (!IsWindowEnabled(hwnd)) {
          // Redirect focus and activation to the first enabled descendant.
          if (HostWindow* enabled_descendant = FindFirstEnabledDescendant()) {
            SetActiveWindow(enabled_descendant->GetWindowHandle());
            FocusRootViewOf(this);
          }
          return 0;
        }
        FocusRootViewOf(this);
      }
      return 0;
  }

  return HostWindow::HandleMessage(hwnd, message, wparam, lparam);
}

void HostWindowDialog::UpdateModalState() {
  // Find the root window of the window hierarchy and process
  // modal state update for the entire branch.
  HostWindow* root = this;
  while (HostWindow* const owner = root->GetOwnerWindow()) {
    root = owner;
  }
  root->UpdateModalStateLayer();
}

void HostWindowDialog::SetFullscreen(
    bool fullscreen,
    std::optional<FlutterEngineDisplayId> display_id) {}

bool HostWindowDialog::GetFullscreen() const {
  return false;
}

}  // namespace flutter
