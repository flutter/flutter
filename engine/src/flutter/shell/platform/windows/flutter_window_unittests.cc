// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/windows/flutter_window.h"
#include "flutter/shell/platform/windows/testing/flutter_windows_engine_builder.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler_delegate.h"
#include "flutter/shell/platform/windows/testing/mock_windows_proc_table.h"
#include "flutter/shell/platform/windows/testing/windows_test.h"
#include "flutter/shell/platform/windows/testing/wm_builders.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

using ::testing::_;
using ::testing::AnyNumber;
using ::testing::Eq;
using ::testing::Invoke;
using ::testing::Return;

namespace {
static constexpr int32_t kDefaultPointerDeviceId = 0;

class MockFlutterWindow : public FlutterWindow {
 public:
  MockFlutterWindow(bool reset_view_on_exit = true)
      : reset_view_on_exit_(reset_view_on_exit) {
    ON_CALL(*this, GetDpiScale())
        .WillByDefault(Return(this->FlutterWindow::GetDpiScale()));
  }

  // Used for injecting a proc_table to override calls to the windows API
  MockFlutterWindow(int width,
                    int height,
                    std::shared_ptr<WindowsProcTable> proc_table = nullptr)
      : FlutterWindow(width, height, proc_table) {}

  virtual ~MockFlutterWindow() {
    if (reset_view_on_exit_) {
      SetView(nullptr);
    }
  }

  // Wrapper for GetCurrentDPI() which is a protected method.
  UINT GetDpi() { return GetCurrentDPI(); }
  // Simulates a WindowProc message from the OS.
  LRESULT InjectWindowMessage(UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) {
    return HandleMessage(message, wparam, lparam);
  }

  MOCK_METHOD(void, OnDpiScale, (unsigned int), (override));
  MOCK_METHOD(void, OnResize, (unsigned int, unsigned int), (override));
  MOCK_METHOD(float, GetScrollOffsetMultiplier, (), (override));
  MOCK_METHOD(float, GetDpiScale, (), (override));
  MOCK_METHOD(void, UpdateCursorRect, (const Rect&), (override));
  MOCK_METHOD(void, OnResetImeComposing, (), (override));
  MOCK_METHOD(UINT, Win32DispatchMessage, (UINT, WPARAM, LPARAM), (override));
  MOCK_METHOD(BOOL, Win32PeekMessage, (LPMSG, UINT, UINT, UINT), (override));
  MOCK_METHOD(uint32_t, Win32MapVkToChar, (uint32_t), (override));
  MOCK_METHOD(HWND, GetWindowHandle, (), (override));
  MOCK_METHOD(ui::AXFragmentRootDelegateWin*,
              GetAxFragmentRootDelegate,
              (),
              (override));
  MOCK_METHOD(void, OnWindowStateEvent, (WindowStateEvent), (override));

 protected:
  // |KeyboardManager::WindowDelegate|
  LRESULT Win32DefWindowProc(HWND hWnd,
                             UINT Msg,
                             WPARAM wParam,
                             LPARAM lParam) override {
    return kWmResultDefault;
  }

 private:
  bool reset_view_on_exit_;
  FML_DISALLOW_COPY_AND_ASSIGN(MockFlutterWindow);
};

class MockFlutterWindowsView : public FlutterWindowsView {
 public:
  MockFlutterWindowsView(FlutterWindowsEngine* engine,
                         std::unique_ptr<WindowBindingHandler> window_binding)
      : FlutterWindowsView(kImplicitViewId, engine, std::move(window_binding)) {
  }
  ~MockFlutterWindowsView() {}

  MOCK_METHOD(void,
              NotifyWinEventWrapper,
              (ui::AXPlatformNodeWin*, ax::mojom::Event),
              (override));

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(MockFlutterWindowsView);
};

class FlutterWindowTest : public WindowsTest {};

}  // namespace

