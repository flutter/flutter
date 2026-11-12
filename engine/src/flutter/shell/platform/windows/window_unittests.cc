// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <array>

#include "flutter/shell/platform/windows/testing/mock_direct_manipulation.h"
#include "flutter/shell/platform/windows/testing/mock_text_input_manager.h"
#include "flutter/shell/platform/windows/testing/mock_window.h"
#include "flutter/shell/platform/windows/testing/mock_windows_proc_table.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

using testing::_;
using testing::Eq;
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

TEST(MockWindow, DirectManipulationDoesNotCreateAnIdleTimer) {
  auto windows_proc_table =
      std::make_unique<::testing::StrictMock<MockWindowsProcTable>>();
  EXPECT_CALL(*windows_proc_table, SetTimer(_, _, _, _)).Times(0);
  EXPECT_CALL(*windows_proc_table, KillTimer(_, _)).Times(0);
  MockWindow window(std::move(windows_proc_table), nullptr);
  ASSERT_NE(window.GetWindowHandle(), nullptr);
}

// Exercise interaction callbacks and timer message dispatch with mocked timer
// calls. The strict mock also rejects timer calls during window creation.
class DirectManipulationPollingTest : public ::testing::Test {
 protected:
  void SetUp() override {
    ASSERT_NE(window_.GetWindowHandle(), nullptr);
    auto owner = std::make_unique<MockDirectManipulationOwner>(&window_);
    owner_ = owner.get();
    handler_ = fml::MakeRefCounted<DirectManipulationEventHandler>(owner_);
    window_.SetDirectManipulationOwner(std::move(owner));
  }

  void Interact(DIRECTMANIPULATION_INTERACTION_TYPE interaction) {
    EXPECT_EQ(handler_->OnInteraction(nullptr, interaction), S_OK);
  }

  // The timer ID is part of FlutterWindow's WM_TIMER dispatch contract.
  static constexpr UINT_PTR kTimerId = 1;
  MockWindowsProcTable* windows_proc_table_ = nullptr;
  MockWindow window_{CreateWindowsProcTable(), nullptr};
  MockDirectManipulationOwner* owner_ = nullptr;
  fml::RefPtr<DirectManipulationEventHandler> handler_;

 private:
  std::unique_ptr<WindowsProcTable> CreateWindowsProcTable() {
    auto windows_proc_table =
        std::make_unique<::testing::StrictMock<MockWindowsProcTable>>();
    windows_proc_table_ = windows_proc_table.get();
    return windows_proc_table;
  }
};

TEST_F(DirectManipulationPollingTest, InitiallyIdleHasNoTimer) {
  EXPECT_CALL(*windows_proc_table_, SetTimer(_, _, _, _)).Times(0);
  EXPECT_CALL(*windows_proc_table_, KillTimer(_, _)).Times(0);
  EXPECT_CALL(*owner_, Update()).Times(0);
  window_.InjectWindowMessage(WM_TIMER, kTimerId, 0);
}

TEST_F(DirectManipulationPollingTest,
       DispatchesUpdatesOnlyDuringAnInteraction) {
  EXPECT_CALL(*windows_proc_table_,
              SetTimer(window_.GetWindowHandle(), kTimerId, 14, nullptr))
      .WillOnce(Return(UINT_PTR{1}));
  Interact(DIRECTMANIPULATION_INTERACTION_BEGIN);
  Interact(DIRECTMANIPULATION_INTERACTION_BEGIN);
  EXPECT_CALL(*owner_, Update()).Times(1);
  window_.InjectWindowMessage(WM_TIMER, kTimerId, 0);
  ASSERT_TRUE(::testing::Mock::VerifyAndClearExpectations(owner_));

  EXPECT_CALL(*owner_, Update()).Times(1);
  Interact(DIRECTMANIPULATION_INTERACTION_TYPE_MANIPULATION);
  window_.InjectWindowMessage(WM_TIMER, kTimerId, 0);
  ASSERT_TRUE(::testing::Mock::VerifyAndClearExpectations(owner_));

  EXPECT_CALL(*owner_, Update()).Times(0);
  EXPECT_CALL(*windows_proc_table_,
              KillTimer(window_.GetWindowHandle(), kTimerId))
      .WillOnce(Return(TRUE));
  Interact(DIRECTMANIPULATION_INTERACTION_END);
  ASSERT_TRUE(::testing::Mock::VerifyAndClearExpectations(windows_proc_table_));
  window_.InjectWindowMessage(WM_TIMER, kTimerId, 0);

  Interact(DIRECTMANIPULATION_INTERACTION_END);
  // KillTimer does not remove WM_TIMER messages that were already queued.
  window_.InjectWindowMessage(WM_TIMER, kTimerId, 0);
}

