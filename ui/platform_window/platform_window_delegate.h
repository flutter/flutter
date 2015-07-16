// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_PLATFORM_WINDOW_PLATFORM_WINDOW_DELEGATE_H_
#define UI_PLATFORM_WINDOW_PLATFORM_WINDOW_DELEGATE_H_

#include "ui/gfx/native_widget_types.h"

namespace gfx {
class Rect;
}

namespace ui {

class Event;

enum PlatformWindowState {
  PLATFORM_WINDOW_STATE_UNKNOWN,
  PLATFORM_WINDOW_STATE_MAXIMIZED,
  PLATFORM_WINDOW_STATE_MINIMIZED,
  PLATFORM_WINDOW_STATE_NORMAL,
  PLATFORM_WINDOW_STATE_FULLSCREEN,
};

class PlatformWindowDelegate {
 public:
  virtual ~PlatformWindowDelegate() {}

  // Note that |new_bounds| is in physical screen coordinates.
  virtual void OnBoundsChanged(const gfx::Rect& new_bounds) = 0;

  // Note that |damaged_region| is in the platform-window's coordinates, in
  // physical pixels.
  virtual void OnDamageRect(const gfx::Rect& damaged_region) = 0;

  virtual void DispatchEvent(Event* event) = 0;

  virtual void OnCloseRequest() = 0;
  virtual void OnClosed() = 0;

  virtual void OnWindowStateChanged(PlatformWindowState new_state) = 0;

  virtual void OnLostCapture() = 0;

  virtual void OnAcceleratedWidgetAvailable(gfx::AcceleratedWidget widget) = 0;

  virtual void OnActivationChanged(bool active) = 0;
};

}  // namespace ui

#endif  // UI_PLATFORM_WINDOW_PLATFORM_WINDOW_DELEGATE_H_
