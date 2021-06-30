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
#include "flutter/shell/platform/windows/testing/flutter_window_win32_test.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler.h"
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
// Creates a valid Windows LPARAM for WM_KEYDOWN and WM_CHAR from parameters
// given.
static LPARAM CreateKeyEventLparam(USHORT scancode,
                                   bool extended = false,
                                   bool was_down = 1,
                                   USHORT repeat_count = 1,
                                   bool context_code = 0,
                                   bool transition_state = 1) {
  return ((LPARAM(transition_state) << 31) | (LPARAM(was_down) << 30) |
          (LPARAM(context_code) << 29) | (LPARAM(extended ? 0x1 : 0x0) << 24) |
          (LPARAM(scancode) << 16) | LPARAM(repeat_count));
}

// A struc to hold simulated events that will be delivered after the framework
// response is handled.
struct SimulatedEvent {
  UINT message;
  WPARAM wparam;
  LPARAM lparam;
};

// A key event handler that can be spied on while it forwards calls to the real
// key event handler.
class SpyKeyboardKeyHandler : public KeyboardHandlerBase {
 public:
  SpyKeyboardKeyHandler(
      flutter::BinaryMessenger* messenger,
      KeyboardKeyHandler::EventRedispatcher redispatch_event) {
    real_implementation_ =
        std::make_unique<KeyboardKeyHandler>(redispatch_event);
    real_implementation_->AddDelegate(
        std::make_unique<KeyboardKeyChannelHandler>(messenger));
    ON_CALL(*this, KeyboardHook(_, _, _, _, _, _, _))
        .WillByDefault(Invoke(real_implementation_.get(),
                              &KeyboardKeyHandler::KeyboardHook));
    ON_CALL(*this, TextHook(_, _))
        .WillByDefault(
            Invoke(real_implementation_.get(), &KeyboardKeyHandler::TextHook));
  }

  MOCK_METHOD7(KeyboardHook,
               bool(FlutterWindowsView* window,
                    int key,
                    int scancode,
                    int action,
                    char32_t character,
                    bool extended,
                    bool was_down));
  MOCK_METHOD2(TextHook,
               void(FlutterWindowsView* window, const std::u16string& text));
  MOCK_METHOD0(ComposeBeginHook, void());
  MOCK_METHOD0(ComposeCommitHook, void());
  MOCK_METHOD0(ComposeEndHook, void());
  MOCK_METHOD2(ComposeChangeHook,
               void(const std::u16string& text, int cursor_pos));

 private:
  std::unique_ptr<KeyboardKeyHandler> real_implementation_;
};

// A text input plugin that can be spied on while it forwards calls to the real
// text input plugin.
class SpyTextInputPlugin : public KeyboardHandlerBase,
                           public TextInputPluginDelegate {
 public:
  SpyTextInputPlugin(flutter::BinaryMessenger* messenger) {
    real_implementation_ = std::make_unique<TextInputPlugin>(messenger, this);
    ON_CALL(*this, KeyboardHook(_, _, _, _, _, _, _))
        .WillByDefault(
            Invoke(real_implementation_.get(), &TextInputPlugin::KeyboardHook));
    ON_CALL(*this, TextHook(_, _))
        .WillByDefault(
            Invoke(real_implementation_.get(), &TextInputPlugin::TextHook));
  }

  MOCK_METHOD7(KeyboardHook,
               bool(FlutterWindowsView* window,
                    int key,
                    int scancode,
                    int action,
                    char32_t character,
                    bool extended,
                    bool was_down));
  MOCK_METHOD2(TextHook,
               void(FlutterWindowsView* window, const std::u16string& text));
  MOCK_METHOD0(ComposeBeginHook, void());
  MOCK_METHOD0(ComposeCommitHook, void());
  MOCK_METHOD0(ComposeEndHook, void());
  MOCK_METHOD2(ComposeChangeHook,
               void(const std::u16string& text, int cursor_pos));

  virtual void OnCursorRectUpdated(const Rect& rect) {}

 private:
  std::unique_ptr<TextInputPlugin> real_implementation_;
};

