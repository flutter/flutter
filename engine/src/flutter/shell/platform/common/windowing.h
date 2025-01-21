// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_WINDOWING_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_WINDOWING_H_

#include <optional>

#include "geometry.h"

namespace flutter {

// A unique identifier for a view.
using FlutterViewId = int64_t;

// Types of windows.
enum class WindowArchetype {
  // Regular top-level window.
  regular,
};

// Possible states a window can be in.
enum class WindowState {
  // Normal state, neither maximized, nor minimized.
  restored,
  // Maximized, occupying the full screen but still showing the system UI.
  maximized,
  // Minimized and not visible on the screen.
  minimized,
};

// Converts a |flutter::WindowState| to its corresponding string representation.
inline std::string WindowStateToString(WindowState state) {
  switch (state) {
    case WindowState::restored:
      return "WindowState.restored";
    case WindowState::maximized:
      return "WindowState.maximized";
    case WindowState::minimized:
      return "WindowState.minimized";
  }
  return {};
}

// Converts a string to a |flutter::WindowState|. Returns std::nullopt if
// invalid.
inline std::optional<WindowState> StringToWindowState(std::string_view str) {
  if (str == "WindowState.restored")
    return WindowState::restored;
  if (str == "WindowState.maximized")
    return WindowState::maximized;
  if (str == "WindowState.minimized")
    return WindowState::minimized;
  return std::nullopt;
}

// Settings used for creating a Flutter window.
struct WindowCreationSettings {
  // Type of the window.
  WindowArchetype archetype = WindowArchetype::regular;
  // Requested size of the window's client area, in logical coordinates.
  Size size;
  // Minimum size of the window's client area, in logical coordinates.
  std::optional<Size> min_size;
  // Maximum size of the window's client area, in logical coordinates.
  std::optional<Size> max_size;
  // Window title.
  std::optional<std::string> title;
  // Initial state of the window.
  std::optional<WindowState> state;
};

// Window metadata returned as the result of creating a Flutter window.
struct WindowMetadata {
  // The ID of the view used for this window, which is unique to each window.
  FlutterViewId view_id = 0;
  // The type of the window.
  WindowArchetype archetype = WindowArchetype::regular;
  // Size of the created window, in logical coordinates.
  Size size;
  // The ID of the view used by the parent window. If not set, the window is
  // assumed a top-level window.
  std::optional<FlutterViewId> parent_id;
  // The initial state of the window, or std::nullopt if not a regular window.
  std::optional<WindowState> state;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_WINDOWING_H_