TEST_F(DirectManipulationPollingTest, CanStartAnotherInteraction) {
  InSequence sequence;
  for (int i = 0; i < 2; ++i) {
    EXPECT_CALL(*windows_proc_table_,
                SetTimer(window_.GetWindowHandle(), kTimerId, 14, nullptr))
        .WillOnce(Return(UINT_PTR{1}));
    EXPECT_CALL(*windows_proc_table_,
                KillTimer(window_.GetWindowHandle(), kTimerId))
        .WillOnce(Return(TRUE));
    Interact(DIRECTMANIPULATION_INTERACTION_BEGIN);
    Interact(DIRECTMANIPULATION_INTERACTION_END);
    ASSERT_TRUE(
        ::testing::Mock::VerifyAndClearExpectations(windows_proc_table_));
  }
}

TEST_F(DirectManipulationPollingTest,
       FailedTimerCreationDoesNotPollAndCanRetry) {
  EXPECT_CALL(*windows_proc_table_,
              SetTimer(window_.GetWindowHandle(), kTimerId, 14, nullptr))
      .WillOnce(Return(UINT_PTR{0}));
  EXPECT_CALL(*owner_, Update()).Times(0);
  Interact(DIRECTMANIPULATION_INTERACTION_BEGIN);
  window_.InjectWindowMessage(WM_TIMER, kTimerId, 0);
  Interact(DIRECTMANIPULATION_INTERACTION_END);
  ASSERT_TRUE(::testing::Mock::VerifyAndClearExpectations(windows_proc_table_));
  ASSERT_TRUE(::testing::Mock::VerifyAndClearExpectations(owner_));

  EXPECT_CALL(*windows_proc_table_,
              SetTimer(window_.GetWindowHandle(), kTimerId, 14, nullptr))
      .WillOnce(Return(UINT_PTR{1}));
  EXPECT_CALL(*owner_, Update()).Times(1);
  Interact(DIRECTMANIPULATION_INTERACTION_BEGIN);
  window_.InjectWindowMessage(WM_TIMER, kTimerId, 0);
  ASSERT_TRUE(::testing::Mock::VerifyAndClearExpectations(owner_));

  EXPECT_CALL(*owner_, Update()).Times(0);
  EXPECT_CALL(*windows_proc_table_,
              KillTimer(window_.GetWindowHandle(), kTimerId))
      .WillOnce(Return(TRUE));
  Interact(DIRECTMANIPULATION_INTERACTION_END);
  ASSERT_TRUE(::testing::Mock::VerifyAndClearExpectations(windows_proc_table_));
  window_.InjectWindowMessage(WM_TIMER, kTimerId, 0);
}

TEST_F(DirectManipulationPollingTest,
       ManipulationAndUnmatchedEndDoNotStartPolling) {
  EXPECT_CALL(*windows_proc_table_, SetTimer(_, _, _, _)).Times(0);
  EXPECT_CALL(*windows_proc_table_, KillTimer(_, _)).Times(0);
  EXPECT_CALL(*owner_, Update()).Times(0);
  Interact(DIRECTMANIPULATION_INTERACTION_TYPE_MANIPULATION);
  window_.InjectWindowMessage(WM_TIMER, kTimerId, 0);

  Interact(DIRECTMANIPULATION_INTERACTION_END);
  window_.InjectWindowMessage(WM_TIMER, kTimerId, 0);
}