class MockFlutterWindowWin32 : public FlutterWindowWin32 {
 public:
  MockFlutterWindowWin32() : FlutterWindowWin32(800, 600) {
    ON_CALL(*this, GetDpiScale())
        .WillByDefault(Return(this->FlutterWindowWin32::GetDpiScale()));
  }
  virtual ~MockFlutterWindowWin32() {}

  // Prevent copying.
  MockFlutterWindowWin32(MockFlutterWindowWin32 const&) = delete;
  MockFlutterWindowWin32& operator=(MockFlutterWindowWin32 const&) = delete;

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
  MOCK_METHOD2(OnPointerMove, void(double, double));
  MOCK_METHOD3(OnPointerDown, void(double, double, UINT));
  MOCK_METHOD3(OnPointerUp, void(double, double, UINT));
  MOCK_METHOD0(OnPointerLeave, void());
  MOCK_METHOD0(OnSetCursor, void());
  MOCK_METHOD2(OnScroll, void(double, double));
  MOCK_METHOD4(DefaultWindowProc, LRESULT(HWND, UINT, WPARAM, LPARAM));
  MOCK_METHOD0(GetDpiScale, float());
  MOCK_METHOD0(IsVisible, bool());
  MOCK_METHOD1(UpdateCursorRect, void(const Rect&));
};

class MockWindowBindingHandlerDelegate : public WindowBindingHandlerDelegate {
 public:
  MockWindowBindingHandlerDelegate() {}

  // Prevent copying.
  MockWindowBindingHandlerDelegate(MockWindowBindingHandlerDelegate const&) =
      delete;
  MockWindowBindingHandlerDelegate& operator=(
      MockWindowBindingHandlerDelegate const&) = delete;

  MOCK_METHOD2(OnWindowSizeChanged, void(size_t, size_t));
  MOCK_METHOD3(OnPointerMove, void(double, double, FlutterPointerDeviceKind));
  MOCK_METHOD4(OnPointerDown,
               void(double,
                    double,
                    FlutterPointerDeviceKind,
                    FlutterPointerMouseButtons));
  MOCK_METHOD4(OnPointerUp,
               void(double,
                    double,
                    FlutterPointerDeviceKind,
                    FlutterPointerMouseButtons));
  MOCK_METHOD1(OnPointerLeave, void(FlutterPointerDeviceKind));
  MOCK_METHOD1(OnText, void(const std::u16string&));
  MOCK_METHOD6(OnKey, bool(int, int, int, char32_t, bool, bool));
  MOCK_METHOD0(OnComposeBegin, void());
  MOCK_METHOD0(OnComposeCommit, void());
  MOCK_METHOD0(OnComposeEnd, void());
  MOCK_METHOD2(OnComposeChange, void(const std::u16string&, int));
  MOCK_METHOD5(OnScroll, void(double, double, double, double, int));
};

// A FlutterWindowsView that overrides the RegisterKeyboardHandlers function
// to register the keyboard hook handlers that can be spied upon.
class TestFlutterWindowsView : public FlutterWindowsView {
 public:
  TestFlutterWindowsView(std::unique_ptr<WindowBindingHandler> window_binding,
                         WPARAM virtual_key,
                         bool is_printable = true)
      : FlutterWindowsView(std::move(window_binding)),
        virtual_key_(virtual_key),
        is_printable_(is_printable) {}

  SpyKeyboardKeyHandler* key_event_handler;
  SpyTextInputPlugin* text_input_plugin;

  void InjectPendingEvents(MockFlutterWindowWin32* win32window) {
    while (pending_responds_.size() > 0) {
      SimulatedEvent event = pending_responds_.front();
      win32window->InjectWindowMessage(event.message, event.wparam,
                                       event.lparam);
      pending_responds_.pop_front();
    }
  }

