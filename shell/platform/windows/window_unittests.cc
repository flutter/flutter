// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/testing/mock_text_input_manager_win32.h"
#include "flutter/shell/platform/windows/testing/mock_window.h"
#include "gtest/gtest.h"

using testing::_;
using testing::InSequence;
using testing::Invoke;
using testing::Return;

namespace flutter {
namespace testing {

TEST(MockWindow, CreateDestroy) {
  MockWindow window;
  ASSERT_TRUE(TRUE);
}

TEST(MockWindow, GetDpiAfterCreate) {
  MockWindow window;
  ASSERT_TRUE(window.GetDpi() > 0);
}

TEST(MockWindow, VerticalScroll) {
  MockWindow window;
  const int scroll_amount = 10;
  // Vertical scroll should be passed along, adjusted for scroll tick size
  // and direction.
  EXPECT_CALL(window, OnScroll(0, -scroll_amount / 120.0,
                               kFlutterPointerDeviceKindMouse, 0))
      .Times(1);

  window.InjectWindowMessage(WM_MOUSEWHEEL, MAKEWPARAM(0, scroll_amount), 0);
}

TEST(MockWindow, OnImeCompositionCompose) {
  MockTextInputManagerWin32* text_input_manager =
      new MockTextInputManagerWin32();
  std::unique_ptr<TextInputManagerWin32> text_input_manager_ptr(
      text_input_manager);
  MockWindow window(std::move(text_input_manager_ptr));
  EXPECT_CALL(*text_input_manager, GetComposingString())
      .WillRepeatedly(
          Return(std::optional<std::u16string>(std::u16string(u"nihao"))));
  EXPECT_CALL(*text_input_manager, GetResultString())
      .WillRepeatedly(
          Return(std::optional<std::u16string>(std::u16string(u"`}"))));
  EXPECT_CALL(*text_input_manager, GetComposingCursorPosition())
      .WillRepeatedly(Return((int)0));

  EXPECT_CALL(window, OnComposeChange(std::u16string(u"nihao"), 0)).Times(1);
  EXPECT_CALL(window, OnComposeChange(std::u16string(u"`}"), 0)).Times(0);
  EXPECT_CALL(window, OnComposeCommit()).Times(0);
  ON_CALL(window, OnImeComposition)
      .WillByDefault(Invoke(&window, &MockWindow::CallOnImeComposition));
  EXPECT_CALL(window, OnImeComposition(_, _, _)).Times(1);

  // Send an IME_COMPOSITION event that contains just the composition string.
  window.InjectWindowMessage(WM_IME_COMPOSITION, 0, GCS_COMPSTR);
}

TEST(MockWindow, OnImeCompositionResult) {
  MockTextInputManagerWin32* text_input_manager =
      new MockTextInputManagerWin32();
  std::unique_ptr<TextInputManagerWin32> text_input_manager_ptr(
      text_input_manager);
  MockWindow window(std::move(text_input_manager_ptr));
  EXPECT_CALL(*text_input_manager, GetComposingString())
      .WillRepeatedly(
          Return(std::optional<std::u16string>(std::u16string(u"nihao"))));
  EXPECT_CALL(*text_input_manager, GetResultString())
      .WillRepeatedly(
          Return(std::optional<std::u16string>(std::u16string(u"`}"))));
  EXPECT_CALL(*text_input_manager, GetComposingCursorPosition())
      .WillRepeatedly(Return((int)0));

  EXPECT_CALL(window, OnComposeChange(std::u16string(u"nihao"), 0)).Times(0);
  EXPECT_CALL(window, OnComposeChange(std::u16string(u"`}"), 0)).Times(1);
  EXPECT_CALL(window, OnComposeCommit()).Times(1);
  ON_CALL(window, OnImeComposition)
      .WillByDefault(Invoke(&window, &MockWindow::CallOnImeComposition));
  EXPECT_CALL(window, OnImeComposition(_, _, _)).Times(1);

  // Send an IME_COMPOSITION event that contains just the result string.
  window.InjectWindowMessage(WM_IME_COMPOSITION, 0, GCS_RESULTSTR);
}

TEST(MockWindow, OnImeCompositionResultAndCompose) {
  MockTextInputManagerWin32* text_input_manager =
      new MockTextInputManagerWin32();
  std::unique_ptr<TextInputManagerWin32> text_input_manager_ptr(
      text_input_manager);
  MockWindow window(std::move(text_input_manager_ptr));

  // This situation is that Google Japanese Input finished composing "今日" in
  // "今日は" but is still composing "は".
  {
    InSequence dummy;
    EXPECT_CALL(*text_input_manager, GetResultString())
        .WillRepeatedly(
            Return(std::optional<std::u16string>(std::u16string(u"今日"))));
    EXPECT_CALL(*text_input_manager, GetComposingString())
        .WillRepeatedly(
            Return(std::optional<std::u16string>(std::u16string(u"は"))));
  }
  {
    InSequence dummy;
    EXPECT_CALL(window, OnComposeChange(std::u16string(u"今日"), 0)).Times(1);
    EXPECT_CALL(window, OnComposeCommit()).Times(1);
    EXPECT_CALL(window, OnComposeChange(std::u16string(u"は"), 0)).Times(1);
  }

  EXPECT_CALL(*text_input_manager, GetComposingCursorPosition())
      .WillRepeatedly(Return((int)0));

  ON_CALL(window, OnImeComposition)
      .WillByDefault(Invoke(&window, &MockWindow::CallOnImeComposition));
  EXPECT_CALL(window, OnImeComposition(_, _, _)).Times(1);

  // send an IME_COMPOSITION event that contains both the result string and the
  // composition string.
  window.InjectWindowMessage(WM_IME_COMPOSITION, 0,
                             GCS_COMPSTR | GCS_RESULTSTR);
}

TEST(MockWindow, OnImeCompositionClearChange) {
  MockTextInputManagerWin32* text_input_manager =
      new MockTextInputManagerWin32();
  std::unique_ptr<TextInputManagerWin32> text_input_manager_ptr(
      text_input_manager);
  MockWindow window(std::move(text_input_manager_ptr));
  EXPECT_CALL(window, OnComposeChange(std::u16string(u""), 0)).Times(1);
  EXPECT_CALL(window, OnComposeCommit()).Times(1);
  ON_CALL(window, OnImeComposition)
      .WillByDefault(Invoke(&window, &MockWindow::CallOnImeComposition));
  EXPECT_CALL(window, OnImeComposition(_, _, _)).Times(1);

  // send an IME_COMPOSITION event that contains both the result string and the
  // composition string.
  window.InjectWindowMessage(WM_IME_COMPOSITION, 0, 0);
}

TEST(MockWindow, HorizontalScroll) {
  MockWindow window;
  const int scroll_amount = 10;
  // Vertical scroll should be passed along, adjusted for scroll tick size.
  EXPECT_CALL(window, OnScroll(scroll_amount / 120.0, 0,
                               kFlutterPointerDeviceKindMouse, 0))
      .Times(1);

  window.InjectWindowMessage(WM_MOUSEHWHEEL, MAKEWPARAM(0, scroll_amount), 0);
}

TEST(MockWindow, MouseLeave) {
  MockWindow window;
  const double mouse_x = 10.0;
  const double mouse_y = 20.0;

  EXPECT_CALL(window, OnPointerMove(mouse_x, mouse_y,
                                    kFlutterPointerDeviceKindMouse, 0))
      .Times(1);
  EXPECT_CALL(window, OnPointerLeave(mouse_x, mouse_y,
                                     kFlutterPointerDeviceKindMouse, 0))
      .Times(1);

  window.InjectWindowMessage(WM_MOUSEMOVE, 0, MAKELPARAM(mouse_x, mouse_y));
  window.InjectWindowMessage(WM_MOUSELEAVE, 0, 0);
}

TEST(MockWindow, KeyDown) {
  MockWindow window;
  EXPECT_CALL(window, OnKey(_, _, _, _, _, _, _)).Times(1);
  LPARAM lparam = CreateKeyEventLparam(42, false, false);
  // send a "Shift" key down event.
  window.InjectWindowMessage(WM_KEYDOWN, 16, lparam);
}

TEST(MockWindow, KeyUp) {
  MockWindow window;
  EXPECT_CALL(window, OnKey(_, _, _, _, _, _, _)).Times(1);
  LPARAM lparam = CreateKeyEventLparam(42, false, true);
  // send a "Shift" key up event.
  window.InjectWindowMessage(WM_KEYUP, 16, lparam);
}

TEST(MockWindow, SysKeyDown) {
  MockWindow window;
  EXPECT_CALL(window, OnKey(_, _, _, _, _, _, _)).Times(1);
  LPARAM lparam = CreateKeyEventLparam(42, false, false);
  // send a "Shift" key down event.
  window.InjectWindowMessage(WM_SYSKEYDOWN, 16, lparam);
}

TEST(MockWindow, SysKeyUp) {
  MockWindow window;
  EXPECT_CALL(window, OnKey(_, _, _, _, _, _, _)).Times(1);
  LPARAM lparam = CreateKeyEventLparam(42, false, true);
  // send a "Shift" key up event.
  window.InjectWindowMessage(WM_SYSKEYUP, 16, lparam);
}

TEST(MockWindow, KeyDownPrintable) {
  MockWindow window;
  LPARAM lparam = CreateKeyEventLparam(30, false, false);

  auto respond_false = [](int key, int scancode, int action, char32_t character,
                          bool extended, bool was_down,
                          std::function<void(bool)> callback) {
    callback(false);
  };
  EXPECT_CALL(window, OnKey(65, 30, WM_KEYDOWN, 0, false, false, _))
      .Times(1)
      .WillOnce(respond_false);
  EXPECT_CALL(window, OnText(_)).Times(1);
  Win32Message messages[] = {{WM_KEYDOWN, 65, lparam, kWmResultDontCheck},
                             {WM_CHAR, 65, lparam, kWmResultDontCheck}};
  window.InjectMessageList(2, messages);
}

TEST(MockWindow, KeyDownWithCtrl) {
  MockWindow window;

  // Simulate CONTROL pressed
  BYTE keyboard_state[256];
  memset(keyboard_state, 0, 256);
  keyboard_state[VK_CONTROL] = -1;
  SetKeyboardState(keyboard_state);

  LPARAM lparam = CreateKeyEventLparam(30, false, false);

  // Expect OnKey, but not OnText, because Control + Key is not followed by
  // WM_CHAR
  EXPECT_CALL(window, OnKey(65, 30, WM_KEYDOWN, 0, false, false, _)).Times(1);
  EXPECT_CALL(window, OnText(_)).Times(0);

  window.InjectWindowMessage(WM_KEYDOWN, 65, lparam);

  memset(keyboard_state, 0, 256);
  SetKeyboardState(keyboard_state);
}

TEST(MockWindow, KeyDownWithCtrlToggled) {
  MockWindow window;

  auto respond_false = [](int key, int scancode, int action, char32_t character,
                          bool extended, bool was_down,
                          std::function<void(bool)> callback) {
    callback(false);
  };

  // Simulate CONTROL toggled
  BYTE keyboard_state[256];
  memset(keyboard_state, 0, 256);
  keyboard_state[VK_CONTROL] = 1;
  SetKeyboardState(keyboard_state);

  LPARAM lparam = CreateKeyEventLparam(30, false, false);

  EXPECT_CALL(window, OnKey(65, 30, WM_KEYDOWN, 0, false, false, _))
      .Times(1)
      .WillOnce(respond_false);
  EXPECT_CALL(window, OnText(_)).Times(1);

  // send a "A" key down event.
  Win32Message messages[] = {{WM_KEYDOWN, 65, lparam, kWmResultDontCheck},
                             {WM_CHAR, 65, lparam, kWmResultDontCheck}};
  window.InjectMessageList(2, messages);

  memset(keyboard_state, 0, 256);
  SetKeyboardState(keyboard_state);
}

TEST(MockWindow, Paint) {
  MockWindow window;
  EXPECT_CALL(window, OnPaint()).Times(1);
  window.InjectWindowMessage(WM_PAINT, 0, 0);
}

}  // namespace testing
}  // namespace flutter
