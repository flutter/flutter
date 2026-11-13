// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_ON_SCREEN_KEYBOARD_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_ON_SCREEN_KEYBOARD_H_

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/windows/on_screen_keyboard.h"
#include "gmock/gmock.h"

namespace flutter {
namespace testing {

class MockOnScreenKeyboard : public OnScreenKeyboard {
 public:
  MockOnScreenKeyboard() = default;
  ~MockOnScreenKeyboard() override = default;

  MOCK_METHOD(void,
              SetVisibilityChangedCallback,
              (OnScreenKeyboard::VisibilityChanged callback),
              (override));
  MOCK_METHOD(void, Display, (HWND hwnd), (override));
  MOCK_METHOD(void, Dismiss, (HWND hwnd), (override));
  MOCK_METHOD(void, OnClientCleared, (), (override));
  MOCK_METHOD(bool, shown, (), (const, override));
  MOCK_METHOD(double, physical_bottom_inset, (), (const, override));

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(MockOnScreenKeyboard);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_ON_SCREEN_KEYBOARD_H_