 protected:
  void RegisterKeyboardHandlers(flutter::BinaryMessenger* messenger) override {
    auto spy_key_event_handler = std::make_unique<SpyKeyboardKeyHandler>(
        messenger, [this](UINT cInputs, LPINPUT pInputs, int cbSize) -> UINT {
          return this->SendInput(cInputs, pInputs, cbSize);
        });
    auto spy_text_input_plugin =
        std::make_unique<SpyTextInputPlugin>(messenger);
    key_event_handler = spy_key_event_handler.get();
    text_input_plugin = spy_text_input_plugin.get();
    AddKeyboardHandler(std::move(spy_key_event_handler));
    AddKeyboardHandler(std::move(spy_text_input_plugin));
  }

 private:
  UINT SendInput(UINT cInputs, LPINPUT pInputs, int cbSize) {
    // Simulate the event loop by just sending the event sent to
    // "SendInput" directly to the window.
    const KEYBDINPUT kbdinput = pInputs->ki;
    const UINT message =
        (kbdinput.dwFlags & KEYEVENTF_KEYUP) ? WM_KEYUP : WM_KEYDOWN;
    const LPARAM lparam = CreateKeyEventLparam(
        kbdinput.wScan, kbdinput.dwFlags & KEYEVENTF_EXTENDEDKEY);
    // Windows would normally fill in the virtual key code for us, so we
    // simulate it for the test with the key we know is in the test. The
    // KBDINPUT we're passed doesn't have it filled in (on purpose, so that
    // Windows will fill it in).
    pending_responds_.push_back(SimulatedEvent{message, virtual_key_, lparam});
    if (is_printable_ && (kbdinput.dwFlags & KEYEVENTF_KEYUP) == 0) {
      pending_responds_.push_back(
          SimulatedEvent{WM_CHAR, virtual_key_, lparam});
    }
    return 1;
  }

  std::deque<SimulatedEvent> pending_responds_;
  WPARAM virtual_key_;
  bool is_printable_;
};

// A struct to use as a FlutterPlatformMessageResponseHandle so it can keep the
// callbacks and user data passed to the engine's
// PlatformMessageCreateResponseHandle for use in the SendPlatformMessage
// overridden function.
struct TestResponseHandle {
  FlutterDesktopBinaryReply callback;
  void* user_data;
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
  // Force the non-AOT path unless overridden by the test.
  modifier.embedder_api().RunsAOTCompiledDartCode = []() { return false; };

  modifier.embedder_api().PlatformMessageCreateResponseHandle =
      [](auto engine, auto data_callback, auto user_data, auto response_out) {
        TestResponseHandle* response_handle = new TestResponseHandle();
        response_handle->user_data = user_data;
        response_handle->callback = data_callback;
        *response_out = reinterpret_cast<FlutterPlatformMessageResponseHandle*>(
            response_handle);
        return kSuccess;
      };

  modifier.embedder_api().SendPlatformMessage =
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
         const FlutterPlatformMessage* message) {
        rapidjson::Document document;
        auto& allocator = document.GetAllocator();
        document.SetObject();
        document.AddMember("handled", test_response, allocator);
        auto encoded =
            flutter::JsonMessageCodec::GetInstance().EncodeMessage(document);
        const TestResponseHandle* response_handle =
            reinterpret_cast<const TestResponseHandle*>(
                message->response_handle);
        if (response_handle->callback != nullptr) {
          response_handle->callback(encoded->data(), encoded->size(),
                                    response_handle->user_data);
        }
        return kSuccess;
      };

  modifier.embedder_api().PlatformMessageReleaseResponseHandle =
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
         FlutterPlatformMessageResponseHandle* response) {
        const TestResponseHandle* response_handle =
            reinterpret_cast<const TestResponseHandle*>(response);
        delete response_handle;
        return kSuccess;
      };

  return engine;
}

}  // namespace

TEST(FlutterWindowWin32Test, CreateDestroy) {
  FlutterWindowWin32Test window(800, 600);
  ASSERT_TRUE(TRUE);
}

