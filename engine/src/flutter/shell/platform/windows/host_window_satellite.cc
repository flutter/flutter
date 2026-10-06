// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/host_window_satellite.h"

#include <cmath>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/windows/dpi_utils.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_view_controller.h"
#include "flutter/shell/platform/windows/window_proc_delegate_manager.h"

namespace flutter {

DWORD HostWindowSatellite::GetWindowStyleForSatellite(bool resizable) {
  // Satellites are decorated and activatable like a regular window, but they
  // are never minimizable.
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

  InitializeFlutterView(HostWindowInitializationParams{
      .archetype = WindowArchetype::kSatellite,
      .window_style = GetWindowStyleForSatellite(resizable),
      .extended_window_style = 0,
      .box_constraints = constraints,
      .initial_window_rect =
          GetInitialRect(engine, preferred_size, constraints, parent,
                         sized_to_content, resizable),
      .title = title ? title : L"",
      .owner_window = parent,
      .sizing_delegate = sized_to_content ? AsSizingDelegate() : nullptr,
      .is_sized_to_content = sized_to_content,
  });

  UpdateParentOffset();
}

HostWindowSatellite::~HostWindowSatellite() {
  // Reset the view while this most-derived object is still fully alive, to stop
  // the raster thread from sizing it (via the overridden ApplyContentSize /
  // GetWorkArea) before any subobject is torn down. See the destructor comment
  // in host_window_sized.h for the rationale.
  view_controller_.reset();
}

Rect HostWindowSatellite::GetInitialRect(
    FlutterWindowsEngine* engine,
    const WindowSizeRequest& preferred_size,
    const BoxConstraints& constraints,
    HWND parent,
    bool sized_to_content,
    bool resizable) {
  std::optional<Size> const window_size = GetInitialWindowSize(
      engine, preferred_size, constraints,
      GetWindowStyleForSatellite(resizable), /*extended_window_style=*/0,
      parent, sized_to_content);

  // The placement is resolved after the first frame, so the window is created
  // at a default position and moved before it is shown for the first time.
  return {{CW_USEDEFAULT, CW_USEDEFAULT},
          window_size ? *window_size : Size{CW_USEDEFAULT, CW_USEDEFAULT}};
}

WindowRect HostWindowSatellite::GetWorkArea() const {
  return GetWorkAreaForWindow(parent_);
}

std::optional<WindowRect> HostWindowSatellite::ComputePosition(
    const WindowSize& window_size) const {
  if (!get_position_callback_) {
    return std::nullopt;
  }

  RECT parent_client_rect;
  GetClientRect(parent_, &parent_client_rect);

  // Convert top-left and bottom-right points to screen coordinates.
  POINT parent_top_left = {parent_client_rect.left, parent_client_rect.top};
  POINT parent_bottom_right = {parent_client_rect.right,
                               parent_client_rect.bottom};
  ClientToScreen(parent_, &parent_top_left);
  ClientToScreen(parent_, &parent_bottom_right);

  IsolateScope scope(isolate_);

  WindowRect rect = {};
  get_position_callback_(window_size,
                         WindowRect{parent_top_left.x, parent_top_left.y,
                                    parent_bottom_right.x - parent_top_left.x,
                                    parent_bottom_right.y - parent_top_left.y},
                         GetWorkAreaForWindow(parent_), rect);
  return rect;
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

  std::optional<WindowRect> const rect = ComputePosition(window_size);
  if (!rect) {
    return;
  }

  SetWindowPos(window_handle_, nullptr, rect->left, rect->top, rect->width,
               rect->height, SWP_NOACTIVATE | SWP_NOOWNERZORDER | SWP_NOZORDER);

  initial_position_applied_ = true;

  // The positioner constrained the dimensions more than the current size, so
  // let the framework know about the size it actually got.
  if (rect->width != window_size.width || rect->height != window_size.height) {
    auto metrics_event = view_controller_->view()->CreateWindowMetricsEvent();
    view_controller_->engine()->SendWindowMetricsEvent(metrics_event);
  }
}

void HostWindowSatellite::OnFirstFrame() {
  // A satellite that is sized to content has already been placed from
  // |ApplyContentSize|, which runs once the first frame has been generated.
  ApplyInitialPosition();
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

std::optional<POINT> HostWindowSatellite::GetParentClientOrigin() const {
  // A minimized window's client area has no meaningful position.
  if (IsIconic(parent_)) {
    return std::nullopt;
  }

  POINT origin = {0, 0};
  if (!ClientToScreen(parent_, &origin)) {
    return std::nullopt;
  }

  return origin;
}

double HostWindowSatellite::GetParentScaleFactor() const {
  return static_cast<double>(GetDpiForHWND(parent_)) / kDefaultDpi;
}

void HostWindowSatellite::UpdateParentOffset() {
  std::optional<POINT> const parent_origin = GetParentClientOrigin();
  RECT window_rect;
  if (!parent_origin || !GetWindowRect(window_handle_, &window_rect)) {
    return;
  }

  double const scale_factor = GetParentScaleFactor();
  parent_offset_x_ = (window_rect.left - parent_origin->x) / scale_factor;
  parent_offset_y_ = (window_rect.top - parent_origin->y) / scale_factor;
}

void HostWindowSatellite::OnParentMoved() {
  bool const was_following_parent = std::exchange(is_following_parent_, true);

  // Moving the satellite may carry it onto a monitor with a different DPI. Its
  // WM_DPICHANGED handler then resizes it to the system-suggested rectangle,
  // which may also move it. A second pass corrects for that.
  for (int pass = 0; pass < 2; ++pass) {
    std::optional<POINT> const parent_origin = GetParentClientOrigin();
    RECT window_rect;
    if (!parent_origin || !GetWindowRect(window_handle_, &window_rect)) {
      break;
    }

    double const scale_factor = GetParentScaleFactor();
    LONG const target_x =
        parent_origin->x + std::lround(parent_offset_x_ * scale_factor);
    LONG const target_y =
        parent_origin->y + std::lround(parent_offset_y_ * scale_factor);
    if (target_x == window_rect.left && target_y == window_rect.top) {
      break;
    }

    SetWindowPos(window_handle_, nullptr, target_x, target_y, 0, 0,
                 SWP_NOSIZE | SWP_NOACTIVATE | SWP_NOZORDER);
  }

  is_following_parent_ = was_following_parent;
}

void HostWindowSatellite::SetSatelliteParent(HWND new_parent) {
  if (new_parent == parent_ || new_parent == nullptr) {
    return;
  }

  // Reject a reparent that would make this satellite its own ancestor.
  for (HWND ancestor = new_parent; ancestor != nullptr;
       ancestor = GetWindow(ancestor, GW_OWNER)) {
    if (ancestor == window_handle_) {
      FML_LOG(ERROR) << "Refusing to anchor a satellite window to itself or to "
                        "one of its own satellites.";
      return;
    }
  }

  parent_ = new_parent;
  // Transfer ownership to the new parent, so that the satellite is destroyed
  // alongside it.
  SetWindowLongPtr(window_handle_, GWLP_HWNDPARENT,
                   reinterpret_cast<LONG_PTR>(new_parent));
  SetWindowPos(window_handle_, nullptr, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE |
                   SWP_FRAMECHANGED);

  // Measure the offset against the new parent so that reparenting does not
  // move the satellite.
  UpdateParentOffset();
}

LRESULT HostWindowSatellite::HandleMessage(HWND hwnd,
                                           UINT message,
                                           WPARAM wparam,
                                           LPARAM lparam) {
  switch (message) {
    case WM_SYSCOMMAND:
      // Disallow minimization.
      if ((wparam & 0xFFF0) == SC_MINIMIZE) {
        return 0;
      }
      break;

    case WM_ENTERSIZEMOVE:
      is_in_move_size_loop_ = true;
      break;

    case WM_EXITSIZEMOVE:
      is_in_move_size_loop_ = false;
      break;

    case WM_DPICHANGED: {
      // While the user drags the satellite, or while it is already following
      // its parent (whose loop corrects the position), use the default
      // handling, which applies the system-suggested rectangle.
      if (is_in_move_size_loop_ || is_following_parent_) {
        break;
      }
      
      // Otherwise the DPI change was not caused by the user moving the
      // satellite (e.g. it followed its parent onto another monitor). Apply the
      // suggested rectangle for its new size, without treating the
      // accompanying move as a new offset from the parent, and then re-anchor
      // the satellite to its parent.
      bool const was_following_parent =
          std::exchange(is_following_parent_, true);
      LRESULT const result =
          HostWindow::HandleMessage(hwnd, message, wparam, lparam);
      is_following_parent_ = was_following_parent;
      OnParentMoved();
      return result;
    }

    case WM_WINDOWPOSCHANGED: {
      // When the satellite is moved other than by following its parent (e.g.
      // dragged by the user), keep the new offset from the parent.
      auto const* const window_pos = reinterpret_cast<WINDOWPOS*>(lparam);
      if (!is_following_parent_ && window_pos &&
          !(window_pos->flags & SWP_NOMOVE)) {
        UpdateParentOffset();
      }
      break;
    }

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
