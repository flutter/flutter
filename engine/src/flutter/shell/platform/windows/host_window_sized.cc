// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/host_window_sized.h"
#include "flutter/shell/platform/windows/dpi_utils.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_view_controller.h"

namespace flutter {

HostWindowSized::HostWindowSized(WindowManager* window_manager,
                                 FlutterWindowsEngine* engine,
                                 bool resizable)
    : HostWindow(window_manager, engine),
      resizable_(resizable),
      view_alive_(std::make_shared<int>(0)) {}

HostWindowSized::~HostWindowSized() {
  // Destroy the view (and therefore the raster thread's access to this object
  // as a sizing delegate) while this HostWindowSized is still fully alive.
  //
  // When sized to content, this object is the view's
  // FlutterWindowsViewSizingDelegate. The view is owned by |view_controller_|,
  // a member of the HostWindow base class, which would otherwise be destroyed
  // *after* this object's FlutterWindowsViewSizingDelegate subobject. Resetting
  // it here triggers FlutterWindowsEngine::RemoveView, which guarantees the
  // raster thread no longer presents to (or sizes) this view, before the
  // sizing delegate is torn down. Without this, the raster thread's
  // sized-to-content path can call into a destroyed sizing delegate and crash.
  view_controller_.reset();
}

void HostWindowSized::DidUpdateViewSize(int32_t width, int32_t height) {
  // This is called from the raster thread.
  std::weak_ptr<int> weak_view_alive = view_alive_;
  engine_->task_runner()->PostTask([this, width, height, weak_view_alive]() {
    auto const view_alive = weak_view_alive.lock();
    if (!view_alive) {
      return;
    }
    if (physical_width_ == width && physical_width_ == height) {
      return;
    }
    if (is_being_destroyed_) {
      return;
    }
    physical_width_ = width;
    physical_width_ = height;

    WINDOWINFO window_info = {.cbSize = sizeof(WINDOWINFO)};
    GetWindowInfo(window_handle_, &window_info);

    // Convert physical pixels to logical pixels.
    UINT const dpi = GetDpiForHWND(window_handle_);
    double const scale = static_cast<double>(dpi > 0 ? dpi : 96) / 96.0;
    std::optional<Size> const window_size = GetWindowSizeForClientSize(
        *engine_->windows_proc_table(), Size(width / scale, height / scale),
        box_constraints_.smallest(), box_constraints_.biggest(),
        window_info.dwStyle, window_info.dwExStyle, nullptr);

    if (!window_size) {
      return;
    }

    SetWindowPos(window_handle_, NULL, 0, 0, window_size->width(),
                 window_size->height(),
                 SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);

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
