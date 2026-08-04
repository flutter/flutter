// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_REGULAR_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_REGULAR_H_

#include "host_window_sized.h"

namespace flutter {
class HostWindowRegular : public HostWindowSized {
 public:
  // Creates a regular window.
  //
  // If |sized_to_content| is true, the window is initially sized to the
  // minimum of |constraints|. The window will automatically resize to its
  // rendered content after each frame. If |resizable| is false, the window
  // will continue to track content size after the initial sizing and its
  // resize border is removed. If |resizable| is true, the user may resize the
  // window manually after the initial content-based sizing.
  //
  // If |sized_to_content| is false, the window is created with the size
  // specified in |preferred_size|.
  HostWindowRegular(WindowManager* window_manager,
                    FlutterWindowsEngine* engine,
                    const WindowSizeRequest& preferred_size,
                    const BoxConstraints& constraints,
                    LPCWSTR title,
                    bool sized_to_content,
                    bool resizable);

  ~HostWindowRegular() override;

 private:
  static Rect GetInitialRect(FlutterWindowsEngine* engine,
                             const WindowSizeRequest& preferred_size,
                             const BoxConstraints& constraints,
                             bool sized_to_content,
                             bool resizable);
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_REGULAR_H_