TEST_F(DirectManipulationPollingTest, UnrelatedTimerDoesNotPoll) {
  EXPECT_CALL(*windows_proc_table_,
              SetTimer(window_.GetWindowHandle(), kTimerId, 14, nullptr))
      .WillOnce(Return(UINT_PTR{1}));
  EXPECT_CALL(*windows_proc_table_,
              KillTimer(window_.GetWindowHandle(), kTimerId))
      .WillOnce(Return(TRUE));
  Interact(DIRECTMANIPULATION_INTERACTION_BEGIN);
  EXPECT_CALL(*owner_, Update()).Times(0);
  window_.InjectWindowMessage(WM_TIMER, kTimerId + 1, 0);
  Interact(DIRECTMANIPULATION_INTERACTION_END);
  ASSERT_TRUE(::testing::Mock::VerifyAndClearExpectations(windows_proc_table_));
}

TEST_F(DirectManipulationPollingTest,
       ParentVisibilityChangesDoNotStartPolling) {
  HWND parent =
      CreateWindowEx(0, L"STATIC", L"", WS_OVERLAPPED, 0, 0, 100, 100, nullptr,
                     nullptr, GetModuleHandle(nullptr), nullptr);
  ASSERT_NE(parent, nullptr);
  HWND child = window_.GetWindowHandle();
  SetParent(child, parent);
  EXPECT_EQ(GetParent(child), parent);
  EXPECT_FALSE(IsWindowVisible(child));

  ShowWindow(parent, SW_SHOWNOACTIVATE);
  EXPECT_TRUE(IsWindowVisible(child));
  ShowWindow(parent, SW_HIDE);
  EXPECT_FALSE(IsWindowVisible(child));
  ShowWindow(parent, SW_SHOWNOACTIVATE);
  EXPECT_TRUE(IsWindowVisible(child));

  EXPECT_CALL(*windows_proc_table_, SetTimer(child, kTimerId, 14, nullptr))
      .WillOnce(Return(UINT_PTR{1}));
  EXPECT_CALL(*windows_proc_table_, KillTimer(child, kTimerId))
      .WillOnce(Return(TRUE));
  Interact(DIRECTMANIPULATION_INTERACTION_BEGIN);
  Interact(DIRECTMANIPULATION_INTERACTION_END);
  EXPECT_TRUE(::testing::Mock::VerifyAndClearExpectations(windows_proc_table_));
  SetParent(child, HWND_MESSAGE);
  DestroyWindow(parent);
}

TEST_F(DirectManipulationPollingTest,
       OwnerShutdownStopsPollingAndPreventsRestart) {
  EXPECT_CALL(*windows_proc_table_,
              SetTimer(window_.GetWindowHandle(), kTimerId, 14, nullptr))
      .WillOnce(Return(UINT_PTR{1}));
  Interact(DIRECTMANIPULATION_INTERACTION_BEGIN);
  EXPECT_CALL(*windows_proc_table_,
              KillTimer(window_.GetWindowHandle(), kTimerId))
      .WillOnce(Return(TRUE));
  owner_->Destroy();
  ASSERT_TRUE(::testing::Mock::VerifyAndClearExpectations(windows_proc_table_));
  EXPECT_CALL(*owner_, Update()).Times(0);
  window_.InjectWindowMessage(WM_TIMER, kTimerId, 0);
  // This separately constructed handler still references the live owner, but
  // the owner must no longer forward requests after releasing its OS resources.
  Interact(DIRECTMANIPULATION_INTERACTION_BEGIN);
}

