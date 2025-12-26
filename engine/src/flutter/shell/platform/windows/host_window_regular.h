// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_REGULAR_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_REGULAR_H_

#include "host_window.h"

namespace flutter {
class HostWindowRegular : public HostWindow {
 public:
  // Creates a regular window.
  HostWindowRegular(WindowManager* window_manager,
                    FlutterWindowsEngine* engine,
                    const WindowSizeRequest& preferred_size,
                    const BoxConstraints& constraints,
                    LPCWSTR title);

 private:
  static Rect GetInitialRect(FlutterWindowsEngine* engine,
                             const WindowSizeRequest& preferred_size,
                             const BoxConstraints& constraints);
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_REGULAR_H_
