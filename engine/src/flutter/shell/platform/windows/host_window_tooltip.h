// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_TOOLTIP_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_TOOLTIP_H_

#include <cstdint>
#include "host_window.h"
#include "shell/platform/windows/flutter_windows_view.h"
#include "shell/platform/windows/window_manager.h"

namespace flutter {
class HostWindowTooltip : public HostWindow,
                          private FlutterWindowsViewSizingDelegate {
 public:
  // Creates a regular window.
  HostWindowTooltip(WindowManager* window_manager,
                    FlutterWindowsEngine* engine,
                    const BoxConstraints& constraints,
                    GetWindowPositionCallback get_position_callback,
                    HWND parent);

  void UpdatePosition();

 private:
  Size GetMinimumViewSize() const override;
  Size GetMaximumViewSize() const override;
  void DidUpdateViewSize(int32_t width, int32_t height) override;
  WindowRect GetWorkArea() const;

  GetWindowPositionCallback get_position_callback_;
  HWND parent_;
  Isolate isolate_;
  int width_ = 0;
  int height_ = 0;
  WindowSize positioner_size_constraints_ = {0, 0};
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_TOOLTIP_H_