// Tests key event propagation of non-printable, non-modifier key down events.
TEST(FlutterWindowWin32Test, NonPrintableKeyDownPropagation) {
  ::testing::InSequence in_sequence;

  constexpr WPARAM virtual_key = VK_LEFT;
  constexpr WPARAM scan_code = 10;
  constexpr char32_t character = 0;
  MockFlutterWindowWin32 win32window;
  std::deque<SimulatedEvent> pending_events;
  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  TestFlutterWindowsView flutter_windows_view(
      std::move(window_binding_handler), virtual_key, false /* is_printable */);
  win32window.SetView(&flutter_windows_view);
  LPARAM lparam = CreateKeyEventLparam(scan_code, false /* extended */,
                                       false /* PrevState */);

  // Test an event not handled by the framework
  {
    test_response = false;
    flutter_windows_view.SetEngine(std::move(GetTestEngine()));
    EXPECT_CALL(*flutter_windows_view.key_event_handler,
                KeyboardHook(_, virtual_key, scan_code, WM_KEYDOWN, character,
                             false /* extended */, _))
        .Times(2)
        .RetiresOnSaturation();
    EXPECT_CALL(*flutter_windows_view.text_input_plugin,
                KeyboardHook(_, _, _, _, _, _, _))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(win32window, DefaultWindowProc(_, _, _, _))
        .Times(0)
        .RetiresOnSaturation();
    EXPECT_CALL(*flutter_windows_view.key_event_handler, TextHook(_, _))
        .Times(0);
    EXPECT_CALL(*flutter_windows_view.text_input_plugin, TextHook(_, _))
        .Times(0);
    EXPECT_EQ(win32window.InjectWindowMessage(WM_KEYDOWN, virtual_key, lparam),
              0);
    flutter_windows_view.InjectPendingEvents(&win32window);
  }

  // Test an event handled by the framework
  {
    test_response = true;
    EXPECT_CALL(*flutter_windows_view.key_event_handler,
                KeyboardHook(_, virtual_key, scan_code, WM_KEYDOWN, character,
                             false /* extended */, false /* PrevState */))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*flutter_windows_view.text_input_plugin,
                KeyboardHook(_, _, _, _, _, _, _))
        .Times(0);
    EXPECT_EQ(win32window.InjectWindowMessage(WM_KEYDOWN, virtual_key, lparam),
              0);
    flutter_windows_view.InjectPendingEvents(&win32window);
  }
}

// Tests key event propagation of printable character key down events. These
// differ from non-printable characters in that they follow a different code
// path in the WndProc (HandleMessage), producing a follow-on WM_CHAR event.
TEST(FlutterWindowWin32Test, CharKeyDownPropagation) {
  // ::testing::InSequence in_sequence;

  constexpr WPARAM virtual_key = 65;  // The "A" key, which produces a character
  constexpr WPARAM scan_code = 30;
  constexpr char32_t character = 65;

  MockFlutterWindowWin32 win32window;
  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  TestFlutterWindowsView flutter_windows_view(
      std::move(window_binding_handler), virtual_key, true /* is_printable */);
  win32window.SetView(&flutter_windows_view);
  LPARAM lparam = CreateKeyEventLparam(scan_code, false /* extended */,
                                       true /* PrevState */);

  // Test an event not handled by the framework
  {
    test_response = false;
    flutter_windows_view.SetEngine(std::move(GetTestEngine()));
    EXPECT_CALL(*flutter_windows_view.key_event_handler,
                KeyboardHook(_, virtual_key, scan_code, WM_KEYDOWN, character,
                             false, true))
        .Times(2)
        .RetiresOnSaturation();
    EXPECT_CALL(*flutter_windows_view.text_input_plugin,
                KeyboardHook(_, _, _, _, _, _, _))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*flutter_windows_view.key_event_handler, TextHook(_, _))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*flutter_windows_view.text_input_plugin, TextHook(_, _))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_EQ(win32window.InjectWindowMessage(WM_KEYDOWN, virtual_key, lparam),
              0);
    EXPECT_EQ(win32window.InjectWindowMessage(WM_CHAR, virtual_key, lparam), 0);
    flutter_windows_view.InjectPendingEvents(&win32window);
  }
  return;

  // Test an event handled by the framework
  {
    test_response = true;
    EXPECT_CALL(*flutter_windows_view.key_event_handler,
                KeyboardHook(_, virtual_key, scan_code, WM_KEYDOWN, character,
                             false /* is_printable */, true))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*flutter_windows_view.text_input_plugin,
                KeyboardHook(_, _, _, _, _, _, _))
        .Times(0);
    EXPECT_CALL(*flutter_windows_view.key_event_handler, TextHook(_, _))
        .Times(0);
    EXPECT_CALL(*flutter_windows_view.text_input_plugin, TextHook(_, _))
        .Times(0);
    EXPECT_EQ(win32window.InjectWindowMessage(WM_KEYDOWN, virtual_key, lparam),
              0);
    EXPECT_EQ(win32window.InjectWindowMessage(WM_CHAR, virtual_key, lparam), 0);
    flutter_windows_view.InjectPendingEvents(&win32window);
  }
}

