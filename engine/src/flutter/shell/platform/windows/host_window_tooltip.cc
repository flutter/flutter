// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/host_window_tooltip.h"
#include <cstdio>
#include "flutter/shell/platform/windows/flutter_windows_view_controller.h"
#include "shell/platform/windows/window_manager.h"

namespace flutter {
HostWindowTooltip::HostWindowTooltip(
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
  // with valid metrics.
  auto const initial_width =
      static_cast<double>(constraints.smallest().width());
  auto const initial_height =
      static_cast<double>(constraints.smallest().height());

  InitializeFlutterView(HostWindowInitializationParams{
      .archetype = WindowArchetype::kTooltip,
      .window_style = WS_POPUP,
      .extended_window_style = WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW,
      .box_constraints = constraints,
      .initial_window_rect = {{0, 0}, {initial_width, initial_height}},
      .title = L"",
      .owner_window = parent,
      .nCmdShow = SW_SHOWNOACTIVATE,
      .sizing_delegate = AsSizingDelegate(),
      .is_sized_to_content = true});
  SetWindowLongPtr(window_handle_, GWLP_HWNDPARENT,
                   reinterpret_cast<LONG_PTR>(parent_));
}

HostWindowTooltip::~HostWindowTooltip() {
  // Reset the view while this most-derived object is still fully alive, to stop
  // the raster thread from sizing it (via the overridden ApplyContentSize /
  // GetWorkArea) before any subobject is torn down. See the destructor comment
  // in host_window_sized.h for the rationale.
  view_controller_.reset();
}

void HostWindowTooltip::ApplyContentSize(int32_t physical_width,
                                         int32_t physical_height) {
  UpdatePosition();
}

WindowRect HostWindowTooltip::GetWorkArea() const {
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

void HostWindowTooltip::UpdatePosition() {
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
  auto rect = get_position_callback_(
      WindowSize{physical_width_, physical_height_},
      WindowRect{parent_top_left.x, parent_top_left.y,
                 parent_bottom_right.x - parent_top_left.x,
                 parent_bottom_right.y - parent_top_left.y},
      work_area);
  SetWindowPos(window_handle_, nullptr, rect->left, rect->top, rect->width,
               rect->height, SWP_NOACTIVATE | SWP_NOOWNERZORDER);
  free(rect);

  // The positioner constrained the dimensions more than current size, apply
  // positioner constraints.
  if (rect->width < physical_width_ || rect->height < physical_height_) {
    auto metrics_event = view_controller_->view()->CreateWindowMetricsEvent();
    view_controller_->engine()->SendWindowMetricsEvent(metrics_event);
  }
}

LRESULT HostWindowTooltip::HandleMessage(HWND hwnd,
                                         UINT message,
                                         WPARAM wparam,
                                         LPARAM lparam) {
  switch (message) {
    case WM_MOUSEACTIVATE:
      // Prevent activation when clicked
      return MA_NOACTIVATE;

    case WM_NCACTIVATE:
      // Return TRUE to prevent visual activation changes
      return TRUE;

    case WM_ACTIVATE:
      // Immediately deactivate if somehow activated
      if (LOWORD(wparam) != WA_INACTIVE) {
        HWND hFocus = GetFocus();
        SetFocus(nullptr);
      }
      break;
  }

  return HostWindow::HandleMessage(hwnd, message, wparam, lparam);
}

}  // namespace flutter
