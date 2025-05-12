// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_WINDOWING_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_WINDOWING_H_

namespace flutter {

// Types of windows.
// The value must match value from WindowType in the Dart code.
enum class WindowArchetype {
  // Regular top-level window.
  kRegular,
};

// Possible states a window can be in.
// The values must match values from WindowState in the Dart code.
enum class WindowState {
  // Normal state, neither maximized, nor minimized.
  kRestored,
  // Maximized, occupying the full screen but still showing the system UI.
  kMaximized,
  // Minimized and not visible on the screen.
  kMinimized,
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_WINDOWING_H_
