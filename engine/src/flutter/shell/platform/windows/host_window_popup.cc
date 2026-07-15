// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/host_window_popup.h"
#include <cstdio>
#include <memory>
#include "flutter/shell/platform/windows/flutter_windows_view_controller.h"
#include "shell/platform/windows/window_manager.h"

namespace flutter {
HostWindowPopup::HostWindowPopup(
    WindowManager* window_manager,
    FlutterWindowsEngine* engine,
    const BoxConstraints& constraints,
    GetWindowPositionCallback get_position_callback,
    HWND parent)
    : HostWindowSized(window_manager, engine, /*resizable=*/false),
      get_position_callback_(get_position_callback),
      parent_(parent),
      isolate_(Isolate::Current()) {
  // Use minimum constraints as initial size to ensure the view can be created
  // with valid metrics. The size will be updated when content is rendered.
  auto const initial_width =
      static_cast<double>(constraints.smallest().width());
  auto const initial_height =
      static_cast<double>(constraints.smallest().height());

  InitializeFlutterView(HostWindowInitializationParams{
      .archetype = WindowArchetype::kPopup,
      .window_style = WS_POPUP,
      .extended_window_style = WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW,
      .box_constraints = constraints,
      .initial_window_rect = {{0, 0}, {initial_width, initial_height}},
      .title = L"",
      .owner_window = parent,
      .nCmdShow = SW_SHOWNOACTIVATE,
      .sizing_delegate = AsSizingDelegate(),
      .is_sized_to_content = true});
}

HostWindowPopup::~HostWindowPopup() {
  // Reset the view while this most-derived object is still fully alive, to stop
  // the raster thread from sizing it (via the overridden ApplyContentSize /
  // GetWorkArea) before any subobject is torn down. See the destructor comment
  // in host_window_sized.h for the rationale.
  view_controller_.reset();
}

void HostWindowPopup::ApplyContentSize(int32_t physical_width,
                                       int32_t physical_height) {
  UpdatePosition();
}

WindowRect HostWindowPopup::GetWorkArea() const {
  constexpr int32_t kDefaultWorkAreaSize = 10000;
  WindowRect work_area = {0, 0, kDefaultWorkAreaSize, kDefaultWorkAreaSize};
  HMONITOR monitor = MonitorFromWindow(parent_, MONITOR_DEFAULTTONEAREST);
  if (monitor) {
    MONITORINFO monitor_info = {0};
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

void HostWindowPopup::UpdatePosition() {
  RECT parent_client_rect;
  GetClientRect(parent_, &parent_client_rect);

  // Convert top-left and bottom-right points to screen coordinates.
  POINT parent_top_left = {parent_client_rect.left, parent_client_rect.top};
  POINT parent_bottom_right = {parent_client_rect.right,
                               parent_client_rect.bottom};

  ClientToScreen(parent_, &parent_top_left);
  ClientToScreen(parent_, &parent_bottom_right);

  // Get monitor from HWND and usable work area.
  HMONITOR monitor = MonitorFromWindow(parent_, MONITOR_DEFAULTTONEAREST);
  WindowRect work_area = GetWorkArea();

  IsolateScope scope(isolate_);

  // Frees the memory allocated by the positioner callback.
  // Even if the callback throws an exception, the memory will be freed when
  // rect goes out of scope.
  std::unique_ptr<WindowRect, decltype(&free)> rect(
      get_position_callback_(
          WindowSize{physical_width_, physical_height_},
          WindowRect{parent_top_left.x, parent_top_left.y,
                     parent_bottom_right.x - parent_top_left.x,
                     parent_bottom_right.y - parent_top_left.y},
          work_area),
      free);
  SetWindowPos(window_handle_, HWND_TOP, rect->left, rect->top, rect->width,
               rect->height, SWP_NOACTIVATE | SWP_NOOWNERZORDER);

  // The positioner constrained the dimensions more than current size, apply
  // positioner constraints.
  if (rect->width < physical_width_ || rect->height < physical_height_) {
    auto metrics_event = view_controller_->view()->CreateWindowMetricsEvent();
    view_controller_->engine()->SendWindowMetricsEvent(metrics_event);
  }
}

}  // namespace flutter
