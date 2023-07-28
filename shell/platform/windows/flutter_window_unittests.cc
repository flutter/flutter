// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/windows/testing/flutter_window_test.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler_delegate.h"
#include "flutter/shell/platform/windows/testing/wm_builders.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

using testing::_;
using testing::Invoke;
using testing::Return;

namespace flutter {
namespace testing {

namespace {
static constexpr int32_t kDefaultPointerDeviceId = 0;

class MockFlutterWindow : public FlutterWindow {
 public:
  MockFlutterWindow() : FlutterWindow(800, 600) {
    ON_CALL(*this, GetDpiScale())
        .WillByDefault(Return(this->FlutterWindow::GetDpiScale()));
  }
  virtual ~MockFlutterWindow() { SetView(nullptr); }

  // Wrapper for GetCurrentDPI() which is a protected method.
  UINT GetDpi() { return GetCurrentDPI(); }

  // Simulates a WindowProc message from the OS.
  LRESULT InjectWindowMessage(UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) {
    return HandleMessage(message, wparam, lparam);
  }

  MOCK_METHOD1(OnDpiScale, void(unsigned int));
  MOCK_METHOD2(OnResize, void(unsigned int, unsigned int));
  MOCK_METHOD4(OnPointerMove,
               void(double, double, FlutterPointerDeviceKind, int32_t));
  MOCK_METHOD5(OnPointerDown,
               void(double, double, FlutterPointerDeviceKind, int32_t, UINT));
  MOCK_METHOD5(OnPointerUp,
               void(double, double, FlutterPointerDeviceKind, int32_t, UINT));
  MOCK_METHOD4(OnPointerLeave,
               void(double, double, FlutterPointerDeviceKind, int32_t));
  MOCK_METHOD0(OnSetCursor, void());
  MOCK_METHOD0(GetScrollOffsetMultiplier, float());
  MOCK_METHOD0(GetHighContrastEnabled, bool());
  MOCK_METHOD0(GetDpiScale, float());
  MOCK_METHOD0(IsVisible, bool());
  MOCK_METHOD1(UpdateCursorRect, void(const Rect&));
  MOCK_METHOD0(OnResetImeComposing, void());
  MOCK_METHOD3(Win32DispatchMessage, UINT(UINT, WPARAM, LPARAM));
  MOCK_METHOD4(Win32PeekMessage, BOOL(LPMSG, UINT, UINT, UINT));
  MOCK_METHOD1(Win32MapVkToChar, uint32_t(uint32_t));
  MOCK_METHOD0(GetPlatformWindow, HWND());
  MOCK_METHOD0(GetAxFragmentRootDelegate, ui::AXFragmentRootDelegateWin*());

 protected:
  // |KeyboardManager::WindowDelegate|
  LRESULT Win32DefWindowProc(HWND hWnd,
                             UINT Msg,
                             WPARAM wParam,
                             LPARAM lParam) override {
    return kWmResultDefault;
  }

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(MockFlutterWindow);
};

class MockFlutterWindowsView : public FlutterWindowsView {
 public:
  MockFlutterWindowsView(std::unique_ptr<WindowBindingHandler> window_binding)
      : FlutterWindowsView(std::move(window_binding)) {}
  ~MockFlutterWindowsView() {}

