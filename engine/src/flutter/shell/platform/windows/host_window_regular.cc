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
    : HostWindowSized(window_manager, engine, resizable) {
  FML_CHECK(sized_to_content || preferred_size.has_preferred_view_size);
  DWORD const window_style = GetWindowStyleForRegular(resizable);
  InitializeFlutterView(HostWindowInitializationParams{
      .archetype = WindowArchetype::kRegular,
      .window_style = window_style,
      .extended_window_style = 0,
      .box_constraints = constraints,
      .initial_window_rect = GetInitialRect(engine, preferred_size, constraints,
                                            sized_to_content, resizable),
      .title = title,
      .owner_window = std::optional<HWND>(),
      .sizing_delegate = sized_to_content ? AsSizingDelegate() : nullptr,
      .is_sized_to_content = sized_to_content,
  });
}

HostWindowRegular::~HostWindowRegular() {
  // Reset the view while this most-derived object is still fully alive, to stop
  // the raster thread from sizing it before any subobject is torn down. See the
  // destructor comment in host_window_sized.h for the rationale.
  view_controller_.reset();
}

Rect HostWindowRegular::GetInitialRect(FlutterWindowsEngine* engine,
                                       const WindowSizeRequest& preferred_size,
                                       const BoxConstraints& constraints,
                                       bool sized_to_content,
                                       bool resizable) {
  std::optional<Size> const window_size = GetInitialWindowSize(
      engine, preferred_size, constraints, GetWindowStyleForRegular(resizable),
      /*extended_window_style=*/0, /*owner_window=*/std::nullopt,
      sized_to_content);
  return {{CW_USEDEFAULT, CW_USEDEFAULT},
          window_size ? *window_size : Size{CW_USEDEFAULT, CW_USEDEFAULT}};
}

}  // namespace flutter