TEST_F(FlutterWindowTest, CreateDestroy) {
  FlutterWindow window(800, 600);
  ASSERT_TRUE(TRUE);
}

TEST_F(FlutterWindowTest, OnBitmapSurfaceUpdated) {
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
TEST_F(FlutterWindowTest, OnCursorRectUpdatedRegularDPI) {
  MockFlutterWindow win32window;
  EXPECT_CALL(win32window, GetDpiScale()).WillOnce(Return(1.0));

  Rect cursor_rect(Point(10, 20), Size(30, 40));
  EXPECT_CALL(win32window, UpdateCursorRect(cursor_rect)).Times(1);

  win32window.OnCursorRectUpdated(cursor_rect);
}

// Tests that composing rect updates are transformed from Flutter logical
// coordinates to device coordinates and passed to the text input manager
// when the DPI scale is 150% (144 DPI).
TEST_F(FlutterWindowTest, OnCursorRectUpdatedHighDPI) {
  MockFlutterWindow win32window;
  EXPECT_CALL(win32window, GetDpiScale()).WillOnce(Return(1.5));

  Rect expected_cursor_rect(Point(15, 30), Size(45, 60));
  EXPECT_CALL(win32window, UpdateCursorRect(expected_cursor_rect)).Times(1);

  Rect cursor_rect(Point(10, 20), Size(30, 40));
  win32window.OnCursorRectUpdated(cursor_rect);
}

TEST_F(FlutterWindowTest, OnPointerStarSendsDeviceType) {
  FlutterWindow win32window(100, 100);
  MockWindowBindingHandlerDelegate delegate;
  EXPECT_CALL(delegate, OnWindowStateEvent).Times(AnyNumber());
  win32window.SetView(&delegate);

  // Move
  EXPECT_CALL(delegate,
              OnPointerMove(10.0, 10.0, kFlutterPointerDeviceKindMouse,
                            kDefaultPointerDeviceId, 0, 0, 0))
      .Times(1);
  EXPECT_CALL(delegate,
              OnPointerMove(10.0, 10.0, kFlutterPointerDeviceKindTouch,
                            kDefaultPointerDeviceId, 0, 0, 0))
      .Times(1);
  EXPECT_CALL(delegate,
              OnPointerMove(10.0, 10.0, kFlutterPointerDeviceKindStylus,
                            kDefaultPointerDeviceId, 0, 0, 0))
      .Times(1);

  // Down
  EXPECT_CALL(delegate,
              OnPointerDown(10.0, 10.0, kFlutterPointerDeviceKindMouse,
                            kDefaultPointerDeviceId,
                            kFlutterPointerButtonMousePrimary, 0, 0))
      .Times(1);
  EXPECT_CALL(delegate,
              OnPointerDown(10.0, 10.0, kFlutterPointerDeviceKindTouch,
                            kDefaultPointerDeviceId,
                            kFlutterPointerButtonMousePrimary, 0, 0))
      .Times(1);
  EXPECT_CALL(delegate,
              OnPointerDown(10.0, 10.0, kFlutterPointerDeviceKindStylus,
                            kDefaultPointerDeviceId,
                            kFlutterPointerButtonMousePrimary, 0, 0))
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
                            kDefaultPointerDeviceId, 0, 0, 0);
  win32window.OnPointerDown(10.0, 10.0, kFlutterPointerDeviceKindMouse,
                            kDefaultPointerDeviceId, WM_LBUTTONDOWN, 0, 0);
  win32window.OnPointerUp(10.0, 10.0, kFlutterPointerDeviceKindMouse,
                          kDefaultPointerDeviceId, WM_LBUTTONDOWN);
  win32window.OnPointerLeave(10.0, 10.0, kFlutterPointerDeviceKindMouse,
                             kDefaultPointerDeviceId);

  // Touch
  win32window.OnPointerMove(10.0, 10.0, kFlutterPointerDeviceKindTouch,
                            kDefaultPointerDeviceId, 0, 0, 0);
  win32window.OnPointerDown(10.0, 10.0, kFlutterPointerDeviceKindTouch,
                            kDefaultPointerDeviceId, WM_LBUTTONDOWN, 0, 0);
  win32window.OnPointerUp(10.0, 10.0, kFlutterPointerDeviceKindTouch,
                          kDefaultPointerDeviceId, WM_LBUTTONDOWN);
  win32window.OnPointerLeave(10.0, 10.0, kFlutterPointerDeviceKindTouch,
                             kDefaultPointerDeviceId);

  // Pen
  win32window.OnPointerMove(10.0, 10.0, kFlutterPointerDeviceKindStylus,
                            kDefaultPointerDeviceId, 0, 0, 0);
  win32window.OnPointerDown(10.0, 10.0, kFlutterPointerDeviceKindStylus,
                            kDefaultPointerDeviceId, WM_LBUTTONDOWN, 0, 0);
  win32window.OnPointerUp(10.0, 10.0, kFlutterPointerDeviceKindStylus,
                          kDefaultPointerDeviceId, WM_LBUTTONDOWN);
  win32window.OnPointerLeave(10.0, 10.0, kFlutterPointerDeviceKindStylus,
                             kDefaultPointerDeviceId);

  // Destruction of win32window sends a HIDE update. In situ, the window is
  // owned by the delegate, and so is destructed first. Not so here.
  win32window.SetView(nullptr);
}

