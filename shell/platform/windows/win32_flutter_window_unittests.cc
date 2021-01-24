// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/cpp/json_message_codec.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/testing/engine_embedder_api_modifier.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler.h"
#include "flutter/shell/platform/windows/testing/win32_flutter_window_test.h"
#include "flutter/shell/platform/windows/text_input_plugin_delegate.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include <rapidjson/document.h>

using testing::_;
using testing::Invoke;

namespace flutter {
namespace testing {

namespace {
// Creates a valid Windows LPARAM for WM_KEYDOWN and WM_CHAR from parameters
// given.
static LPARAM CreateKeyEventLparam(USHORT ScanCode,
                                   bool extended = false,
                                   USHORT RepeatCount = 1,
                                   bool ContextCode = 0,
                                   bool PreviousKeyState = 1,
                                   bool TransitionState = 1) {
  return ((LPARAM(TransitionState) << 31) | (LPARAM(PreviousKeyState) << 30) |
          (LPARAM(ContextCode) << 29) | (LPARAM(extended ? 0x1 : 0x0) << 24) |
          (LPARAM(ScanCode) << 16) | LPARAM(RepeatCount));
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
class SpyKeyEventHandler : public KeyboardHookHandler {
 public:
  SpyKeyEventHandler(flutter::BinaryMessenger* messenger,
                     KeyEventHandler::SendInputDelegate delegate) {
    real_implementation_ =
        std::make_unique<KeyEventHandler>(messenger, delegate);
    ON_CALL(*this, KeyboardHook(_, _, _, _, _, _))
        .WillByDefault(
            Invoke(real_implementation_.get(), &KeyEventHandler::KeyboardHook));
    ON_CALL(*this, TextHook(_, _))
        .WillByDefault(
            Invoke(real_implementation_.get(), &KeyEventHandler::TextHook));
  }

  MOCK_METHOD6(KeyboardHook,
               bool(FlutterWindowsView* window,
                    int key,
                    int scancode,
                    int action,
                    char32_t character,
                    bool extended));
  MOCK_METHOD2(TextHook,
               void(FlutterWindowsView* window, const std::u16string& text));
  MOCK_METHOD0(ComposeBeginHook, void());
  MOCK_METHOD0(ComposeEndHook, void());
  MOCK_METHOD2(ComposeChangeHook, void(const std::u16string& text, int cursor_pos));

 private:
  std::unique_ptr<KeyEventHandler> real_implementation_;
};

// A text input plugin that can be spied on while it forwards calls to the real
// text input plugin.
class SpyTextInputPlugin : public KeyboardHookHandler,
                           public TextInputPluginDelegate {
 public:
  SpyTextInputPlugin(flutter::BinaryMessenger* messenger) {
    real_implementation_ = std::make_unique<TextInputPlugin>(messenger, this);
    ON_CALL(*this, KeyboardHook(_, _, _, _, _, _))
        .WillByDefault(
            Invoke(real_implementation_.get(), &TextInputPlugin::KeyboardHook));
    ON_CALL(*this, TextHook(_, _))
        .WillByDefault(
            Invoke(real_implementation_.get(), &TextInputPlugin::TextHook));
  }

  MOCK_METHOD6(KeyboardHook,
               bool(FlutterWindowsView* window,
                    int key,
                    int scancode,
                    int action,
                    char32_t character,
                    bool extended));
  MOCK_METHOD2(TextHook,
               void(FlutterWindowsView* window, const std::u16string& text));
  MOCK_METHOD0(ComposeBeginHook, void());
  MOCK_METHOD0(ComposeEndHook, void());
  MOCK_METHOD2(ComposeChangeHook, void(const std::u16string& text, int cursor_pos));

  virtual void OnCursorRectUpdated(const Rect& rect) {}

 private:
  std::unique_ptr<TextInputPlugin> real_implementation_;
};

class MockWin32FlutterWindow : public Win32FlutterWindow {
 public:
  MockWin32FlutterWindow() : Win32FlutterWindow(800, 600) {}
  virtual ~MockWin32FlutterWindow() {}

  // Prevent copying.
  MockWin32FlutterWindow(MockWin32FlutterWindow const&) = delete;
  MockWin32FlutterWindow& operator=(MockWin32FlutterWindow const&) = delete;

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
};

// A FlutterWindowsView that overrides the RegisterKeyboardHookHandlers function
// to register the keyboard hook handlers that can be spied upon.
class TestFlutterWindowsView : public FlutterWindowsView {
 public:
  TestFlutterWindowsView(std::unique_ptr<WindowBindingHandler> window_binding,
                         WPARAM virtual_key,
                         bool is_printable = true)
      : FlutterWindowsView(std::move(window_binding)),
        virtual_key_(virtual_key),
        is_printable_(is_printable) {}

  SpyKeyEventHandler* key_event_handler;
  SpyTextInputPlugin* text_input_plugin;

  void InjectPendingEvents(MockWin32FlutterWindow* win32window) {
    while (pending_events_.size() > 0) {
      SimulatedEvent event = pending_events_.front();
      win32window->InjectWindowMessage(event.message, event.wparam,
                                       event.lparam);
      pending_events_.pop_front();
    }
  }

 protected:
  void RegisterKeyboardHookHandlers(
      flutter::BinaryMessenger* messenger) override {
    auto spy_key_event_handler = std::make_unique<SpyKeyEventHandler>(
        messenger, [this](UINT cInputs, LPINPUT pInputs, int cbSize) -> UINT {
          return this->SendInput(cInputs, pInputs, cbSize);
        });
    auto spy_text_input_plugin =
        std::make_unique<SpyTextInputPlugin>(messenger);
    key_event_handler = spy_key_event_handler.get();
    text_input_plugin = spy_text_input_plugin.get();
    AddKeyboardHookHandler(std::move(spy_key_event_handler));
    AddKeyboardHookHandler(std::move(spy_text_input_plugin));
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
    pending_events_.push_back(SimulatedEvent{message, virtual_key_, lparam});
    if (is_printable_ && (kbdinput.dwFlags & KEYEVENTF_KEYUP) == 0) {
      pending_events_.push_back(SimulatedEvent{WM_CHAR, virtual_key_, lparam});
    }
    return 1;
  }

  std::deque<SimulatedEvent> pending_events_;
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

  EngineEmbedderApiModifier modifier(engine.get());
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

TEST(Win32FlutterWindowTest, CreateDestroy) {
  Win32FlutterWindowTest window(800, 600);
  ASSERT_TRUE(TRUE);
}

// Tests key event propagation of non-printable, non-modifier key down events.
TEST(Win32FlutterWindowTest, NonPrintableKeyDownPropagation) {
  constexpr WPARAM virtual_key = VK_LEFT;
  constexpr WPARAM scan_code = 10;
  constexpr char32_t character = 0;
  MockWin32FlutterWindow win32window;
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
                             false /* extended */))
        .Times(2)
        .RetiresOnSaturation();
    EXPECT_CALL(*flutter_windows_view.text_input_plugin,
                KeyboardHook(_, _, _, _, _, _))
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
                             false /* extended */))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*flutter_windows_view.text_input_plugin,
                KeyboardHook(_, _, _, _, _, _))
        .Times(0);
    EXPECT_EQ(win32window.InjectWindowMessage(WM_KEYDOWN, virtual_key, lparam),
              0);
    flutter_windows_view.InjectPendingEvents(&win32window);
  }
}

