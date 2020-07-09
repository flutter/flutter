// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <windowsx.h>

#include "flutter/shell/platform/windows/win32_window.h"

namespace flutter {
namespace testing {

/// Test class for the Win32Window base class. Used to access protected methods
/// for testing.
class Win32WindowTest : public Win32Window {
 public:
  Win32WindowTest();
  virtual ~Win32WindowTest();

  // Prevent copying.
  Win32WindowTest(Win32WindowTest const&) = delete;
  Win32WindowTest& operator=(Win32WindowTest const&) = delete;

  // Wrapper for GetCurrentDPI() which is a protected method.
  UINT GetDpi();

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
};

}  // namespace testing
}  // namespace flutter