TEST_F(FlutterWindowTest, OnStylusPointerDown) {
  auto mock_proc_table = std::make_shared<MockWindowsProcTable>();

  // Set up expectations for the mock
  EXPECT_CALL(*mock_proc_table, GetPointerInfo(_, _))
      .WillRepeatedly([](UINT32 pointer_id, POINTER_INFO* pointer_info) {
        if (pointer_info != nullptr) {
          pointer_info->pointerType = PT_PEN;
          pointer_info->pointerId = pointer_id;
          pointer_info->pointerFlags = POINTER_FLAG_INCONTACT;
        }
        return TRUE;
      });

  EXPECT_CALL(*mock_proc_table, GetPointerPenInfo(_, _))
      .WillRepeatedly([](UINT32 pointer_id, POINTER_PEN_INFO* pen_info) {
        if (pen_info != nullptr) {
          pen_info->pressure = 720;  // Non-zero pressure for contact events
          pen_info->rotation = 0;
        }
        return TRUE;
      });

  POINTER_INFO test_pointer_info = {};
  BOOL result = mock_proc_table->GetPointerInfo(1, &test_pointer_info);

  MockFlutterWindow win32window(100, 100, mock_proc_table);
  MockWindowBindingHandlerDelegate delegate;

  win32window.SetView(&delegate);

  EXPECT_CALL(delegate,
              OnPointerDown(10.0, 10.0, kFlutterPointerDeviceKindStylus,
                            kDefaultPointerDeviceId,
                            kFlutterPointerButtonMousePrimary, 720, 0))
      .Times(1);

  UINT32 pointerId = 1;
  WPARAM wparam = static_cast<WPARAM>(pointerId);
  LPARAM lparam = MAKELPARAM(10, 10);

  win32window.InjectWindowMessage(WM_POINTERDOWN, wparam, lparam);
}

