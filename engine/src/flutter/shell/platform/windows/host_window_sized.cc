// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/host_window_sized.h"

#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_view_controller.h"

namespace flutter {

HostWindowSized::HostWindowSized(WindowManager* window_manager,
                                 FlutterWindowsEngine* engine,
                                 bool resizable)
    : HostWindow(window_manager, engine),
      resizable_(resizable),
      view_alive_(std::make_shared<int>(0)) {}

void HostWindowSized::DidUpdateViewSize(int32_t width, int32_t height) {
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

WindowRect HostWindowSized::GetWorkArea() const {
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

}  // namespace flutter
