// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/host_window_regular.h"

#include "flutter/shell/platform/windows/flutter_windows_engine.h"

namespace flutter {
HostWindowRegular::HostWindowRegular(WindowManager* window_manager,
                                     FlutterWindowsEngine* engine,
                                     const WindowSizeRequest& preferred_size,
                                     const BoxConstraints& constraints,
                                     LPCWSTR title)

    : HostWindow(window_manager,
                 engine,
                 WindowArchetype::kRegular,
                 WS_OVERLAPPEDWINDOW,
                 0,
                 constraints,
                 GetInitialRect(engine, preferred_size, constraints),
                 title,
                 std::nullopt) {
  // TODO(knopp): Investigate sizing the window to its content with the help of
  // https://github.com/flutter/flutter/pull/173610.
  FML_CHECK(preferred_size.has_preferred_view_size);
}

Rect HostWindowRegular::GetInitialRect(FlutterWindowsEngine* engine,
                                       const WindowSizeRequest& preferred_size,
                                       const BoxConstraints& constraints) {
  std::optional<Size> const window_size =
      HostWindow::GetWindowSizeForClientSize(
          *engine->windows_proc_table(),
          Size(preferred_size.preferred_view_width,
               preferred_size.preferred_view_height),
          constraints.smallest(), constraints.biggest(), WS_OVERLAPPEDWINDOW, 0,
          nullptr);
  return {{CW_USEDEFAULT, CW_USEDEFAULT},
          window_size ? *window_size : Size{CW_USEDEFAULT, CW_USEDEFAULT}};
}

}  // namespace flutter
