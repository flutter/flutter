// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_POPUP_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_POPUP_H_

#include <cstdint>
#include "host_window_sized.h"
#include "shell/platform/windows/flutter_windows_view.h"
#include "shell/platform/windows/window_manager.h"

namespace flutter {
class HostWindowPopup : public HostWindowSized {
 public:
  // Creates a popup window.
  HostWindowPopup(WindowManager* window_manager,
                  FlutterWindowsEngine* engine,
                  const BoxConstraints& constraints,
                  GetWindowPositionCallback get_position_callback,
                  HWND parent);

  // Update the position of the popup window based off the current size
  // of the popup.
  void UpdatePosition();

 protected:
  void ApplyContentSize(int32_t physical_width,
                        int32_t physical_height) override;

 private:
  WindowRect GetWorkArea() const override;

  GetWindowPositionCallback get_position_callback_;
  HWND parent_;
  Isolate isolate_;
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_POPUP_H_
