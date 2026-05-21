// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/host_window_regular.h"

#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_view_controller.h"

namespace flutter {

namespace {

// Returns the Win32 window style for a regular window.
//
// If |resizable| is false, the resize border (WS_THICKFRAME) and maximize
// button (WS_MAXIMIZEBOX) are omitted.
DWORD GetWindowStyleForRegular(bool resizable) {
  DWORD style = WS_OVERLAPPEDWINDOW;
  if (!resizable) {
    style &= ~(WS_THICKFRAME | WS_MAXIMIZEBOX);
  }
  return style;
}

}  // namespace

HostWindowRegular::HostWindowRegular(WindowManager* window_manager,
                                     FlutterWindowsEngine* engine,
                                     const WindowSizeRequest& preferred_size,
                                     const BoxConstraints& constraints,
                                     LPCWSTR title,
                                     bool sized_to_content,
                                     bool resizable)
    : HostWindow(window_manager, engine),
      resizable_(resizable),
      view_alive_(std::make_shared<int>(0)) {
  FML_CHECK(sized_to_content || preferred_size.has_preferred_view_size);
  DWORD const window_style = GetWindowStyleForRegular(resizable);
  InitializeFlutterView(HostWindowInitializationParams{
      .archetype = WindowArchetype::kRegular,
      .window_style = window_style,
      .extended_window_style = 0,
      .box_constraints = constraints,
      .initial_window_rect =
          GetInitialRect(engine, preferred_size, constraints, sized_to_content),
      .title = title,
      .owner_window = std::optional<HWND>(),
      .sizing_delegate = sized_to_content ? this : nullptr,
      .is_sized_to_content = sized_to_content,
  });
}

void HostWindowRegular::DidUpdateViewSize(int32_t width, int32_t height) {
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

WindowRect HostWindowRegular::GetWorkArea() const {
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
Rect HostWindowRegular::GetInitialRect(FlutterWindowsEngine* engine,
                                       const WindowSizeRequest& preferred_size,
                                       const BoxConstraints& constraints,
                                       bool sized_to_content) {
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
          constraints.smallest(), constraints.biggest(), WS_OVERLAPPEDWINDOW, 0,
          nullptr);
  return {{CW_USEDEFAULT, CW_USEDEFAULT},
          window_size ? *window_size : Size{CW_USEDEFAULT, CW_USEDEFAULT}};
}

}  // namespace flutter
