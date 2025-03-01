// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_WINDOWING_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_WINDOWING_H_

#include <optional>

#include "flutter/fml/logging.h"
#include "geometry.h"

namespace flutter {

// A unique identifier for a view.
using FlutterViewId = int64_t;

// Types of windows.
enum class WindowArchetype {
  // Regular top-level window.
  kRegular,
  // Popup.
  kPopup,
};

// Possible states a window can be in.
enum class WindowState {
  // Normal state, neither maximized, nor minimized.
  kRestored,
  // Maximized, occupying the full screen but still showing the system UI.
  kMaximized,
  // Minimized and not visible on the screen.
  kMinimized,
};

// Converts a |flutter::WindowState| to the string representation of
// |WindowState| as defined in the framework.
inline std::string WindowStateToString(WindowState state) {
  switch (state) {
    case WindowState::kRestored:
      return "WindowState.restored";
    case WindowState::kMaximized:
      return "WindowState.maximized";
    case WindowState::kMinimized:
      return "WindowState.minimized";
    default:
      FML_UNREACHABLE();
  }
}

// Converts the string representation of |WindowState| defined in the framework
// to a |flutter::WindowState|. Returns std::nullopt if the given string is
// invalid.
inline std::optional<WindowState> StringToWindowState(std::string_view str) {
  if (str == "WindowState.restored")
    return WindowState::kRestored;
  if (str == "WindowState.maximized")
    return WindowState::kMaximized;
  if (str == "WindowState.minimized")
    return WindowState::kMinimized;
  return std::nullopt;
}

// Defines how a child window should be positioned relative to its parent.
struct WindowPositioner {
  // Allowed anchor positions.
  enum class Anchor {
    kCenter,       // Center.
    kTop,          // Top, centered horizontally.
    kBottom,       // Bottom, centered horizontally.
    kLeft,         // Left, centered vertically.
    kRight,        // Right, centered vertically.
    kTopLeft,      // Top-left corner.
    kBottomLeft,   // Bottom-left corner.
    kTopRight,     // Top-right corner.
    kBottomRight,  // Bottom-right corner.
  };

  // Specifies how a window should be adjusted if it doesn't fit the placement
  // bounds. In order of precedence:
  // 1. 'kFlip{X|Y|Any}': reverse the anchor points and offset along an axis.
  // 2. 'kSlide{X|Y|Any}': adjust the offset along an axis.
  // 3. 'kResize{X|Y|Any}': adjust the window size along an axis.
  enum class ConstraintAdjustment {
    kNone = 0,                         // No adjustment.
    kSlideX = 1 << 0,                  // Slide horizontally to fit.
    kSlideY = 1 << 1,                  // Slide vertically to fit.
    kFlipX = 1 << 2,                   // Flip horizontally to fit.
    kFlipY = 1 << 3,                   // Flip vertically to fit.
    kResizeX = 1 << 4,                 // Resize horizontally to fit.
    kResizeY = 1 << 5,                 // Resize vertically to fit.
    kFlipAny = kFlipX | kFlipY,        // Flip in any direction to fit.
    kSlideAny = kSlideX | kSlideY,     // Slide in any direction to fit.
    kResizeAny = kResizeX | kResizeY,  // Resize in any direction to fit.
  };

  // The reference anchor rectangle relative to the client rectangle of the
  // parent window. If nullopt, the anchor rectangle is assumed to be the window
  // rectangle.
  std::optional<Rect> anchor_rect;
  // Specifies which anchor of the parent window to align to.
  Anchor parent_anchor = Anchor::kCenter;
  // Specifies which anchor of the child window to align with the parent.
  Anchor child_anchor = Anchor::kCenter;
  // Offset relative to the position of the anchor on the anchor rectangle and
  // the anchor on the child.
  Point offset;
  // The adjustments to apply if the window doesn't fit the available space.
  // The order of precedence is: 1) Flip, 2) Slide, 3) Resize.
  ConstraintAdjustment constraint_adjustment = ConstraintAdjustment::kNone;
};

// Settings used for creating a Flutter window.
struct WindowCreationSettings {
  // Type of the window.
  WindowArchetype archetype = WindowArchetype::kRegular;
  // Requested size of the window's client area, in logical coordinates.
  Size size;
  // Minimum size of the window's client area, in logical coordinates.
  std::optional<Size> min_size;
  // Maximum size of the window's client area, in logical coordinates.
  std::optional<Size> max_size;
  // Window title. Required by WindowArchetype::kRegular.
  std::optional<std::string> title;
  // Initial state of the window. Used by WindowArchetype::kRegular.
  std::optional<WindowState> state;
  // The ID of the view used by the parent window. Required by
  // WindowArchetype::kPopup.
  std::optional<FlutterViewId> parent_view_id;
  // Positioning settings. Required by WindowArchetype::kPopup.
  std::optional<WindowPositioner> positioner;
};

// Settings for modifying a Flutter window.
struct WindowModificationSettings {
  // The new requested size, in logical coordinates.
  std::optional<Size> size;
  // The new window title.
  std::optional<std::string> title;
  // The new window state.
  std::optional<WindowState> state;
};

// Window metadata returned as the result of creating a Flutter window.
struct WindowMetadata {
  // The ID of the view used for this window, which is unique to each window.
  FlutterViewId view_id = 0;
  /// The archetype of the window.
  WindowArchetype archetype;
  // Size of the created window, in logical coordinates.
  Size size;
  // The ID of the view used by the parent window. If not set, the window is
  // assumed a top-level window.
  std::optional<FlutterViewId> parent_id;
  // The initial state of the window, or std::nullopt if not a regular window.
  // Used by WindowArchetype::kRegular.
  std::optional<WindowState> state;
  // Relative position between the top-left corner of this window and the
  // top-left corner of its parent window, in logical coordinates. Used by
  // WindowArchetype::kPopup.
  std::optional<Point> relative_position;
};

// Computes the screen-space rectangle for a child window placed according to
// the given |positioner|. |child_size| is the frame size of the child window.
// |anchor_rect| is the rectangle relative to which the child window is placed.
// |parent_rect| is the parent window's rectangle. |output_rect| is the output
// display area where the child window will be placed. All sizes and rectangles
// are in physical coordinates. Note: WindowPositioner::anchor_rect is not used
// in this function; use |anchor_rect| to set the anchor rectangle for the
// child.
Rect PlaceWindow(WindowPositioner const& positioner,
                 Size child_size,
                 Rect const& anchor_rect,
                 Rect const& parent_rect,
                 Rect const& output_rect);

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_WINDOWING_H_