TEST(MockWindow, StopsPollingAndShutsDownOwnerBeforeDestroyingWindow) {
  class CheckingOwner : public MockDirectManipulationOwner {
   public:
    CheckingOwner(FlutterWindow* window,
                  MockWindowsProcTable* windows_proc_table)
        : MockDirectManipulationOwner(window),
          hwnd_(window->GetWindowHandle()),
          windows_proc_table_(windows_proc_table) {}

    ~CheckingOwner() override {
      EXPECT_TRUE(IsWindow(hwnd_));
      // Verify that KillTimer was called before destroying the owner.
      EXPECT_TRUE(
          ::testing::Mock::VerifyAndClearExpectations(windows_proc_table_));
      // Destroy must also sever the owner's link to the still-live window.
      // The strict mock rejects any timer calls after verification.
      SetNeedsUpdate(true);
    }

   private:
    HWND hwnd_;
    MockWindowsProcTable* windows_proc_table_;
  };

  auto windows_proc_table =
      std::make_unique<::testing::StrictMock<MockWindowsProcTable>>();
  auto* proc_table = windows_proc_table.get();
  MockWindow window(std::move(windows_proc_table), nullptr);
  ASSERT_NE(window.GetWindowHandle(), nullptr);
  auto owner = std::make_unique<CheckingOwner>(&window, proc_table);
  EXPECT_CALL(*proc_table, SetTimer(window.GetWindowHandle(), 1, 14, nullptr))
      .WillOnce(Return(UINT_PTR{1}));
  EXPECT_CALL(*owner, Update()).Times(1);
  auto* owner_ptr = owner.get();
  window.SetDirectManipulationOwner(std::move(owner));
  window.SetDirectManipulationNeedsUpdate(true);
  window.InjectWindowMessage(WM_TIMER, 1, 0);
  ASSERT_TRUE(::testing::Mock::VerifyAndClearExpectations(owner_ptr));
  EXPECT_CALL(*owner_ptr, Update()).Times(0);
  EXPECT_CALL(*proc_table, KillTimer(window.GetWindowHandle(), 1))
      .WillOnce(Return(TRUE));
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
  auto windows_proc_table = std::make_unique<MockWindowsProcTable>();
  auto* text_input_manager = new MockTextInputManager();
  std::unique_ptr<TextInputManager> text_input_manager_ptr(text_input_manager);
  MockWindow window(std::move(windows_proc_table),
                    std::move(text_input_manager_ptr));
  EXPECT_CALL(*text_input_manager, GetComposingString())
      .WillRepeatedly(
          Return(std::optional<std::u16string>(std::u16string(u"nihao"))));
  EXPECT_CALL(*text_input_manager, GetResultString())
      .WillRepeatedly(
          Return(std::optional<std::u16string>(std::u16string(u"`}"))));
  EXPECT_CALL(*text_input_manager, GetComposingCursorPosition()).Times(0);

  EXPECT_CALL(window, OnComposeChange(std::u16string(u"nihao"), 5)).Times(1);
  EXPECT_CALL(window, OnComposeChange(std::u16string(u"`}"), 0)).Times(0);
  EXPECT_CALL(window, OnComposeCommit()).Times(0);
  ON_CALL(window, OnImeComposition)
      .WillByDefault(Invoke(&window, &MockWindow::CallOnImeComposition));
  EXPECT_CALL(window, OnImeComposition(_, _, _)).Times(1);

  // Send an IME_COMPOSITION event that contains just the composition string.
  window.InjectWindowMessage(WM_IME_COMPOSITION, 0, GCS_COMPSTR);
}

// Regression test for https://github.com/flutter/flutter/issues/140739.
TEST(MockWindow, OnImeCompositionDefaultsKoreanCursorToCompositionEnd) {
  auto windows_proc_table = std::make_unique<MockWindowsProcTable>();
  auto* text_input_manager = new MockTextInputManager();
  std::unique_ptr<TextInputManager> text_input_manager_ptr(text_input_manager);
  MockWindow window(std::move(windows_proc_table),
                    std::move(text_input_manager_ptr));
  EXPECT_CALL(*text_input_manager, GetComposingString())
      .WillRepeatedly(
          Return(std::optional<std::u16string>(std::u16string(u"다"))));
  EXPECT_CALL(*text_input_manager, GetComposingCursorPosition()).Times(0);

  EXPECT_CALL(window, OnComposeChange(std::u16string(u"다"), 1)).Times(1);
  EXPECT_CALL(window, OnComposeCommit()).Times(0);
  ON_CALL(window, OnImeComposition)
      .WillByDefault(Invoke(&window, &MockWindow::CallOnImeComposition));
  EXPECT_CALL(window, OnImeComposition(_, _, _)).Times(1);

  window.InjectWindowMessage(WM_IME_COMPOSITION, 0, GCS_COMPSTR);
}