TEST_F(FlutterWindowTest, OnStylusPointerMove) {
  auto mock_proc_table = std::make_shared<MockWindowsProcTable>();

  EXPECT_CALL(*mock_proc_table, GetPointerInfo(_, _))
      .WillRepeatedly([](UINT32 pointer_id, POINTER_INFO* pointer_info) {
        if (pointer_info != nullptr) {
          pointer_info->pointerType = PT_PEN;
          pointer_info->pointerId = pointer_id;
          pointer_info->pointerFlags =
              POINTER_FLAG_INCONTACT | POINTER_FLAG_UPDATE;
        }
        return TRUE;
      });

  EXPECT_CALL(*mock_proc_table, GetPointerPenInfo(_, _))
      .WillRepeatedly([](UINT32 pointer_id, POINTER_PEN_INFO* pen_info) {
        if (pen_info != nullptr) {
          pen_info->pressure = 720;  // Non-zero pressure for contact events
          pen_info->rotation = 10;   // This is PRE-transformation to radians.
        }
        return TRUE;
      });

  MockFlutterWindow win32window(100, 100, mock_proc_table);
  MockWindowBindingHandlerDelegate delegate;
  win32window.SetView(&delegate);

  EXPECT_CALL(delegate, OnPointerMove(15, 20, kFlutterPointerDeviceKindStylus,
                                      kDefaultPointerDeviceId, 10, 720, 0))
      .Times(1);

  UINT32 pointerId = 1;
  WPARAM wparam = static_cast<WPARAM>(pointerId);
  LPARAM lparam = MAKELPARAM(15, 20);

  win32window.InjectWindowMessage(WM_POINTERUPDATE, wparam, lparam);
}

TEST_F(FlutterWindowTest, OnStylusPointerUp) {
  auto mock_proc_table = std::make_shared<MockWindowsProcTable>();

  EXPECT_CALL(*mock_proc_table, GetPointerInfo(_, _))
      .WillRepeatedly([](UINT32 pointer_id, POINTER_INFO* pointer_info) {
        if (pointer_info != nullptr) {
          pointer_info->pointerType = PT_PEN;
          pointer_info->pointerId = pointer_id;
          pointer_info->pointerFlags = POINTER_FLAG_UP;
        }
        return TRUE;
      });

  EXPECT_CALL(*mock_proc_table, GetPointerPenInfo(_, _))
      .WillRepeatedly([](UINT32 pointer_id, POINTER_PEN_INFO* pen_info) {
        if (pen_info != nullptr) {
          pen_info->pressure = 720;
          pen_info->rotation = 0;
        }
        return TRUE;
      });

  MockFlutterWindow win32window(100, 100, mock_proc_table);
  MockWindowBindingHandlerDelegate delegate;
  win32window.SetView(&delegate);

  EXPECT_CALL(delegate, OnPointerUp(25, 30, kFlutterPointerDeviceKindStylus,
                                    kDefaultPointerDeviceId,
                                    kFlutterPointerButtonMousePrimary))
      .Times(1);

  UINT32 pointerId = 1;
  WPARAM wparam = static_cast<WPARAM>(pointerId);
  LPARAM lparam = MAKELPARAM(25, 30);

  win32window.InjectWindowMessage(WM_POINTERUP, wparam, lparam);
}

TEST_F(FlutterWindowTest, OnStylusPointerLeave) {
  auto mock_proc_table = std::make_shared<MockWindowsProcTable>();

  EXPECT_CALL(*mock_proc_table, GetPointerInfo(_, _))
      .WillRepeatedly([](UINT32 pointer_id, POINTER_INFO* pointer_info) {
        if (pointer_info != nullptr) {
          pointer_info->pointerType = PT_PEN;
          pointer_info->pointerId = pointer_id;
          pointer_info->pointerFlags = POINTER_FLAG_UP;
        }
        return TRUE;
      });

  EXPECT_CALL(*mock_proc_table, GetPointerPenInfo(_, _))
      .WillRepeatedly([](UINT32 pointer_id, POINTER_PEN_INFO* pen_info) {
        if (pen_info != nullptr) {
          pen_info->pressure = 720;
          pen_info->rotation = 0;
        }
        return TRUE;
      });

  MockFlutterWindow win32window(100, 100, mock_proc_table);
  MockWindowBindingHandlerDelegate delegate;
  win32window.SetView(&delegate);

  EXPECT_CALL(delegate, OnPointerLeave(35, 40, kFlutterPointerDeviceKindStylus,
                                       kDefaultPointerDeviceId))
      .Times(1);

  UINT32 pointerId = 1;
  WPARAM wparam = static_cast<WPARAM>(pointerId);
  LPARAM lparam = MAKELPARAM(35, 40);

  win32window.InjectWindowMessage(WM_POINTERLEAVE, wparam, lparam);
}

