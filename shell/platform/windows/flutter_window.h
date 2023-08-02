// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOW_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOW_H_

#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/common/geometry.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/window.h"
#include "flutter/shell/platform/windows/window_binding_handler.h"

namespace flutter {

// A win32 flutter child window used as implementations for flutter view.  In
// the future, there will likely be a CoreWindow-based FlutterWindow as well.
// At the point may make sense to dependency inject the native window rather
// than inherit.
class FlutterWindow : public Window, public WindowBindingHandler {
 public:
  // Create flutter Window for use as child window
  FlutterWindow(int width, int height);

  virtual ~FlutterWindow();

  // |Window|
  void OnDpiScale(unsigned int dpi) override;

  // |Window|
  void OnResize(unsigned int width, unsigned int height) override;

  // |Window|
  void OnPaint() override;

  // |Window|
  void OnPointerMove(double x,
                     double y,
                     FlutterPointerDeviceKind device_kind,
                     int32_t device_id,
                     int modifiers_state) override;

  // |Window|
  void OnPointerDown(double x,
                     double y,
                     FlutterPointerDeviceKind device_kind,
                     int32_t device_id,
                     UINT button) override;

  // |Window|
  void OnPointerUp(double x,
                   double y,
                   FlutterPointerDeviceKind device_kind,
                   int32_t device_id,
                   UINT button) override;

  // |Window|
  void OnPointerLeave(double x,
                      double y,
                      FlutterPointerDeviceKind device_kind,
                      int32_t device_id) override;

  // |Window|
  void OnSetCursor() override;

  // |Window|
  void OnText(const std::u16string& text) override;

  // |Window|
  void OnKey(int key,
             int scancode,
             int action,
             char32_t character,
             bool extended,
             bool was_down,
             KeyEventCallback callback) override;

  // |Window|
  void OnComposeBegin() override;

  // |Window|
  void OnComposeCommit() override;

  // |Window|
  void OnComposeEnd() override;

  // |Window|
  void OnComposeChange(const std::u16string& text, int cursor_pos) override;

  // |FlutterWindowBindingHandler|
  void OnCursorRectUpdated(const Rect& rect) override;

  // |FlutterWindowBindingHandler|
  void OnResetImeComposing() override;

  // |Window|
  void OnUpdateSemanticsEnabled(bool enabled) override;

  // |Window|
  void OnScroll(double delta_x,
                double delta_y,
                FlutterPointerDeviceKind device_kind,
                int32_t device_id) override;

  // |Window|
  gfx::NativeViewAccessible GetNativeViewAccessible() override;

  // |FlutterWindowBindingHandler|
  void SetView(WindowBindingHandlerDelegate* view) override;

  // |FlutterWindowBindingHandler|
  WindowsRenderTarget GetRenderTarget() override;

  // |FlutterWindowBindingHandler|
  PlatformWindow GetPlatformWindow() override;

  // |FlutterWindowBindingHandler|
  float GetDpiScale() override;

  // |FlutterWindowBindingHandler|
  bool IsVisible() override;

  // |FlutterWindowBindingHandler|
  PhysicalWindowBounds GetPhysicalWindowBounds() override;

  // |FlutterWindowBindingHandler|
  void UpdateFlutterCursor(const std::string& cursor_name) override;

  // |FlutterWindowBindingHandler|
  void SetFlutterCursor(HCURSOR cursor) override;

  // |FlutterWindowBindingHandler|
  void OnWindowResized() override;

  // |FlutterWindowBindingHandler|
  bool OnBitmapSurfaceUpdated(const void* allocation,
                              size_t row_bytes,
                              size_t height) override;

  // |FlutterWindowBindingHandler|
  PointerLocation GetPrimaryPointerLocation() override;

  // |Window|
  void OnThemeChange() override;

  // |WindowBindingHandler|
  void SendInitialAccessibilityFeatures() override;

  // |WindowBindingHandler|
  AlertPlatformNodeDelegate* GetAlertDelegate() override;

  // |WindowBindingHandler|
  ui::AXPlatformNodeWin* GetAlert() override;

  // |WindowBindingHandler|
  bool NeedsVSync() override;

  // |Window|
  ui::AXFragmentRootDelegateWin* GetAxFragmentRootDelegate() override;

 private:
  // A pointer to a FlutterWindowsView that can be used to update engine
  // windowing and input state.
  WindowBindingHandlerDelegate* binding_handler_delegate_;

  // The last cursor set by Flutter. Defaults to the arrow cursor.
  HCURSOR current_cursor_;

  // The cursor rect set by Flutter.
  RECT cursor_rect_;

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterWindow);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_WINDOW_H_
