// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/host_window_satellite.h"

#include <dwmapi.h>

#include <algorithm>
#include <cstdlib>
#include <memory>

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_view_controller.h"
#include "flutter/shell/platform/windows/window_proc_delegate_manager.h"

namespace flutter {

namespace {
// Fallback work area used when the monitor for a window cannot be determined.
constexpr int32_t kDefaultWorkAreaSize = 10000;
}  // namespace

DWORD HostWindowSatellite::GetWindowStyleForSatellite(bool resizable) {
  // Satellites are decorated and activatable like a regular window, but they
  // are never minimizable: a satellite has no meaningful existence apart from
  // the parent it tracks.
  DWORD window_style = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU;
  if (resizable) {
    window_style |= WS_THICKFRAME | WS_MAXIMIZEBOX;
  }
  return window_style;
}

HostWindowSatellite::HostWindowSatellite(
    WindowManager* window_manager,
    FlutterWindowsEngine* engine,
    const WindowSizeRequest& preferred_size,
    const BoxConstraints& constraints,
    GetWindowPositionCallback get_position_callback,
    HWND parent,
    LPCWSTR title,
    bool sized_to_content,
    bool resizable)
    : HostWindowSized(window_manager, engine, resizable),
      get_position_callback_(get_position_callback),
      parent_(parent),
      isolate_(Isolate::Current()) {
  FML_CHECK(sized_to_content || preferred_size.has_preferred_view_size);

  DWORD const window_style = GetWindowStyleForSatellite(resizable);

  double client_width;
  double client_height;
  if (sized_to_content) {
    // Use the minimum constraint as the initial size so the view can be
    // created with valid metrics. The window is resized to fit the rendered
    // content after the first frame.
    client_width = std::max(1.0, constraints.smallest().width());
    client_height = std::max(1.0, constraints.smallest().height());
  } else {
    client_width = preferred_size.preferred_view_width;
    client_height = preferred_size.preferred_view_height;
  }

  std::optional<Size> const window_size = GetWindowSizeForClientSize(
      *engine->windows_proc_table(), Size(client_width, client_height),
      constraints.smallest(), constraints.biggest(), window_style,
      /*extended_window_style=*/0, parent);

  Size const initial_size =
      window_size ? *window_size : Size{CW_USEDEFAULT, CW_USEDEFAULT};
  Point window_origin = {CW_USEDEFAULT, CW_USEDEFAULT};

  // When the satellite has a fixed size, its final frame size is already known,
  // so the initial placement can be resolved up front and the window created
  // directly at its target position. Sized-to-content satellites have to wait
  // for the first frame before their size, and therefore their placement, is
  // known; those are positioned from |ApplyContentSize|.
  if (!sized_to_content && window_size) {
    if (std::optional<WindowRect> const rect = ComputePosition(
            get_position_callback, isolate_, parent,
            WindowSize{static_cast<int32_t>(window_size->width()),
                       static_cast<int32_t>(window_size->height())})) {
      window_origin = {static_cast<double>(rect->left),
                       static_cast<double>(rect->top)};
      initial_position_applied_ = true;
    }
  }

  InitializeFlutterView(HostWindowInitializationParams{
      .archetype = WindowArchetype::kSatellite,
      .window_style = window_style,
      .extended_window_style = 0,
      .box_constraints = constraints,
      .initial_window_rect = {window_origin, initial_size},
      .title = title ? title : L"",
      .owner_window = parent,
      .sizing_delegate = sized_to_content ? AsSizingDelegate() : nullptr,
      .is_sized_to_content = sized_to_content,
  });

  // Owned windows are destroyed alongside their owner and always stay above it
  // in the z-order, which is the relationship a satellite needs.
  SetWindowLongPtr(window_handle_, GWLP_HWNDPARENT,
                   reinterpret_cast<LONG_PTR>(parent_));

  // Record where the parent is now so subsequent moves can be applied as
  // deltas.
  RECT parent_rect;
  if (GetWindowRect(parent_, &parent_rect)) {
    last_parent_pos_ = {parent_rect.left, parent_rect.top};
  }
}

HostWindowSatellite::~HostWindowSatellite() {
  // Reset the view while this most-derived object is still fully alive, to stop
  // the raster thread from sizing it (via the overridden ApplyContentSize /
  // GetWorkArea) before any subobject is torn down. See the destructor comment
  // in host_window_sized.h for the rationale.
  view_controller_.reset();
}

WindowRect HostWindowSatellite::GetWorkAreaForWindow(HWND hwnd) {
  WindowRect work_area = {0, 0, kDefaultWorkAreaSize, kDefaultWorkAreaSize};
  HMONITOR const monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
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

WindowRect HostWindowSatellite::GetWorkArea() const {
  return GetWorkAreaForWindow(parent_);
}

std::optional<WindowRect> HostWindowSatellite::ComputePosition(
    GetWindowPositionCallback get_position_callback,
    const Isolate& isolate,
    HWND parent,
    const WindowSize& window_size) {
  if (!get_position_callback) {
    return std::nullopt;
  }

  RECT parent_client_rect;
  GetClientRect(parent, &parent_client_rect);

  // Convert top-left and bottom-right points to screen coordinates.
  POINT parent_top_left = {parent_client_rect.left, parent_client_rect.top};
  POINT parent_bottom_right = {parent_client_rect.right,
                               parent_client_rect.bottom};
  ClientToScreen(parent, &parent_top_left);
  ClientToScreen(parent, &parent_bottom_right);

  IsolateScope scope(isolate);

  // Frees the memory allocated by the positioner callback. Even if the callback
  // throws an exception, the memory is freed when |rect| goes out of scope.
  std::unique_ptr<WindowRect, decltype(&free)> rect(
      get_position_callback(
          window_size,
          WindowRect{parent_top_left.x, parent_top_left.y,
                     parent_bottom_right.x - parent_top_left.x,
                     parent_bottom_right.y - parent_top_left.y},
          GetWorkAreaForWindow(parent)),
      free);
  if (!rect) {
    return std::nullopt;
  }
  return *rect;
}

void HostWindowSatellite::ApplyInitialPosition() {
  if (initial_position_applied_) {
    return;
  }

  RECT window_rect;
  if (!GetWindowRect(window_handle_, &window_rect)) {
    return;
  }
  WindowSize const window_size = {window_rect.right - window_rect.left,
                                  window_rect.bottom - window_rect.top};

  std::optional<WindowRect> const rect =
      ComputePosition(get_position_callback_, isolate_, parent_, window_size);
  if (!rect) {
    return;
  }

  SetWindowPos(window_handle_, nullptr, rect->left, rect->top, rect->width,
               rect->height, SWP_NOACTIVATE | SWP_NOOWNERZORDER | SWP_NOZORDER);

  // |HostWindow::InitializeFlutterView| aligns a window's origin with the
  // top-left corner of its frame rather than its window rectangle, which
  // includes the invisible drop-shadow border. Reapply that adjustment here so
  // that both placement paths interpret the positioner's result identically.
  RECT frame_rect;
  RECT positioned_rect;
  if (SUCCEEDED(DwmGetWindowAttribute(window_handle_,
                                      DWMWA_EXTENDED_FRAME_BOUNDS, &frame_rect,
                                      sizeof(frame_rect))) &&
      GetWindowRect(window_handle_, &positioned_rect)) {
    LONG const left_dropshadow_width = frame_rect.left - positioned_rect.left;
    LONG const top_dropshadow_height = positioned_rect.top - frame_rect.top;
    if (left_dropshadow_width != 0 || top_dropshadow_height != 0) {
      SetWindowPos(
          window_handle_, nullptr, positioned_rect.left - left_dropshadow_width,
          positioned_rect.top - top_dropshadow_height, 0, 0,
          SWP_NOSIZE | SWP_NOACTIVATE | SWP_NOOWNERZORDER | SWP_NOZORDER);
    }
  }

  initial_position_applied_ = true;

  // The positioner constrained the dimensions more than the current size, so
  // let the framework know about the size it actually got.
  if (rect->width < window_size.width || rect->height < window_size.height) {
    auto metrics_event = view_controller_->view()->CreateWindowMetricsEvent();
    view_controller_->engine()->SendWindowMetricsEvent(metrics_event);
  }
}

void HostWindowSatellite::ApplyContentSize(int32_t physical_width,
                                           int32_t physical_height) {
  // Resize the window to fit its content. For resizable satellites this also
  // stops content-size tracking after the first frame, so the user's subsequent
  // manual resizes are forwarded to Flutter instead of being overridden.
  HostWindowSized::ApplyContentSize(physical_width, physical_height);

  // Run the positioner only for the initial placement. Afterwards the satellite
  // is positioned solely by following its parent.
  ApplyInitialPosition();
}

void HostWindowSatellite::OnParentMoved() {
  RECT parent_rect;
  if (!GetWindowRect(parent_, &parent_rect)) {
    return;
  }

  LONG const dx = parent_rect.left - last_parent_pos_.x;
  LONG const dy = parent_rect.top - last_parent_pos_.y;
  last_parent_pos_ = {parent_rect.left, parent_rect.top};

  if (dx == 0 && dy == 0) {
    return;
  }

  RECT satellite_rect;
  if (!GetWindowRect(window_handle_, &satellite_rect)) {
    return;
  }
  SetWindowPos(window_handle_, nullptr, satellite_rect.left + dx,
               satellite_rect.top + dy, 0, 0,
               SWP_NOSIZE | SWP_NOACTIVATE | SWP_NOZORDER);
}

void HostWindowSatellite::SetSatelliteParent(HWND new_parent) {
  if (new_parent == parent_ || new_parent == nullptr) {
    return;
  }

  // Reject a reparent that would make this satellite its own ancestor. Parent
  // movement propagates down the anchor chain, so a cycle would recurse until
  // the stack is exhausted.
  for (HWND ancestor = new_parent; ancestor != nullptr;
       ancestor = GetWindow(ancestor, GW_OWNER)) {
    if (ancestor == window_handle_) {
      FML_LOG(ERROR) << "Refusing to anchor a satellite window to itself or to "
                        "one of its own satellites.";
      return;
    }
  }

  parent_ = new_parent;
  SetWindowLongPtr(window_handle_, GWLP_HWNDPARENT,
                   reinterpret_cast<LONG_PTR>(new_parent));

  // Re-anchor the movement tracking to the new parent's current position so
  // that reparenting does not move the satellite.
  RECT parent_rect;
  if (GetWindowRect(new_parent, &parent_rect)) {
    last_parent_pos_ = {parent_rect.left, parent_rect.top};
  }
}

LRESULT HostWindowSatellite::HandleMessage(HWND hwnd,
                                           UINT message,
                                           WPARAM wparam,
                                           LPARAM lparam) {
  switch (message) {
    case WM_SYSCOMMAND:
      // A satellite has no meaningful existence apart from its parent, so it
      // cannot be minimized on its own.
      if ((wparam & 0xFFF0) == SC_MINIMIZE) {
        return 0;
      }
      break;

    case WM_ACTIVATE:
      // Forward the message to Dart before handling it on the C++ side, so
      // that Dart-side handlers (e.g. popup dismiss logic) can observe
      // activation changes caused by satellite windows.
      if (auto const result =
              engine_->window_proc_delegate_manager()->OnTopLevelWindowProc(
                  window_handle_, message, wparam, lparam)) {
        return *result;
      }

      HandleWindowActivation(hwnd, wparam);
      return 0;
  }

  return HostWindow::HandleMessage(hwnd, message, wparam, lparam);
}

}  // namespace flutter