TEST(MockWindow, OnImeCompositionResult) {
  auto windows_proc_table = std::make_unique<MockWindowsProcTable>();
  auto* text_input_manager = new MockTextInputManager();
  std::unique_ptr<TextInputManager> text_input_manager_ptr(text_input_manager);
  MockWindow window(std::move(windows_proc_table),
                    std::move(text_input_manager_ptr));
  EXPECT_CALL(*text_input_manager, GetComposingString())
      .WillRepeatedly(
          Return(std::optional<std::u16string>(std::u16string(u"nihao"))));
  EXPECT_CALL(*text_input_manager, GetResultString())
      .WillRepeatedly(
          Return(std::optional<std::u16string>(std::u16string(u"`}"))));
  EXPECT_CALL(*text_input_manager, GetComposingCursorPosition()).Times(0);

  EXPECT_CALL(window, OnComposeChange(std::u16string(u"nihao"), 0)).Times(0);
  EXPECT_CALL(window, OnComposeChange(std::u16string(u"`}"), 2)).Times(1);
  EXPECT_CALL(window, OnComposeCommit()).Times(1);
  ON_CALL(window, OnImeComposition)
      .WillByDefault(Invoke(&window, &MockWindow::CallOnImeComposition));
  EXPECT_CALL(window, OnImeComposition(_, _, _)).Times(1);

  // Send an IME_COMPOSITION event that contains just the result string.
  window.InjectWindowMessage(WM_IME_COMPOSITION, 0, GCS_RESULTSTR);
}

TEST(MockWindow, OnImeCompositionResultAndCompose) {
  auto windows_proc_table = std::make_unique<MockWindowsProcTable>();
  auto* text_input_manager = new MockTextInputManager();
  std::unique_ptr<TextInputManager> text_input_manager_ptr(text_input_manager);
  MockWindow window(std::move(windows_proc_table),
                    std::move(text_input_manager_ptr));

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
    EXPECT_CALL(window, OnComposeChange(std::u16string(u"今日"), 2)).Times(1);
    EXPECT_CALL(window, OnComposeCommit()).Times(1);
    EXPECT_CALL(window, OnComposeChange(std::u16string(u"は"), 1)).Times(1);
  }

  EXPECT_CALL(*text_input_manager, GetComposingCursorPosition()).Times(0);

  ON_CALL(window, OnImeComposition)
      .WillByDefault(Invoke(&window, &MockWindow::CallOnImeComposition));
  EXPECT_CALL(window, OnImeComposition(_, _, _)).Times(1);

  // send an IME_COMPOSITION event that contains both the result string and the
  // composition string.
  window.InjectWindowMessage(WM_IME_COMPOSITION, 0,
                             GCS_COMPSTR | GCS_RESULTSTR);
}

TEST(MockWindow, OnImeCompositionUsesCursorPositionWhenProvided) {
  auto windows_proc_table = std::make_unique<MockWindowsProcTable>();
  auto* text_input_manager = new MockTextInputManager();
  std::unique_ptr<TextInputManager> text_input_manager_ptr(text_input_manager);
  MockWindow window(std::move(windows_proc_table),
                    std::move(text_input_manager_ptr));
  EXPECT_CALL(*text_input_manager, GetComposingString())
      .WillRepeatedly(
          Return(std::optional<std::u16string>(std::u16string(u"nihao"))));
  EXPECT_CALL(*text_input_manager, GetComposingCursorPosition())
      .WillOnce(Return(2));

  EXPECT_CALL(window, OnComposeChange(std::u16string(u"nihao"), 2)).Times(1);
  EXPECT_CALL(window, OnComposeCommit()).Times(0);
  ON_CALL(window, OnImeComposition)
      .WillByDefault(Invoke(&window, &MockWindow::CallOnImeComposition));
  EXPECT_CALL(window, OnImeComposition(_, _, _)).Times(1);

  window.InjectWindowMessage(WM_IME_COMPOSITION, 0,
                             GCS_COMPSTR | GCS_CURSORPOS);
}