TEST_F(FlutterWindowTest, OnStylusPointerHover) {
  // Test that WM_POINTERUPDATE without POINTER_FLAG_INCONTACT (hover) is
  // handled
  auto mock_proc_table = std::make_shared<MockWindowsProcTable>();

  EXPECT_CALL(*mock_proc_table, GetPointerInfo(_, _))
      .WillRepeatedly([](UINT32 pointer_id, POINTER_INFO* pointer_info) {
        if (pointer_info != nullptr) {
          pointer_info->pointerId = 1;
          pointer_info->pointerType = PT_PEN;
          // No POINTER_FLAG_INCONTACT - this simulates a hover event
          pointer_info->pointerFlags = POINTER_FLAG_UPDATE;
          pointer_info->ptPixelLocation.x = 45;
          pointer_info->ptPixelLocation.y = 50;
        }
        return TRUE;
      });

  EXPECT_CALL(*mock_proc_table, GetPointerPenInfo(_, _))
      .WillRepeatedly([](UINT32 pointer_id, POINTER_PEN_INFO* pen_info) {
        if (pen_info != nullptr) {
          pen_info->pressure = 0;
          pen_info->rotation = 0;
        }
        return TRUE;
      });

  MockFlutterWindow win32window(100, 100, mock_proc_table);
  MockWindowBindingHandlerDelegate delegate;
  win32window.SetView(&delegate);

  // First establish the pointer with WM_POINTERDOWN
  EXPECT_CALL(delegate,
              OnPointerDown(45, 50, kFlutterPointerDeviceKindStylus, 0,
                            kFlutterPointerButtonMousePrimary, 0, 0))
      .Times(1);

  UINT32 pointerId = 1;
  WPARAM wparam = static_cast<WPARAM>(pointerId);
  LPARAM lparam = MAKELPARAM(45, 50);
  win32window.InjectWindowMessage(WM_POINTERDOWN, wparam, lparam);

  // Now expect OnPointerMove to be called for hover events
  EXPECT_CALL(delegate, OnPointerMove(45, 50, kFlutterPointerDeviceKindStylus,
                                      0, 0, 0, 0))
      .Times(1);

  // Inject WM_POINTERUPDATE message (hover event)
  win32window.InjectWindowMessage(WM_POINTERUPDATE, wparam, lparam);
}

TEST_F(FlutterWindowTest, OnMousePointerDown) {
  auto mock_proc_table = std::make_shared<MockWindowsProcTable>();

  EXPECT_CALL(*mock_proc_table, GetPointerInfo(_, _))
      .WillRepeatedly([](UINT32 pointer_id, POINTER_INFO* pointer_info) {
        if (pointer_info != nullptr) {
          pointer_info->pointerType = PT_MOUSE;
          pointer_info->pointerId = pointer_id;
          pointer_info->pointerFlags = POINTER_FLAG_INCONTACT;
        }
        return TRUE;
      });

  MockFlutterWindow win32window(100, 100, mock_proc_table);
  MockWindowBindingHandlerDelegate delegate;
  win32window.SetView(&delegate);

  EXPECT_CALL(delegate, OnPointerDown(45, 50, kFlutterPointerDeviceKindMouse,
                                      kDefaultPointerDeviceId,
                                      kFlutterPointerButtonMousePrimary, 0, 0))
      .Times(1);

  UINT32 pointerId = 1;
  WPARAM wparam = static_cast<WPARAM>(pointerId);
  LPARAM lparam = MAKELPARAM(45, 50);

  win32window.InjectWindowMessage(WM_POINTERDOWN, wparam, lparam);
}

