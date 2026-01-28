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
  // Creates a tooltip window.
  HostWindowTooltip(WindowManager* window_manager,
                    FlutterWindowsEngine* engine,
                    const BoxConstraints& constraints,
                    bool is_sized_to_content,
                    GetWindowPositionCallback get_position_callback,
                    HWND parent);

  // Update the position of the tooltip window based off the current size
  // of the tooltip.
  void UpdatePosition();

 protected:
  LRESULT HandleMessage(HWND hwnd,
                        UINT message,
                        WPARAM wparam,
                        LPARAM lparam) override;

 private:
  void DidUpdateViewSize(int32_t width, int32_t height) override;
  WindowRect GetWorkArea() const override;

  GetWindowPositionCallback get_position_callback_;
  HWND parent_;
  Isolate isolate_;

  // Used to track whether the view is still in tasks scheduled from raster
  // thread.
  std::shared_ptr<int> view_alive_;

  // The current width of the tooltip.
  int width_ = 0;

  // The current height of the tooltip.
  int height_ = 0;
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_TOOLTIP_H_
