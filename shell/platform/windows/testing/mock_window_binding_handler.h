// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_WINDOW_BINDING_HANDLER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_WINDOW_BINDING_HANDLER_H_

#include <windowsx.h>

#include "flutter/shell/platform/windows/window_binding_handler.h"
#include "gmock/gmock.h"

namespace flutter {
namespace testing {

/// Mock for the |WindowWin32| base class.
class MockWindowBindingHandler : public WindowBindingHandler {
 public:
  MockWindowBindingHandler();
  virtual ~MockWindowBindingHandler();

  // Prevent copying.
  MockWindowBindingHandler(MockWindowBindingHandler const&) = delete;
  MockWindowBindingHandler& operator=(MockWindowBindingHandler const&) = delete;

  MOCK_METHOD1(SetView, void(WindowBindingHandlerDelegate* view));
  MOCK_METHOD0(GetRenderTarget, WindowsRenderTarget());
  MOCK_METHOD0(GetPlatformWindow, PlatformWindow());
  MOCK_METHOD0(GetDpiScale, float());
  MOCK_METHOD0(IsVisible, bool());
  MOCK_METHOD0(OnWindowResized, void());
  MOCK_METHOD0(GetPhysicalWindowBounds, PhysicalWindowBounds());
  MOCK_METHOD1(UpdateFlutterCursor, void(const std::string& cursor_name));
  MOCK_METHOD1(OnCursorRectUpdated, void(const Rect& rect));
  MOCK_METHOD0(OnResetImeComposing, void());
  MOCK_METHOD3(OnBitmapSurfaceUpdated,
               bool(const void* allocation, size_t row_bytes, size_t height));
  MOCK_METHOD0(GetPrimaryPointerLocation, PointerLocation());
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_WINDOW_BINDING_HANDLER_H_