TEST_F(FlutterWindowTest, OnTouchPointerDown) {
  auto mock_proc_table = std::make_shared<MockWindowsProcTable>();

  EXPECT_CALL(*mock_proc_table, GetPointerInfo(_, _))
      .WillRepeatedly([](UINT32 pointer_id, POINTER_INFO* pointer_info) {
        if (pointer_info != nullptr) {
          pointer_info->pointerType = PT_TOUCH;
          pointer_info->pointerId = pointer_id;
          pointer_info->pointerFlags = POINTER_FLAG_INCONTACT;
        }
        return TRUE;
      });

  MockFlutterWindow win32window(100, 100, mock_proc_table);
  MockWindowBindingHandlerDelegate delegate;
  win32window.SetView(&delegate);

  EXPECT_CALL(delegate, OnPointerDown(55, 60, kFlutterPointerDeviceKindTouch,
                                      kDefaultPointerDeviceId,
                                      kFlutterPointerButtonMousePrimary, 0, 0))
      .Times(1);

  UINT32 pointerId = 1;
  WPARAM wparam = static_cast<WPARAM>(pointerId);
  LPARAM lparam = MAKELPARAM(55, 60);

  win32window.InjectWindowMessage(WM_POINTERDOWN, wparam, lparam);
}

// Tests that calls to OnScroll in turn calls GetScrollOffsetMultiplier
// for mapping scroll ticks to pixels.
TEST_F(FlutterWindowTest, OnScrollCallsGetScrollOffsetMultiplier) {
  MockFlutterWindow win32window;
  MockWindowBindingHandlerDelegate delegate;
  EXPECT_CALL(win32window, OnWindowStateEvent).Times(AnyNumber());
  win32window.SetView(&delegate);

  EXPECT_CALL(win32window, GetWindowHandle).WillOnce([&win32window]() {
    return win32window.FlutterWindow::GetWindowHandle();
  });
  EXPECT_CALL(win32window, GetScrollOffsetMultiplier).WillOnce(Return(120.0f));

  EXPECT_CALL(delegate,
              OnScroll(_, _, 0, 0, 120.0f, kFlutterPointerDeviceKindMouse,
                       kDefaultPointerDeviceId))
      .Times(1);

  win32window.OnScroll(0.0f, 0.0f, kFlutterPointerDeviceKindMouse,
                       kDefaultPointerDeviceId);
}

TEST_F(FlutterWindowTest, OnWindowRepaint) {
  MockFlutterWindow win32window;
  MockWindowBindingHandlerDelegate delegate;
  EXPECT_CALL(win32window, OnWindowStateEvent).Times(AnyNumber());
  win32window.SetView(&delegate);

  EXPECT_CALL(delegate, OnWindowRepaint()).Times(1);

  win32window.InjectWindowMessage(WM_PAINT, 0, 0);
}

TEST_F(FlutterWindowTest, OnThemeChange) {
  MockFlutterWindow win32window;
  MockWindowBindingHandlerDelegate delegate;
  EXPECT_CALL(win32window, OnWindowStateEvent).Times(AnyNumber());
  win32window.SetView(&delegate);

  EXPECT_CALL(delegate, OnHighContrastChanged).Times(1);

  win32window.InjectWindowMessage(WM_THEMECHANGED, 0, 0);
}

// The window should return no root accessibility node if
// it isn't attached to a view.
// Regression test for https://github.com/flutter/flutter/issues/129791
TEST_F(FlutterWindowTest, AccessibilityNodeWithoutView) {
  MockFlutterWindow win32window;

  EXPECT_EQ(win32window.GetNativeViewAccessible(), nullptr);
}