TEST(MockWindow, OnImeCompositionFallsBackToTextEndForInvalidCursorPosition) {
  auto windows_proc_table = std::make_unique<MockWindowsProcTable>();
  auto* text_input_manager = new MockTextInputManager();
  std::unique_ptr<TextInputManager> text_input_manager_ptr(text_input_manager);
  MockWindow window(std::move(windows_proc_table),
                    std::move(text_input_manager_ptr));
  EXPECT_CALL(*text_input_manager, GetComposingString())
      .WillRepeatedly(
          Return(std::optional<std::u16string>(std::u16string(u"nihao"))));
  EXPECT_CALL(*text_input_manager, GetComposingCursorPosition())
      .WillOnce(Return(-1));

  EXPECT_CALL(window, OnComposeChange(std::u16string(u"nihao"), 5)).Times(1);
  EXPECT_CALL(window, OnComposeCommit()).Times(0);
  ON_CALL(window, OnImeComposition)
      .WillByDefault(Invoke(&window, &MockWindow::CallOnImeComposition));
  EXPECT_CALL(window, OnImeComposition(_, _, _)).Times(1);

  window.InjectWindowMessage(WM_IME_COMPOSITION, 0,
                             GCS_COMPSTR | GCS_CURSORPOS);
}

TEST(MockWindow, OnImeCompositionClearChange) {
  auto windows_proc_table = std::make_unique<MockWindowsProcTable>();
  auto* text_input_manager = new MockTextInputManager();
  std::unique_ptr<TextInputManager> text_input_manager_ptr(text_input_manager);
  MockWindow window(std::move(windows_proc_table),
                    std::move(text_input_manager_ptr));
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

  EXPECT_CALL(window,
              OnPointerMove(mouse_x, mouse_y, kFlutterPointerDeviceKindMouse, 0,
                            0, 0, 0, 0))
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
  // Prevent default proc for WM_SYSKEYUP which unfocuses the window and sends
  // WM_MOUSELEAVE.
  EXPECT_CALL(window, Win32DefWindowProc(_, _, _, _)).Times(0);
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
  std::array<Win32Message, 2> messages = {
      Win32Message{WM_KEYDOWN, 65, lparam, kWmResultDontCheck},
      Win32Message{WM_CHAR, 65, lparam, kWmResultDontCheck}};
  window.InjectMessageList(2, messages.data());
}

TEST(MockWindow, KeyDownWithCtrl) {
  MockWindow window;

  // Simulate CONTROL pressed
  std::array<BYTE, 256> keyboard_state;
  keyboard_state[VK_CONTROL] = -1;
  SetKeyboardState(keyboard_state.data());

  LPARAM lparam = CreateKeyEventLparam(30, false, false);

  // Expect OnKey, but not OnText, because Control + Key is not followed by
  // WM_CHAR
  EXPECT_CALL(window, OnKey(65, 30, WM_KEYDOWN, 0, false, false, _)).Times(1);
  EXPECT_CALL(window, OnText(_)).Times(0);

  window.InjectWindowMessage(WM_KEYDOWN, 65, lparam);

  keyboard_state.fill(0);
  SetKeyboardState(keyboard_state.data());
}

TEST(MockWindow, KeyDownWithCtrlToggled) {
  MockWindow window;

  auto respond_false = [](int key, int scancode, int action, char32_t character,
                          bool extended, bool was_down,
                          std::function<void(bool)> callback) {
    callback(false);
  };

  // Simulate CONTROL toggled
  std::array<BYTE, 256> keyboard_state;
  keyboard_state[VK_CONTROL] = 1;
  SetKeyboardState(keyboard_state.data());

  LPARAM lparam = CreateKeyEventLparam(30, false, false);

  EXPECT_CALL(window, OnKey(65, 30, WM_KEYDOWN, 0, false, false, _))
      .Times(1)
      .WillOnce(respond_false);
  EXPECT_CALL(window, OnText(_)).Times(1);

  // send a "A" key down event.
  Win32Message messages[] = {{WM_KEYDOWN, 65, lparam, kWmResultDontCheck},
                             {WM_CHAR, 65, lparam, kWmResultDontCheck}};
  window.InjectMessageList(2, messages);

  keyboard_state.fill(0);
  SetKeyboardState(keyboard_state.data());
}

TEST(MockWindow, Paint) {
  MockWindow window;
  EXPECT_CALL(window, OnPaint()).Times(1);
  window.InjectWindowMessage(WM_PAINT, 0, 0);
}