// Tests key event propagation of printable character key down events. These
// differ from non-printable characters in that they follow a different code
// path in the WndProc (HandleMessage), producing a follow-on WM_CHAR event.
TEST(Win32FlutterWindowTest, CharKeyDownPropagation) {
  constexpr WPARAM virtual_key = 65;  // The "A" key, which produces a character
  constexpr WPARAM scan_code = 30;
  constexpr char32_t character = 65;

  MockWin32FlutterWindow win32window;
  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  TestFlutterWindowsView flutter_windows_view(
      std::move(window_binding_handler), virtual_key, true /* is_printable */);
  win32window.SetView(&flutter_windows_view);
  LPARAM lparam = CreateKeyEventLparam(scan_code);

  // Test an event not handled by the framework
  {
    test_response = false;
    flutter_windows_view.SetEngine(std::move(GetTestEngine()));
    EXPECT_CALL(
        *flutter_windows_view.key_event_handler,
        KeyboardHook(_, virtual_key, scan_code, WM_KEYDOWN, character, false))
        .Times(2)
        .RetiresOnSaturation();
    EXPECT_CALL(*flutter_windows_view.text_input_plugin,
                KeyboardHook(_, _, _, _, _, _))
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

  // Test an event handled by the framework
  {
    test_response = true;
    EXPECT_CALL(*flutter_windows_view.key_event_handler,
                KeyboardHook(_, virtual_key, scan_code, WM_KEYDOWN, character,
                             false /* is_printable */))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*flutter_windows_view.text_input_plugin,
                KeyboardHook(_, _, _, _, _, _))
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
TEST(Win32FlutterWindowTest, ModifierKeyDownPropagation) {
  constexpr WPARAM virtual_key = VK_LSHIFT;
  constexpr WPARAM scan_code = 20;
  constexpr char32_t character = 0;
  MockWin32FlutterWindow win32window;
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
                             false /* extended */))
        .Times(2)
        .RetiresOnSaturation();
    EXPECT_CALL(*flutter_windows_view.text_input_plugin,
                KeyboardHook(_, _, _, _, _, _))
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
                             false /* extended */))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*flutter_windows_view.text_input_plugin,
                KeyboardHook(_, _, _, _, _, _))
        .Times(0);
    EXPECT_EQ(win32window.InjectWindowMessage(WM_KEYDOWN, virtual_key, lparam),
              0);
    flutter_windows_view.InjectPendingEvents(&win32window);
  }
}

}  // namespace testing
}  // namespace flutter