// Ensure that announcing the alert propagates the message to the alert node.
// Different screen readers use different properties for alerts.
TEST_F(FlutterWindowTest, AlertNode) {
  std::unique_ptr<FlutterWindowsEngine> engine =
      FlutterWindowsEngineBuilder{GetContext()}.Build();
  auto win32window = std::make_unique<MockFlutterWindow>();
  EXPECT_CALL(*win32window.get(), GetAxFragmentRootDelegate())
      .WillRepeatedly(Return(nullptr));
  EXPECT_CALL(*win32window.get(), OnWindowStateEvent).Times(AnyNumber());
  EXPECT_CALL(*win32window.get(), GetWindowHandle).Times(AnyNumber());
  MockFlutterWindowsView view{engine.get(), std::move(win32window)};
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

TEST_F(FlutterWindowTest, LifecycleFocusMessages) {
  MockFlutterWindow win32window;
  EXPECT_CALL(win32window, GetWindowHandle)
      .WillRepeatedly(Return(reinterpret_cast<HWND>(1)));
  MockWindowBindingHandlerDelegate delegate;

  WindowStateEvent last_event;
  EXPECT_CALL(delegate, OnWindowStateEvent)
      .WillRepeatedly([&last_event](HWND hwnd, WindowStateEvent event) {
        last_event = event;
      });
  EXPECT_CALL(win32window, OnWindowStateEvent)
      .WillRepeatedly([&](WindowStateEvent event) {
        win32window.FlutterWindow::OnWindowStateEvent(event);
      });
  EXPECT_CALL(win32window, OnResize).Times(AnyNumber());

  win32window.SetView(&delegate);

  win32window.InjectWindowMessage(WM_SIZE, 0, 0);
  EXPECT_EQ(last_event, WindowStateEvent::kHide);

  win32window.InjectWindowMessage(WM_SIZE, 0, MAKEWORD(1, 1));
  EXPECT_EQ(last_event, WindowStateEvent::kShow);

  EXPECT_CALL(delegate, OnFocus(Eq(FlutterViewFocusState::kFocused),
                                Eq(FlutterViewFocusDirection::kUndefined)))
      .Times(1);
  win32window.InjectWindowMessage(WM_SETFOCUS, 0, 0);
  EXPECT_EQ(last_event, WindowStateEvent::kFocus);

  EXPECT_CALL(delegate, OnFocus(Eq(FlutterViewFocusState::kUnfocused),
                                Eq(FlutterViewFocusDirection::kUndefined)))
      .Times(1);
  win32window.InjectWindowMessage(WM_KILLFOCUS, 0, 0);
  EXPECT_EQ(last_event, WindowStateEvent::kUnfocus);
}

TEST_F(FlutterWindowTest, CachedLifecycleMessage) {
  MockFlutterWindow win32window;
  EXPECT_CALL(win32window, GetWindowHandle)
      .WillRepeatedly(Return(reinterpret_cast<HWND>(1)));
  EXPECT_CALL(win32window, OnWindowStateEvent)
      .WillRepeatedly([&](WindowStateEvent event) {
        win32window.FlutterWindow::OnWindowStateEvent(event);
      });
  EXPECT_CALL(win32window, OnResize).Times(1);

  // Restore
  win32window.InjectWindowMessage(WM_SIZE, 0, MAKEWORD(1, 1));

  // Focus
  win32window.InjectWindowMessage(WM_SETFOCUS, 0, 0);

  MockWindowBindingHandlerDelegate delegate;
  bool focused = false;
  bool restored = false;
  EXPECT_CALL(delegate, OnWindowStateEvent)
      .WillRepeatedly([&](HWND hwnd, WindowStateEvent event) {
        if (event == WindowStateEvent::kFocus) {
          focused = true;
        } else if (event == WindowStateEvent::kShow) {
          restored = true;
        }
      });

  EXPECT_CALL(delegate, OnFocus(Eq(FlutterViewFocusState::kFocused),
                                Eq(FlutterViewFocusDirection::kUndefined)))
      .Times(1);
  win32window.SetView(&delegate);
  EXPECT_TRUE(focused);
  EXPECT_TRUE(restored);
}

}  // namespace testing
}  // namespace flutter
