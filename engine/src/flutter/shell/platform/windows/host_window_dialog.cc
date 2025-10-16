// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/host_window_dialog.h"

#include "flutter/shell/platform/windows/flutter_windows_engine.h"

namespace {
DWORD GetWindowStyleForDialog(std::optional<HWND> const& owner_window) {
  DWORD window_style = WS_OVERLAPPED | WS_CAPTION | WS_THICKFRAME;
  if (!owner_window) {
    // If the dialog has no owner, add a minimize box and a system menu.
    window_style |= WS_MINIMIZEBOX | WS_SYSMENU;
  }

  return window_style;
}

DWORD GetExtendedWindowStyleForDialog(std::optional<HWND> const& owner_window) {
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
}  // namespace

namespace flutter {

HostWindowDialog::HostWindowDialog(WindowManager* window_manager,
                                   FlutterWindowsEngine* engine,
                                   const WindowSizeRequest& preferred_size,
                                   const BoxConstraints& constraints,
                                   LPCWSTR title,
                                   std::optional<HWND> const& owner_window)
    : HostWindow(
          window_manager,
          engine,
          WindowArchetype::kDialog,
          GetWindowStyleForDialog(owner_window),
          GetExtendedWindowStyleForDialog(owner_window),
          constraints,
          GetInitialRect(engine, preferred_size, constraints, owner_window),
          title,
          owner_window) {
  auto hwnd = window_handle_;
  if (owner_window == nullptr) {
    if (HMENU hMenu = GetSystemMenu(hwnd, FALSE)) {
      EnableMenuItem(hMenu, SC_CLOSE, MF_BYCOMMAND | MF_GRAYED);
    }
  }

  if (owner_window != nullptr) {
    UpdateModalState();
  }
}

Rect HostWindowDialog::GetInitialRect(FlutterWindowsEngine* engine,
                                      const WindowSizeRequest& preferred_size,
                                      const BoxConstraints& constraints,
                                      std::optional<HWND> const& owner_window) {
  auto const window_style = GetWindowStyleForDialog(owner_window);
  auto const extended_window_style =
      GetExtendedWindowStyleForDialog(owner_window);
  std::optional<Size> const window_size =
      HostWindow::GetWindowSizeForClientSize(
          *engine->windows_proc_table(),
          Size(preferred_size.preferred_view_width,
               preferred_size.preferred_view_height),
          constraints.smallest(), constraints.biggest(), window_style,
          extended_window_style, owner_window);
  Point window_origin = {CW_USEDEFAULT, CW_USEDEFAULT};
  if (owner_window && window_size.has_value()) {
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
