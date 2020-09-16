// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOW_BINDING_HANDLER_DELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOW_BINDING_HANDLER_DELEGATE_H_

#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

class WindowBindingHandlerDelegate {
 public:
  // Notifies delegate that backing window size has changed.
  // Typically called by currently configured WindowBindingHandler
  virtual void OnWindowSizeChanged(size_t width, size_t height) const = 0;

  // Notifies delegate that backing window mouse has moved.
  // Typically called by currently configured WindowBindingHandler
  virtual void OnPointerMove(double x, double y) = 0;

  // Notifies delegate that backing window mouse pointer button has been
  // pressed. Typically called by currently configured WindowBindingHandler
  virtual void OnPointerDown(double x,
                             double y,
                             FlutterPointerMouseButtons button) = 0;

  // Notifies delegate that backing window mouse pointer button has been
  // released. Typically called by currently configured WindowBindingHandler
  virtual void OnPointerUp(double x,
                           double y,
                           FlutterPointerMouseButtons button) = 0;

  // Notifies delegate that backing window mouse pointer has left the window.
  // Typically called by currently configured WindowBindingHandler
  virtual void OnPointerLeave() = 0;

  // Notifies delegate that backing window has received text.
  // Typically called by currently configured WindowBindingHandler
  virtual void OnText(const std::u16string&) = 0;

  // Notifies delegate that backing window size has received key press.
  // Typically called by currently configured WindowBindingHandler
  virtual void OnKey(int key, int scancode, int action, char32_t character) = 0;

  // Notifies delegate that backing window size has recevied scroll.
  // Typically called by currently configured WindowBindingHandler
  virtual void OnScroll(double x,
                        double y,
                        double delta_x,
                        double delta_y,
                        int scroll_offset_multiplier) = 0;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOW_BINDING_HANDLER_DELEGATE_H_
