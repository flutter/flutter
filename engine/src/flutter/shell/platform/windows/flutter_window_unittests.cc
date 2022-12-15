// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/json_message_codec.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/keyboard_key_channel_handler.h"
#include "flutter/shell/platform/windows/keyboard_key_handler.h"
#include "flutter/shell/platform/windows/testing/engine_modifier.h"
#include "flutter/shell/platform/windows/testing/flutter_window_test.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler_delegate.h"
#include "flutter/shell/platform/windows/testing/test_keyboard.h"
#include "flutter/shell/platform/windows/text_input_plugin.h"
#include "flutter/shell/platform/windows/text_input_plugin_delegate.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include <rapidjson/document.h>

using testing::_;
using testing::Invoke;
using testing::Return;

namespace flutter {
namespace testing {

namespace {
static constexpr int32_t kDefaultPointerDeviceId = 0;

// A key event handler that can be spied on while it forwards calls to the real
// key event handler.
class SpyKeyboardKeyHandler : public KeyboardHandlerBase {
 public:
  SpyKeyboardKeyHandler(flutter::BinaryMessenger* messenger) {
    real_implementation_ = std::make_unique<KeyboardKeyHandler>();
    real_implementation_->AddDelegate(
        std::make_unique<KeyboardKeyChannelHandler>(messenger));
    ON_CALL(*this, KeyboardHook(_, _, _, _, _, _, _))
        .WillByDefault(Invoke(real_implementation_.get(),
                              &KeyboardKeyHandler::KeyboardHook));
    ON_CALL(*this, SyncModifiersIfNeeded(_))
        .WillByDefault(Invoke(real_implementation_.get(),
                              &KeyboardKeyHandler::SyncModifiersIfNeeded));
  }

  MOCK_METHOD7(KeyboardHook,
               void(int key,
                    int scancode,
                    int action,
                    char32_t character,
                    bool extended,
                    bool was_down,
                    KeyEventCallback callback));

  MOCK_METHOD1(SyncModifiersIfNeeded, void(int modifiers_state));

 private:
  std::unique_ptr<KeyboardKeyHandler> real_implementation_;
};

// A text input plugin that can be spied on while it forwards calls to the real
// text input plugin.
class SpyTextInputPlugin : public TextInputPlugin,
                           public TextInputPluginDelegate {
 public:
  SpyTextInputPlugin(flutter::BinaryMessenger* messenger)
      : TextInputPlugin(messenger, this) {
    real_implementation_ = std::make_unique<TextInputPlugin>(messenger, this);
    ON_CALL(*this, KeyboardHook(_, _, _, _, _, _))
        .WillByDefault(
            Invoke(real_implementation_.get(), &TextInputPlugin::KeyboardHook));
    ON_CALL(*this, TextHook(_))
        .WillByDefault(
            Invoke(real_implementation_.get(), &TextInputPlugin::TextHook));
  }

  MOCK_METHOD6(KeyboardHook,
               void(int key,
                    int scancode,
                    int action,
                    char32_t character,
                    bool extended,
                    bool was_down));
  MOCK_METHOD1(TextHook, void(const std::u16string& text));
  MOCK_METHOD0(ComposeBeginHook, void());
  MOCK_METHOD0(ComposeCommitHook, void());
  MOCK_METHOD0(ComposeEndHook, void());
  MOCK_METHOD2(ComposeChangeHook,
               void(const std::u16string& text, int cursor_pos));

  virtual void OnCursorRectUpdated(const Rect& rect) {}
  virtual void OnResetImeComposing() {}

 private:
  std::unique_ptr<TextInputPlugin> real_implementation_;
};

class MockFlutterWindow : public FlutterWindow {
 public:
  MockFlutterWindow() : FlutterWindow(800, 600) {
    ON_CALL(*this, GetDpiScale())
        .WillByDefault(Return(this->FlutterWindow::GetDpiScale()));
  }
  virtual ~MockFlutterWindow() {}

  // Prevent copying.
  MockFlutterWindow(MockFlutterWindow const&) = delete;
  MockFlutterWindow& operator=(MockFlutterWindow const&) = delete;

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

 protected:
  // |KeyboardManager::WindowDelegate|
  LRESULT Win32DefWindowProc(HWND hWnd,
                             UINT Msg,
                             WPARAM wParam,
                             LPARAM lParam) override {
    return kWmResultDefault;
  }
};

// A FlutterWindowsView that overrides the RegisterKeyboardHandlers function
// to register the keyboard hook handlers that can be spied upon.
class TestFlutterWindowsView : public FlutterWindowsView {
 public:
  TestFlutterWindowsView(std::unique_ptr<WindowBindingHandler> window_binding)
      : FlutterWindowsView(std::move(window_binding)) {}
  ~TestFlutterWindowsView() {}

  SpyKeyboardKeyHandler* key_event_handler;
  SpyTextInputPlugin* text_input_plugin;

  MOCK_METHOD4(NotifyWinEventWrapper, void(DWORD, HWND, LONG, LONG));

 protected:
  std::unique_ptr<KeyboardHandlerBase> CreateKeyboardKeyHandler(
      flutter::BinaryMessenger* messenger,
      flutter::KeyboardKeyEmbedderHandler::GetKeyStateHandler get_key_state,
      KeyboardKeyEmbedderHandler::MapVirtualKeyToScanCode map_vk_to_scan)
      override {
    auto spy_key_event_handler =
        std::make_unique<SpyKeyboardKeyHandler>(messenger);
    key_event_handler = spy_key_event_handler.get();
    return spy_key_event_handler;
  }

  std::unique_ptr<TextInputPlugin> CreateTextInputPlugin(
      flutter::BinaryMessenger* messenger) override {
    auto spy_key_event_handler =
        std::make_unique<SpyTextInputPlugin>(messenger);
    text_input_plugin = spy_key_event_handler.get();
    return spy_key_event_handler;
  }
};

// The static value to return as the "handled" value from the framework for key
// events. Individual tests set this to change the framework response that the
// test engine simulates.
static bool test_response = false;

// Returns an engine instance configured with dummy project path values, and
// overridden methods for sending platform messages, so that the engine can
// respond as if the framework were connected.
std::unique_ptr<FlutterWindowsEngine> GetTestEngine() {
  FlutterDesktopEngineProperties properties = {};
  properties.assets_path = L"C:\\foo\\flutter_assets";
  properties.icu_data_path = L"C:\\foo\\icudtl.dat";
  properties.aot_library_path = L"C:\\foo\\aot.so";
  FlutterProjectBundle project(properties);
  auto engine = std::make_unique<FlutterWindowsEngine>(project);

  EngineModifier modifier(engine.get());
  auto key_response_controller = std::make_shared<MockKeyResponseController>();
  key_response_controller->SetChannelResponse(
      [](MockKeyResponseController::ResponseCallback callback) {
        callback(test_response);
      });
  MockEmbedderApiForKeyboard(modifier, key_response_controller);

  return engine;
}

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
  AccessibilityRootNode* root_node = win32window->GetAccessibilityRootNode();
  TestFlutterWindowsView view(std::move(win32window));
  EXPECT_CALL(view,
              NotifyWinEventWrapper(EVENT_SYSTEM_ALERT, nullptr, OBJID_CLIENT,
                                    AccessibilityRootNode::kAlertChildId))
      .Times(1);
  std::wstring message = L"Test alert";
  view.AnnounceAlert(message);
  IAccessible* alert = root_node->GetOrCreateAlert();
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

}  // namespace testing
}  // namespace flutter