// Tests key event propagation of modifier key down events. This are different
// from non-printable events in that they call MapVirtualKey, resulting in a
// slightly different code path.
TEST(FlutterWindowWin32Test, ModifierKeyDownPropagation) {
  constexpr WPARAM virtual_key = VK_LSHIFT;
  constexpr WPARAM scan_code = 20;
  constexpr char32_t character = 0;
  MockFlutterWindowWin32 win32window;
  std::deque<SimulatedEvent> pending_events;
  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  TestFlutterWindowsView flutter_windows_view(
      std::move(window_binding_handler), virtual_key, false /* is_printable */);
  win32window.SetView(&flutter_windows_view);
  LPARAM lparam = CreateKeyEventLparam(scan_code);

  // Test an event not handled by the framework
  {
    test_response = false;
    flutter_windows_view.SetEngine(std::move(GetTestEngine()));
    EXPECT_CALL(*flutter_windows_view.key_event_handler,
                KeyboardHook(_, virtual_key, scan_code, WM_KEYDOWN, character,
                             false /* extended */, true))
        .Times(2)
        .RetiresOnSaturation();
    EXPECT_CALL(*flutter_windows_view.text_input_plugin,
                KeyboardHook(_, _, _, _, _, _, _))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*flutter_windows_view.key_event_handler, TextHook(_, _))
        .Times(0);
    EXPECT_CALL(*flutter_windows_view.text_input_plugin, TextHook(_, _))
        .Times(0);
    EXPECT_EQ(win32window.InjectWindowMessage(WM_KEYDOWN, virtual_key, lparam),
              0);
    flutter_windows_view.InjectPendingEvents(&win32window);
  }

  // Test an event handled by the framework
  {
    test_response = true;
    EXPECT_CALL(*flutter_windows_view.key_event_handler,
                KeyboardHook(_, virtual_key, scan_code, WM_KEYDOWN, character,
                             false /* extended */, true))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*flutter_windows_view.text_input_plugin,
                KeyboardHook(_, _, _, _, _, _, _))
        .Times(0);
    EXPECT_EQ(win32window.InjectWindowMessage(WM_KEYDOWN, virtual_key, lparam),
              0);
    flutter_windows_view.InjectPendingEvents(&win32window);
  }
}

// Tests that composing rect updates are transformed from Flutter logical
// coordinates to device coordinates and passed to the text input manager
// when the DPI scale is 100% (96 DPI).
TEST(FlutterWindowWin32Test, OnCursorRectUpdatedRegularDPI) {
  MockFlutterWindowWin32 win32window;
  ON_CALL(win32window, GetDpiScale()).WillByDefault(Return(1.0));
  EXPECT_CALL(win32window, GetDpiScale()).Times(1);

  Rect cursor_rect(Point(10, 20), Size(30, 40));
  EXPECT_CALL(win32window, UpdateCursorRect(cursor_rect)).Times(1);

  win32window.OnCursorRectUpdated(cursor_rect);
}

