// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOW_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOW_H_

#include <windowsx.h>

#include <iostream>
#include <string>
#include <vector>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/win32_window.h"
#include "flutter/shell/platform/windows/window_binding_handler.h"

namespace flutter {

// A win32 flutter child window used as implementatin for flutter view.  In the
// future, there will likely be a CoreWindow-based FlutterWindow as well.  At
// the point may make sense to dependency inject the native window rather than
// inherit.
class Win32FlutterWindow : public Win32Window, public WindowBindingHandler {
 public:
  // Create flutter Window for use as child window
  Win32FlutterWindow(int width, int height);

  virtual ~Win32FlutterWindow();

  // |Win32Window|
  void OnDpiScale(unsigned int dpi) override;

  // |Win32Window|
  void OnResize(unsigned int width, unsigned int height) override;

  // |Win32Window|
  void OnPointerMove(double x, double y) override;

  // |Win32Window|
  void OnPointerDown(double x, double y, UINT button) override;

  // |Win32Window|
  void OnPointerUp(double x, double y, UINT button) override;

  // |Win32Window|
  void OnPointerLeave() override;

  // |Win32Window|
  void OnSetCursor() override;

  // |Win32Window|
  void OnText(const std::u16string& text) override;

  // |Win32Window|
  void OnKey(int key, int scancode, int action, char32_t character) override;

  // |Win32Window|
  void OnScroll(double delta_x, double delta_y) override;

  // |Win32Window|
  void OnFontChange() override;

  // |FlutterWindowBindingHandler|
  void SetView(WindowBindingHandlerDelegate* view) override;

  // |FlutterWindowBindingHandler|
  WindowsRenderTarget GetRenderTarget() override;

  // |FlutterWindowBindingHandler|
  float GetDpiScale() override;

  // |FlutterWindowBindingHandler|
  PhysicalWindowBounds GetPhysicalWindowBounds() override;

  // |FlutterWindowBindingHandler|
  void UpdateFlutterCursor(const std::string& cursor_name) override;

 private:
  // A pointer to a FlutterWindowsView that can be used to update engine
  // windowing and input state.
  WindowBindingHandlerDelegate* binding_handler_delegate_;

  // The last cursor set by Flutter. Defaults to the arrow cursor.
  HCURSOR current_cursor_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOW_H_
