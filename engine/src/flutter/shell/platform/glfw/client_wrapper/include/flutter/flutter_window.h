// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_GLFW_CLIENT_WRAPPER_INCLUDE_FLUTTER_FLUTTER_WINDOW_H_
#define FLUTTER_SHELL_PLATFORM_GLFW_CLIENT_WRAPPER_INCLUDE_FLUTTER_FLUTTER_WINDOW_H_

#include <string>
#include <vector>

#include <flutter_glfw.h>

#include "plugin_registrar.h"

namespace flutter {

// A window displaying Flutter content.
class FlutterWindow {
 public:
  explicit FlutterWindow(FlutterDesktopWindowRef window) : window_(window) {}

  ~FlutterWindow() = default;

  // Prevent copying.
  FlutterWindow(FlutterWindow const&) = delete;
  FlutterWindow& operator=(FlutterWindow const&) = delete;

  // Enables or disables hover tracking.
  //
  // If hover is enabled, mouse movement will send hover events to the Flutter
  // engine, rather than only tracking the mouse while the button is pressed.
  // Defaults to off.
  void SetHoverEnabled(bool enabled) {
    FlutterDesktopWindowSetHoverEnabled(window_, enabled);
  }

  // Sets the displayed title of the window.
  void SetTitle(const std::string& title) {
    FlutterDesktopWindowSetTitle(window_, title.c_str());
  }

  // Sets the displayed icon for the window.
  //
  // The pixel format is 32-bit RGBA. The provided image data only needs to be
  // valid for the duration of the call to this method. Pass a nullptr to revert
  // to the default icon.
  void SetIcon(uint8_t* pixel_data, int width, int height) {
    FlutterDesktopWindowSetIcon(window_, pixel_data, width, height);
  }

 private:
  // Handle for interacting with the C API's window.
  //
  // Note: window_ is conceptually owned by the controller, not this object.
  FlutterDesktopWindowRef window_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_GLFW_CLIENT_WRAPPER_INCLUDE_FLUTTER_FLUTTER_WINDOW_H_