  MOCK_METHOD2(NotifyWinEventWrapper,
               void(ui::AXPlatformNodeWin*, ax::mojom::Event));

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(MockFlutterWindowsView);
};

}  // namespace

TEST(FlutterWindowTest, CreateDestroy) {
  FlutterWindowTest window(800, 600);
  ASSERT_TRUE(TRUE);
}

TEST(FlutterWindowTest, OnBitmapSurfaceUpdated) {
  FlutterWindow win32window(100, 100);
  int old_handle_count = GetGuiResources(GetCurrentProcess(), GR_GDIOBJECTS);

  constexpr size_t row_bytes = 100 * 4;
  constexpr size_t height = 100;
  std::array<char, row_bytes * height> allocation;
  win32window.OnBitmapSurfaceUpdated(allocation.data(), row_bytes, height);

  int new_handle_count = GetGuiResources(GetCurrentProcess(), GR_GDIOBJECTS);
  // Check GDI resources leak
  EXPECT_EQ(old_handle_count, new_handle_count);
}

// Tests that composing rect updates are transformed from Flutter logical
// coordinates to device coordinates and passed to the text input manager
// when the DPI scale is 100% (96 DPI).
TEST(FlutterWindowTest, OnCursorRectUpdatedRegularDPI) {
  MockFlutterWindow win32window;
  ON_CALL(win32window, GetDpiScale()).WillByDefault(Return(1.0));
  EXPECT_CALL(win32window, GetDpiScale()).Times(1);

  Rect cursor_rect(Point(10, 20), Size(30, 40));
  EXPECT_CALL(win32window, UpdateCursorRect(cursor_rect)).Times(1);

  win32window.OnCursorRectUpdated(cursor_rect);
}

// Tests that composing rect updates are transformed from Flutter logical
// coordinates to device coordinates and passed to the text input manager
// when the DPI scale is 150% (144 DPI).
TEST(FlutterWindowTest, OnCursorRectUpdatedHighDPI) {
  MockFlutterWindow win32window;
  ON_CALL(win32window, GetDpiScale()).WillByDefault(Return(1.5));
  EXPECT_CALL(win32window, GetDpiScale()).Times(1);

  Rect expected_cursor_rect(Point(15, 30), Size(45, 60));
  EXPECT_CALL(win32window, UpdateCursorRect(expected_cursor_rect)).Times(1);

  Rect cursor_rect(Point(10, 20), Size(30, 40));
  win32window.OnCursorRectUpdated(cursor_rect);
}

TEST(FlutterWindowTest, OnPointerStarSendsDeviceType) {
  FlutterWindow win32window(100, 100);
  MockWindowBindingHandlerDelegate delegate;
  win32window.SetView(&delegate);
  // Move
  EXPECT_CALL(delegate,
              OnPointerMove(10.0, 10.0, kFlutterPointerDeviceKindMouse,
                            kDefaultPointerDeviceId, 0))
      .Times(1);
  EXPECT_CALL(delegate,
              OnPointerMove(10.0, 10.0, kFlutterPointerDeviceKindTouch,
                            kDefaultPointerDeviceId, 0))
      .Times(1);
  EXPECT_CALL(delegate,
              OnPointerMove(10.0, 10.0, kFlutterPointerDeviceKindStylus,
                            kDefaultPointerDeviceId, 0))
      .Times(1);

  // Down
  EXPECT_CALL(
      delegate,
      OnPointerDown(10.0, 10.0, kFlutterPointerDeviceKindMouse,
                    kDefaultPointerDeviceId, kFlutterPointerButtonMousePrimary))
      .Times(1);
  EXPECT_CALL(
      delegate,
      OnPointerDown(10.0, 10.0, kFlutterPointerDeviceKindTouch,
                    kDefaultPointerDeviceId, kFlutterPointerButtonMousePrimary))
      .Times(1);
  EXPECT_CALL(
      delegate,
      OnPointerDown(10.0, 10.0, kFlutterPointerDeviceKindStylus,
                    kDefaultPointerDeviceId, kFlutterPointerButtonMousePrimary))
      .Times(1);

  // Up
  EXPECT_CALL(delegate, OnPointerUp(10.0, 10.0, kFlutterPointerDeviceKindMouse,
                                    kDefaultPointerDeviceId,
                                    kFlutterPointerButtonMousePrimary))
      .Times(1);
  EXPECT_CALL(delegate, OnPointerUp(10.0, 10.0, kFlutterPointerDeviceKindTouch,
                                    kDefaultPointerDeviceId,
                                    kFlutterPointerButtonMousePrimary))
      .Times(1);
  EXPECT_CALL(delegate, OnPointerUp(10.0, 10.0, kFlutterPointerDeviceKindStylus,
                                    kDefaultPointerDeviceId,
                                    kFlutterPointerButtonMousePrimary))
      .Times(1);

  // Leave
  EXPECT_CALL(delegate,
              OnPointerLeave(10.0, 10.0, kFlutterPointerDeviceKindMouse,
                             kDefaultPointerDeviceId))
      .Times(1);
  EXPECT_CALL(delegate,
              OnPointerLeave(10.0, 10.0, kFlutterPointerDeviceKindTouch,
                             kDefaultPointerDeviceId))
      .Times(1);
  EXPECT_CALL(delegate,
              OnPointerLeave(10.0, 10.0, kFlutterPointerDeviceKindStylus,
                             kDefaultPointerDeviceId))
      .Times(1);

  win32window.OnPointerMove(10.0, 10.0, kFlutterPointerDeviceKindMouse,
                            kDefaultPointerDeviceId, 0);
  win32window.OnPointerDown(10.0, 10.0, kFlutterPointerDeviceKindMouse,
                            kDefaultPointerDeviceId, WM_LBUTTONDOWN);
  win32window.OnPointerUp(10.0, 10.0, kFlutterPointerDeviceKindMouse,
                          kDefaultPointerDeviceId, WM_LBUTTONDOWN);
  win32window.OnPointerLeave(10.0, 10.0, kFlutterPointerDeviceKindMouse,
                             kDefaultPointerDeviceId);

  // Touch
  win32window.OnPointerMove(10.0, 10.0, kFlutterPointerDeviceKindTouch,
                            kDefaultPointerDeviceId, 0);
  win32window.OnPointerDown(10.0, 10.0, kFlutterPointerDeviceKindTouch,
                            kDefaultPointerDeviceId, WM_LBUTTONDOWN);
  win32window.OnPointerUp(10.0, 10.0, kFlutterPointerDeviceKindTouch,
                          kDefaultPointerDeviceId, WM_LBUTTONDOWN);
  win32window.OnPointerLeave(10.0, 10.0, kFlutterPointerDeviceKindTouch,
                             kDefaultPointerDeviceId);

  // Pen
  win32window.OnPointerMove(10.0, 10.0, kFlutterPointerDeviceKindStylus,
                            kDefaultPointerDeviceId, 0);
  win32window.OnPointerDown(10.0, 10.0, kFlutterPointerDeviceKindStylus,
                            kDefaultPointerDeviceId, WM_LBUTTONDOWN);
  win32window.OnPointerUp(10.0, 10.0, kFlutterPointerDeviceKindStylus,
                          kDefaultPointerDeviceId, WM_LBUTTONDOWN);
  win32window.OnPointerLeave(10.0, 10.0, kFlutterPointerDeviceKindStylus,
                             kDefaultPointerDeviceId);

  // Destruction of win32window sends a HIDE update. In situ, the window is
  // owned by the delegate, and so is destructed first. Not so here.
  win32window.SetView(nullptr);
}

// Tests that calls to OnScroll in turn calls GetScrollOffsetMultiplier
// for mapping scroll ticks to pixels.
TEST(FlutterWindowTest, OnScrollCallsGetScrollOffsetMultiplier) {
  MockFlutterWindow win32window;
  MockWindowBindingHandlerDelegate delegate;
  win32window.SetView(&delegate);

  ON_CALL(win32window, GetScrollOffsetMultiplier())
      .WillByDefault(Return(120.0f));
  EXPECT_CALL(win32window, GetScrollOffsetMultiplier()).Times(1);

  EXPECT_CALL(delegate,
              OnScroll(_, _, 0, 0, 120.0f, kFlutterPointerDeviceKindMouse,
                       kDefaultPointerDeviceId))
      .Times(1);

  win32window.OnScroll(0.0f, 0.0f, kFlutterPointerDeviceKindMouse,
                       kDefaultPointerDeviceId);
}

TEST(FlutterWindowTest, OnWindowRepaint) {
  MockFlutterWindow win32window;
  MockWindowBindingHandlerDelegate delegate;
  win32window.SetView(&delegate);

  EXPECT_CALL(delegate, OnWindowRepaint()).Times(1);

  win32window.InjectWindowMessage(WM_PAINT, 0, 0);
}

TEST(FlutterWindowTest, OnThemeChange) {
  MockFlutterWindow win32window;
  MockWindowBindingHandlerDelegate delegate;
  win32window.SetView(&delegate);

  ON_CALL(win32window, GetHighContrastEnabled()).WillByDefault(Return(true));
  EXPECT_CALL(delegate, UpdateHighContrastEnabled(true)).Times(1);

  win32window.InjectWindowMessage(WM_THEMECHANGED, 0, 0);
}

// The window should return no root accessibility node if
// it isn't attached to a view.
// Regression test for https://github.com/flutter/flutter/issues/129791
TEST(FlutterWindowTest, AccessibilityNodeWithoutView) {
  MockFlutterWindow win32window;

  EXPECT_EQ(win32window.GetNativeViewAccessible(), nullptr);
}

TEST(FlutterWindowTest, InitialAccessibilityFeatures) {
  MockFlutterWindow win32window;
  MockWindowBindingHandlerDelegate delegate;
  win32window.SetView(&delegate);

  ON_CALL(win32window, GetHighContrastEnabled()).WillByDefault(Return(true));
  EXPECT_CALL(delegate, UpdateHighContrastEnabled(true)).Times(1);

  win32window.SendInitialAccessibilityFeatures();
}

// Ensure that announcing the alert propagates the message to the alert node.
// Different screen readers use different properties for alerts.
TEST(FlutterWindowTest, AlertNode) {
  std::unique_ptr<MockFlutterWindow> win32window =
      std::make_unique<MockFlutterWindow>();
  ON_CALL(*win32window, GetPlatformWindow()).WillByDefault(Return(nullptr));
  ON_CALL(*win32window, GetAxFragmentRootDelegate())
      .WillByDefault(Return(nullptr));
  MockFlutterWindowsView view(std::move(win32window));
  std::wstring message = L"Test alert";
  EXPECT_CALL(view, NotifyWinEventWrapper(_, ax::mojom::Event::kAlert))
      .Times(1);
  view.AnnounceAlert(message);

  IAccessible* alert = view.AlertNode();
  VARIANT self{.vt = VT_I4, .lVal = CHILDID_SELF};
  BSTR strptr;
  alert->get_accName(self, &strptr);
  EXPECT_EQ(message, strptr);

  alert->get_accDescription(self, &strptr);
  EXPECT_EQ(message, strptr);

  alert->get_accValue(self, &strptr);
  EXPECT_EQ(message, strptr);

  VARIANT role;
  alert->get_accRole(self, &role);
  EXPECT_EQ(role.vt, VT_I4);
  EXPECT_EQ(role.lVal, ROLE_SYSTEM_ALERT);
}

TEST(FlutterWindowTest, LifecycleFocusMessages) {
  MockFlutterWindow win32window;
  ON_CALL(win32window, GetPlatformWindow).WillByDefault([]() {
    return reinterpret_cast<HWND>(1);
  });
  MockWindowBindingHandlerDelegate delegate;
  win32window.SetView(&delegate);

  WindowStateEvent last_event;
  ON_CALL(delegate, OnWindowStateEvent)
      .WillByDefault([&last_event](HWND hwnd, WindowStateEvent event) {
        last_event = event;
      });

  win32window.InjectWindowMessage(WM_SIZE, 0, 0);
  EXPECT_EQ(last_event, WindowStateEvent::kHide);

  win32window.InjectWindowMessage(WM_SIZE, 0, MAKEWORD(1, 1));
  EXPECT_EQ(last_event, WindowStateEvent::kShow);

  win32window.InjectWindowMessage(WM_SETFOCUS, 0, 0);
  EXPECT_EQ(last_event, WindowStateEvent::kFocus);

  win32window.InjectWindowMessage(WM_KILLFOCUS, 0, 0);
  EXPECT_EQ(last_event, WindowStateEvent::kUnfocus);
}

TEST(FlutterWindowTest, CachedLifecycleMessage) {
  MockFlutterWindow win32window;
  ON_CALL(win32window, GetPlatformWindow).WillByDefault([]() {
    return reinterpret_cast<HWND>(1);
  });

  // Restore
  win32window.InjectWindowMessage(WM_SIZE, 0, MAKEWORD(1, 1));

  // Focus
  win32window.InjectWindowMessage(WM_SETFOCUS, 0, 0);

  MockWindowBindingHandlerDelegate delegate;
  bool focused = false;
  bool restored = false;
  ON_CALL(delegate, OnWindowStateEvent)
      .WillByDefault([&](HWND hwnd, WindowStateEvent event) {
        if (event == WindowStateEvent::kFocus) {
          focused = true;
        } else if (event == WindowStateEvent::kShow) {
          restored = true;
        }
      });

  win32window.SetView(&delegate);
  EXPECT_TRUE(focused);
  EXPECT_TRUE(restored);
}

}  // namespace testing
}  // namespace flutter