// Verify direct manipulation isn't notified of pointer hit tests.
TEST(MockWindow, PointerHitTest) {
  UINT32 pointer_id = 123;
  auto windows_proc_table = std::make_unique<MockWindowsProcTable>();
  auto text_input_manager = std::make_unique<MockTextInputManager>();

  EXPECT_CALL(*windows_proc_table, GetPointerType(Eq(pointer_id), _))
      .Times(1)
      .WillOnce([](UINT32 pointer_id, POINTER_INPUT_TYPE* type) {
        *type = PT_POINTER;
        return TRUE;
      });

  MockWindow window(std::move(windows_proc_table),
                    std::move(text_input_manager));

  auto direct_manipulation =
      std::make_unique<MockDirectManipulationOwner>(&window);

  EXPECT_CALL(*direct_manipulation, SetContact).Times(0);

  window.SetDirectManipulationOwner(std::move(direct_manipulation));
  window.InjectWindowMessage(DM_POINTERHITTEST, MAKEWPARAM(pointer_id, 0), 0);
}

// Verify direct manipulation is notified of touchpad hit tests.
TEST(MockWindow, TouchPadHitTest) {
  UINT32 pointer_id = 123;
  auto windows_proc_table = std::make_unique<MockWindowsProcTable>();
  auto text_input_manager = std::make_unique<MockTextInputManager>();

  EXPECT_CALL(*windows_proc_table, GetPointerType(Eq(pointer_id), _))
      .Times(1)
      .WillOnce([](UINT32 pointer_id, POINTER_INPUT_TYPE* type) {
        *type = PT_TOUCHPAD;
        return TRUE;
      });

  MockWindow window(std::move(windows_proc_table),
                    std::move(text_input_manager));

  auto direct_manipulation =
      std::make_unique<MockDirectManipulationOwner>(&window);

  EXPECT_CALL(*direct_manipulation, SetContact(Eq(pointer_id))).Times(1);

  window.SetDirectManipulationOwner(std::move(direct_manipulation));
  window.InjectWindowMessage(DM_POINTERHITTEST, MAKEWPARAM(pointer_id, 0), 0);
}

// Verify direct manipulation isn't notified of unknown hit tests.
// This can happen if determining the pointer type fails, for example,
// if GetPointerType is unsupported by the current Windows version.
// See: https://github.com/flutter/flutter/issues/109412
TEST(MockWindow, UnknownPointerTypeSkipsDirectManipulation) {
  UINT32 pointer_id = 123;
  auto windows_proc_table = std::make_unique<MockWindowsProcTable>();
  auto text_input_manager = std::make_unique<MockTextInputManager>();

  EXPECT_CALL(*windows_proc_table, GetPointerType(Eq(pointer_id), _))
      .Times(1)
      .WillOnce(
          [](UINT32 pointer_id, POINTER_INPUT_TYPE* type) { return FALSE; });

  MockWindow window(std::move(windows_proc_table),
                    std::move(text_input_manager));

  auto direct_manipulation =
      std::make_unique<MockDirectManipulationOwner>(&window);

  EXPECT_CALL(*direct_manipulation, SetContact).Times(0);

  window.SetDirectManipulationOwner(std::move(direct_manipulation));
  window.InjectWindowMessage(DM_POINTERHITTEST, MAKEWPARAM(pointer_id, 0), 0);
}

// Test that the root UIA object is queried by WM_GETOBJECT.
TEST(MockWindow, DISABLED_GetObjectUia) {
  MockWindow window;
  bool uia_called = false;
  ON_CALL(window, OnGetObject)
      .WillByDefault([&uia_called](UINT msg, WPARAM wpar, LPARAM lpar) {
#ifdef FLUTTER_ENGINE_USE_UIA
        uia_called = true;
#endif  // FLUTTER_ENGINE_USE_UIA
        return static_cast<LRESULT>(0);
      });
  EXPECT_CALL(window, OnGetObject).Times(1);

  window.InjectWindowMessage(WM_GETOBJECT, 0, UiaRootObjectId);

  EXPECT_TRUE(uia_called);
}

}  // namespace testing
}  // namespace flutter
