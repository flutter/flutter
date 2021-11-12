// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_TEXT_INPUT_MANAGER_WIN32_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_TEXT_INPUT_MANAGER_WIN32_H_

#include <windowsx.h>
#include <cstring>
#include <optional>

#include "flutter/shell/platform/windows/text_input_manager_win32.h"
#include "gmock/gmock.h"

namespace flutter {
namespace testing {

/// Mock for the |WindowWin32| base class.
class MockTextInputManagerWin32 : public TextInputManagerWin32 {
 public:
  MockTextInputManagerWin32();
  virtual ~MockTextInputManagerWin32();

  // Prevent copying.
  MockTextInputManagerWin32(MockTextInputManagerWin32 const&) = delete;
  MockTextInputManagerWin32& operator=(MockTextInputManagerWin32 const&) =
      delete;

  MOCK_CONST_METHOD0(GetComposingString, std::optional<std::u16string>());
  MOCK_CONST_METHOD0(GetResultString, std::optional<std::u16string>());
  MOCK_CONST_METHOD0(GetComposingCursorPosition, long());
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_TEXT_INPUT_MANAGER_WIN32_H_
