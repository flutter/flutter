// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOW_BINDING_HANDLER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOW_BINDING_HANDLER_H_

#include <windows.h>

#include <string>
#include <variant>

#include "flutter/shell/platform/common/alert_platform_node_delegate.h"
#include "flutter/shell/platform/common/geometry.h"
#include "flutter/shell/platform/windows/public/flutter_windows.h"
#include "flutter/shell/platform/windows/window_binding_handler_delegate.h"

namespace ui {
class AXPlatformNodeWin;
}

namespace flutter {

class FlutterWindowsView;

// Structure containing physical bounds of a Window
struct PhysicalWindowBounds {
  size_t width;
  size_t height;
};

// Structure containing the position of a mouse pointer in the coordinate system
// specified by the function where it's used.
struct PointerLocation {
  size_t x;
  size_t y;
};

// Abstract class for binding Windows platform windows to Flutter views.
class WindowBindingHandler {
 public:
  virtual ~WindowBindingHandler() = default;

  // Sets the delegate used to communicate state changes from window to view
  // such as key presses, mouse position updates etc.
  virtual void SetView(WindowBindingHandlerDelegate* view) = 0;

  // Returns the underlying HWND backing the window.
  virtual HWND GetWindowHandle() = 0;

  // Returns the scale factor for the backing window.
  virtual float GetDpiScale() = 0;

  // Returns the bounds of the backing window in physical pixels.
  virtual PhysicalWindowBounds GetPhysicalWindowBounds() = 0;

  // Invoked when the cursor/composing rect has been updated in the framework.
  virtual void OnCursorRectUpdated(const Rect& rect) = 0;

  // Invoked when the embedder clears the contents of this Flutter view.
  //
  // Returns whether the surface was successfully updated or not.
  virtual bool OnBitmapSurfaceCleared() = 0;

  // Invoked when the embedder provides us with new bitmap data for the contents
  // of this Flutter view.
  //
  // Returns whether the surface was successfully updated or not.
  virtual bool OnBitmapSurfaceUpdated(const void* allocation,
                                      size_t row_bytes,
                                      size_t height) = 0;

  // Invoked when the app ends IME composing, such when the active text input
  // client is cleared.
  virtual void OnResetImeComposing() = 0;

  // Returns the last known position of the primary pointer in window
  // coordinates.
  virtual PointerLocation GetPrimaryPointerLocation() = 0;

  // Retrieve the delegate for the alert.
  virtual AlertPlatformNodeDelegate* GetAlertDelegate() = 0;

  // Retrieve the alert node.
  virtual ui::AXPlatformNodeWin* GetAlert() = 0;

  // Focuses the current window.
  // Returns true if the window was successfully focused.
  virtual bool Focus() = 0;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOW_BINDING_HANDLER_H_