// Tests that composing rect updates are transformed from Flutter logical
// coordinates to device coordinates and passed to the text input manager
// when the DPI scale is 150% (144 DPI).
TEST(FlutterWindowWin32Test, OnCursorRectUpdatedHighDPI) {
  MockFlutterWindowWin32 win32window;
  ON_CALL(win32window, GetDpiScale()).WillByDefault(Return(1.5));
  EXPECT_CALL(win32window, GetDpiScale()).Times(1);

  Rect expected_cursor_rect(Point(15, 30), Size(45, 60));
  EXPECT_CALL(win32window, UpdateCursorRect(expected_cursor_rect)).Times(1);

  Rect cursor_rect(Point(10, 20), Size(30, 40));
  win32window.OnCursorRectUpdated(cursor_rect);
}

TEST(FlutterWindowWin32Test, OnPointerStarSendsDeviceType) {
  FlutterWindowWin32 win32window(100, 100);
  MockWindowBindingHandlerDelegate delegate;
  win32window.SetView(&delegate);
  // Move
  EXPECT_CALL(delegate,
              OnPointerMove(10.0, 10.0, kFlutterPointerDeviceKindMouse))
      .Times(1);
  EXPECT_CALL(delegate,
              OnPointerMove(10.0, 10.0, kFlutterPointerDeviceKindTouch))
      .Times(1);
  EXPECT_CALL(delegate,
              OnPointerMove(10.0, 10.0, kFlutterPointerDeviceKindStylus))
      .Times(1);

  // Down
  EXPECT_CALL(delegate,
              OnPointerDown(10.0, 10.0, kFlutterPointerDeviceKindMouse,
                            kFlutterPointerButtonMousePrimary))
      .Times(1);
  EXPECT_CALL(delegate,
              OnPointerDown(10.0, 10.0, kFlutterPointerDeviceKindTouch,
                            kFlutterPointerButtonMousePrimary))
      .Times(1);
  EXPECT_CALL(delegate,
              OnPointerDown(10.0, 10.0, kFlutterPointerDeviceKindStylus,
                            kFlutterPointerButtonMousePrimary))
      .Times(1);

  // Up
  EXPECT_CALL(delegate, OnPointerUp(10.0, 10.0, kFlutterPointerDeviceKindMouse,
                                    kFlutterPointerButtonMousePrimary))
      .Times(1);
  EXPECT_CALL(delegate, OnPointerUp(10.0, 10.0, kFlutterPointerDeviceKindTouch,
                                    kFlutterPointerButtonMousePrimary))
      .Times(1);
  EXPECT_CALL(delegate, OnPointerUp(10.0, 10.0, kFlutterPointerDeviceKindStylus,
                                    kFlutterPointerButtonMousePrimary))
      .Times(1);

  // Leave
  EXPECT_CALL(delegate, OnPointerLeave(kFlutterPointerDeviceKindMouse))
      .Times(1);
  EXPECT_CALL(delegate, OnPointerLeave(kFlutterPointerDeviceKindTouch))
      .Times(1);
  EXPECT_CALL(delegate, OnPointerLeave(kFlutterPointerDeviceKindStylus))
      .Times(1);

  win32window.OnPointerMove(10.0, 10.0);
  win32window.OnPointerDown(10.0, 10.0, WM_LBUTTONDOWN);
  win32window.OnPointerUp(10.0, 10.0, WM_LBUTTONDOWN);
  win32window.OnPointerLeave();

  // Touch
  LPARAM original_lparam = SetMessageExtraInfo(0xFF51578b);
  win32window.OnPointerMove(10.0, 10.0);
  win32window.OnPointerDown(10.0, 10.0, WM_LBUTTONDOWN);
  win32window.OnPointerUp(10.0, 10.0, WM_LBUTTONDOWN);
  win32window.OnPointerLeave();

  // Pen
  SetMessageExtraInfo(0xFF515700);
  win32window.OnPointerMove(10.0, 10.0);
  win32window.OnPointerDown(10.0, 10.0, WM_LBUTTONDOWN);
  win32window.OnPointerUp(10.0, 10.0, WM_LBUTTONDOWN);
  win32window.OnPointerLeave();

  // Reset extra info for other tests.
  SetMessageExtraInfo(original_lparam);
}

}  // namespace testing
}  // namespace flutter
