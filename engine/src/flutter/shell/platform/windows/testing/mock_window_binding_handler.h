// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_WINDOW_BINDING_HANDLER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_WINDOW_BINDING_HANDLER_H_

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/windows/window_binding_handler.h"
#include "flutter/third_party/accessibility/ax/platform/ax_platform_node_win.h"
#include "gmock/gmock.h"

namespace flutter {
namespace testing {

/// Mock for the |Window| base class.
class MockWindowBindingHandler : public WindowBindingHandler {
 public:
  MockWindowBindingHandler();
  virtual ~MockWindowBindingHandler();

  MOCK_METHOD1(SetView, void(WindowBindingHandlerDelegate* view));
  MOCK_METHOD0(GetRenderTarget, WindowsRenderTarget());
  MOCK_METHOD0(GetPlatformWindow, PlatformWindow());
  MOCK_METHOD0(GetDpiScale, float());
  MOCK_METHOD0(IsVisible, bool());
  MOCK_METHOD0(OnWindowResized, void());
  MOCK_METHOD0(GetPhysicalWindowBounds, PhysicalWindowBounds());
  MOCK_METHOD1(UpdateFlutterCursor, void(const std::string& cursor_name));
  MOCK_METHOD1(SetFlutterCursor, void(HCURSOR cursor_name));
  MOCK_METHOD1(OnCursorRectUpdated, void(const Rect& rect));
  MOCK_METHOD0(OnResetImeComposing, void());
  MOCK_METHOD3(OnBitmapSurfaceUpdated,
               bool(const void* allocation, size_t row_bytes, size_t height));
  MOCK_METHOD0(GetPrimaryPointerLocation, PointerLocation());
  MOCK_METHOD0(SendInitialAccessibilityFeatures, void());
  MOCK_METHOD0(GetAlertDelegate, AlertPlatformNodeDelegate*());
  MOCK_METHOD0(GetAlert, ui::AXPlatformNodeWin*());
  MOCK_METHOD0(NeedsVSync, bool());

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(MockWindowBindingHandler);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_WINDOW_BINDING_HANDLER_H_
