// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/host_window_satellite.h"

#include "flutter/fml/logging.h"
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

  // |HostWindow::InitializeFlutterView| aligns a window's origin with the
  // top-left corner of its frame rather than its window rectangle, which
  // includes the invisible drop-shadow border. Reapply the same adjustment
  // here so that the positioner's result is interpreted the same way.
  AlignOriginWithFrame();

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
      // Disallow minimization.
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
