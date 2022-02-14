// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/json_message_codec.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/test_utils/key_codes.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/keyboard_key_channel_handler.h"
#include "flutter/shell/platform/windows/keyboard_key_embedder_handler.h"
#include "flutter/shell/platform/windows/keyboard_key_handler.h"
#include "flutter/shell/platform/windows/keyboard_manager_win32.h"
#include "flutter/shell/platform/windows/testing/engine_modifier.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler.h"
#include "flutter/shell/platform/windows/testing/test_keyboard.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "rapidjson/stringbuffer.h"
#include "rapidjson/writer.h"

#include <functional>
#include <vector>

using testing::_;
using testing::Invoke;
using testing::Return;
using namespace ::flutter::testing::keycodes;

namespace flutter {
namespace testing {

namespace {

constexpr SHORT kStateMaskToggled = 0x01;
constexpr SHORT kStateMaskPressed = 0x80;

typedef uint32_t (*MapVkToCharHandler)(uint32_t virtual_key);

uint32_t LayoutDefault(uint32_t virtual_key) {
  return MapVirtualKey(virtual_key, MAPVK_VK_TO_CHAR);
}

uint32_t LayoutFrench(uint32_t virtual_key) {
  switch (virtual_key) {
    case 0xDD:
      return 0x8000005E;
    default:
      return MapVirtualKey(virtual_key, MAPVK_VK_TO_CHAR);
  }
}

class TestKeyboardManagerWin32 : public KeyboardManagerWin32 {
 public:
  explicit TestKeyboardManagerWin32(WindowDelegate* delegate)
      : KeyboardManagerWin32(delegate) {}

  bool DuringRedispatch() { return during_redispatch_; }

 protected:
  void RedispatchEvent(std::unique_ptr<PendingEvent> event) override {
    assert(!during_redispatch_);
    during_redispatch_ = true;
    KeyboardManagerWin32::RedispatchEvent(std::move(event));
    during_redispatch_ = false;
  }

 private:
  bool during_redispatch_ = false;
};

struct KeyStateChange {
  uint32_t key;
  bool pressed;
  bool toggled_on;
};

struct KeyboardChange {
  // The constructors are intentionally for implicit conversion.

  KeyboardChange(Win32Message message) : type(kMessage) {
    content.message = message;
  }

  KeyboardChange(KeyStateChange change) : type(kKeyStateChange) {
    content.key_state_change = change;
  }

  enum Type {
    kMessage,
    kKeyStateChange,
  } type;

  union {
    Win32Message message;
    KeyStateChange key_state_change;
  } content;
};

class TestKeystate {
 public:
  void Set(uint32_t virtual_key, bool pressed, bool toggled_on = false) {
    state_[virtual_key] = (pressed ? kStateMaskPressed : 0) |
                          (toggled_on ? kStateMaskToggled : 0);
  }

  SHORT Get(uint32_t virtual_key) { return state_[virtual_key]; }

 private:
  std::map<uint32_t, SHORT> state_;
};

class MockKeyboardManagerWin32Delegate
    : public KeyboardManagerWin32::WindowDelegate,
      protected MockMessageQueue {
 public:
  MockKeyboardManagerWin32Delegate(WindowBindingHandlerDelegate* view)
      : view_(view), map_vk_to_char_(LayoutDefault) {
    keyboard_manager_ = std::make_unique<TestKeyboardManagerWin32>(this);
  }
  virtual ~MockKeyboardManagerWin32Delegate() {}

  // |KeyboardManagerWin32::WindowDelegate|
  void OnKey(int key,
             int scancode,
             int action,
             char32_t character,
             bool extended,
             bool was_down,
             KeyEventCallback callback) override {
    view_->OnKey(key, scancode, action, character, extended, was_down,
                 callback);
  }

  // |KeyboardManagerWin32::WindowDelegate|
  void OnText(const std::u16string& text) override { view_->OnText(text); }

  void SetLayout(MapVkToCharHandler map_vk_to_char) {
    map_vk_to_char_ =
        map_vk_to_char == nullptr ? LayoutDefault : map_vk_to_char;
  }

  SHORT GetKeyState(int virtual_key) { return key_state_.Get(virtual_key); }

  void InjectKeyboardChanges(std::vector<KeyboardChange> changes) {
    for (const KeyboardChange& change : changes) {
      switch (change.type) {
        case KeyboardChange::kMessage:
          PushBack(&change.content.message);
          break;
        default:
          break;
      }
    }
    for (const KeyboardChange& change : changes) {
      switch (change.type) {
        case KeyboardChange::kMessage:
          DispatchFront();
          break;
        case KeyboardChange::kKeyStateChange: {
          const KeyStateChange& state_change = change.content.key_state_change;
          key_state_.Set(state_change.key, state_change.pressed,
                         state_change.toggled_on);
          break;
        }
        default:
          assert(false);
      }
    }
  }

 protected:
  BOOL Win32PeekMessage(LPMSG lpMsg,
                        UINT wMsgFilterMin,
                        UINT wMsgFilterMax,
                        UINT wRemoveMsg) override {
    return MockMessageQueue::Win32PeekMessage(lpMsg, wMsgFilterMin,
                                              wMsgFilterMax, wRemoveMsg);
  }

  uint32_t Win32MapVkToChar(uint32_t virtual_key) override {
    return map_vk_to_char_(virtual_key);
  }

  // This method is called for each message injected by test cases with
  // `tester.InjectMessages`.
  LRESULT Win32SendMessage(UINT const message,
                           WPARAM const wparam,
                           LPARAM const lparam) override {
    return keyboard_manager_->HandleMessage(message, wparam, lparam)
               ? 0
               : kWmResultDefault;
  }

  // This method is called when the keyboard manager redispatches messages
  // or dispatches CtrlLeft up for AltGr.
  UINT Win32DispatchMessage(UINT Msg, WPARAM wParam, LPARAM lParam) override {
    bool handled = keyboard_manager_->HandleMessage(Msg, wParam, lParam);
    if (keyboard_manager_->DuringRedispatch()) {
      EXPECT_FALSE(handled);
    }
    return 0;
  }

 private:
  WindowBindingHandlerDelegate* view_;
  std::unique_ptr<TestKeyboardManagerWin32> keyboard_manager_;
  MapVkToCharHandler map_vk_to_char_;
  TestKeystate key_state_;
};

// A FlutterWindowsView that overrides the RegisterKeyboardHandlers function
// to register the keyboard hook handlers that can be spied upon.
class TestFlutterWindowsView : public FlutterWindowsView {
 public:
  typedef std::function<void(const std::u16string& text)> U16StringHandler;

  TestFlutterWindowsView(
      U16StringHandler on_text,
      KeyboardKeyEmbedderHandler::GetKeyStateHandler get_keyboard_state)
      // The WindowBindingHandler is used for window size and such, and doesn't
      // affect keyboard.
      : FlutterWindowsView(
            std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>()),
        get_keyboard_state_(std::move(get_keyboard_state)),
        on_text_(std::move(on_text)) {}

  void OnText(const std::u16string& text) override { on_text_(text); }

  void HandleMessage(const char* channel,
                     const char* method,
                     const char* args) {
    rapidjson::Document args_doc;
    args_doc.Parse(args);
    assert(!args_doc.HasParseError());

    rapidjson::Document message_doc(rapidjson::kObjectType);
    auto& allocator = message_doc.GetAllocator();
    message_doc.AddMember("method", rapidjson::Value(method, allocator),
                          allocator);
    message_doc.AddMember("args", args_doc, allocator);

    rapidjson::StringBuffer buffer;
    rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
    message_doc.Accept(writer);

    std::unique_ptr<std::vector<uint8_t>> data =
        JsonMessageCodec::GetInstance().EncodeMessage(message_doc);
    FlutterPlatformMessageResponseHandle response_handle;
    const FlutterPlatformMessage message = {
        sizeof(FlutterPlatformMessage),  // struct_size
        channel,                         // channel
        data->data(),                    // message
        data->size(),                    // message_size
        &response_handle,                // response_handle
    };
    GetEngine()->HandlePlatformMessage(&message);
  }

 protected:
  std::unique_ptr<KeyboardHandlerBase> CreateKeyboardKeyHandler(
      BinaryMessenger* messenger,
      KeyboardKeyEmbedderHandler::GetKeyStateHandler get_key_state) override {
    return FlutterWindowsView::CreateKeyboardKeyHandler(
        messenger,
        [this](int virtual_key) { return get_keyboard_state_(virtual_key); });
  }

 private:
  U16StringHandler on_text_;
  KeyboardKeyEmbedderHandler::GetKeyStateHandler get_keyboard_state_;
};

typedef enum {
  kKeyCallOnKey,
  kKeyCallOnText,
  kKeyCallTextMethodCall,
} KeyCallType;

typedef struct {
  KeyCallType type;

  // Only one of the following fields should be assigned.
  FlutterKeyEvent key_event;     // For kKeyCallOnKey
  std::u16string text;           // For kKeyCallOnText
  std::string text_method_call;  // For kKeyCallTextMethodCall
} KeyCall;

static std::vector<KeyCall> key_calls;

void clear_key_calls() {
  for (KeyCall& key_call : key_calls) {
    if (key_call.type == kKeyCallOnKey &&
        key_call.key_event.character != nullptr) {
      delete[] key_call.key_event.character;
    }
  }
  key_calls.clear();
}

class KeyboardTester {
 public:
  using ResponseHandler =
      std::function<void(MockKeyResponseController::ResponseCallback)>;

  explicit KeyboardTester() : callback_handler_(RespondValue(false)) {
    view_ = std::make_unique<TestFlutterWindowsView>(
        [](const std::u16string& text) {
          key_calls.push_back(KeyCall{
              .type = kKeyCallOnText,
              .text = text,
          });
        },
        [this](int virtual_key) -> SHORT {
          // `window_` is not initialized yet when this callback is first
          // called.
          return window_ ? window_->GetKeyState(virtual_key) : 0;
        });
    view_->SetEngine(GetTestEngine(
        [&callback_handler = callback_handler_](
            const FlutterKeyEvent* event,
            MockKeyResponseController::ResponseCallback callback) {
          FlutterKeyEvent clone_event = *event;
          clone_event.character = event->character == nullptr
                                      ? nullptr
                                      : clone_string(event->character);
          key_calls.push_back(KeyCall{
              .type = kKeyCallOnKey,
              .key_event = clone_event,
          });
          callback_handler(event, callback);
        }));
    window_ = std::make_unique<MockKeyboardManagerWin32Delegate>(view_.get());
  }

  TestFlutterWindowsView& GetView() { return *view_; }
  MockKeyboardManagerWin32Delegate& GetWindow() { return *window_; }

  // Set all events to be handled (true) or unhandled (false).
  void Responding(bool response) { callback_handler_ = RespondValue(response); }

  // Manually handle event callback of the onKeyData embedder API.
  //
  // On every onKeyData call, the |handler| will be invoked with the target
  // key data and the result callback. Immediately calling the callback with
  // a boolean is equivalent to setting |Responding| with the boolean. However,
  // |LateResponding| allows storing the callback to call later.
  void LateResponding(
      MockKeyResponseController::EmbedderCallbackHandler handler) {
    callback_handler_ = std::move(handler);
  }

  void SetLayout(MapVkToCharHandler layout) { window_->SetLayout(layout); }

  void InjectKeyboardChanges(std::vector<KeyboardChange> changes) {
    assert(window_ != nullptr);
    window_->InjectKeyboardChanges(changes);
  }

 private:
  std::unique_ptr<TestFlutterWindowsView> view_;
  std::unique_ptr<MockKeyboardManagerWin32Delegate> window_;
  MockKeyResponseController::EmbedderCallbackHandler callback_handler_;

  // Returns an engine instance configured with dummy project path values, and
  // overridden methods for sending platform messages, so that the engine can
  // respond as if the framework were connected.
  static std::unique_ptr<FlutterWindowsEngine> GetTestEngine(
      MockKeyResponseController::EmbedderCallbackHandler
          embedder_callback_handler) {
    FlutterDesktopEngineProperties properties = {};
    properties.assets_path = L"C:\\foo\\flutter_assets";
    properties.icu_data_path = L"C:\\foo\\icudtl.dat";
    properties.aot_library_path = L"C:\\foo\\aot.so";
    FlutterProjectBundle project(properties);
    auto engine = std::make_unique<FlutterWindowsEngine>(project);

    EngineModifier modifier(engine.get());

    auto key_response_controller =
        std::make_shared<MockKeyResponseController>();
    key_response_controller->SetEmbedderResponse(
        std::move(embedder_callback_handler));
    key_response_controller->SetTextInputResponse(
        [](std::unique_ptr<rapidjson::Document> document) {
          rapidjson::StringBuffer buffer;
          rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
          document->Accept(writer);
          key_calls.push_back(KeyCall{
              .type = kKeyCallTextMethodCall,
              .text_method_call = buffer.GetString(),
          });
        });

    MockEmbedderApiForKeyboard(modifier, key_response_controller);

    engine->RunWithEntrypoint(nullptr);
    return engine;
  }

  static MockKeyResponseController::EmbedderCallbackHandler RespondValue(
      bool value) {
    return [value](const FlutterKeyEvent* event,
                   MockKeyResponseController::ResponseCallback callback) {
      callback(value);
    };
  }
};

constexpr uint64_t kScanCodeBackquote = 0x29;
constexpr uint64_t kScanCodeKeyA = 0x1e;
constexpr uint64_t kScanCodeKeyB = 0x30;
constexpr uint64_t kScanCodeKeyE = 0x12;
constexpr uint64_t kScanCodeKeyQ = 0x10;
constexpr uint64_t kScanCodeKeyW = 0x11;
constexpr uint64_t kScanCodeDigit1 = 0x02;
constexpr uint64_t kScanCodeDigit6 = 0x07;
// constexpr uint64_t kScanCodeNumpad1 = 0x4f;
// constexpr uint64_t kScanCodeNumLock = 0x45;
constexpr uint64_t kScanCodeControl = 0x1d;
constexpr uint64_t kScanCodeMetaLeft = 0x5b;
constexpr uint64_t kScanCodeMetaRight = 0x5c;
constexpr uint64_t kScanCodeAlt = 0x38;
constexpr uint64_t kScanCodeShiftLeft = 0x2a;
constexpr uint64_t kScanCodeShiftRight = 0x36;
constexpr uint64_t kScanCodeBracketLeft = 0x1a;
constexpr uint64_t kScanCodeArrowLeft = 0x4b;
constexpr uint64_t kScanCodeEnter = 0x1c;

constexpr uint64_t kVirtualDigit1 = 0x31;
constexpr uint64_t kVirtualKeyA = 0x41;
constexpr uint64_t kVirtualKeyB = 0x42;
constexpr uint64_t kVirtualKeyE = 0x45;
constexpr uint64_t kVirtualKeyQ = 0x51;
constexpr uint64_t kVirtualKeyW = 0x57;

constexpr bool kSynthesized = true;
constexpr bool kNotSynthesized = false;

}  // namespace

// Define compound `expect` in macros. If they're defined in functions, the
// stacktrace wouldn't print where the function is called in the unit tests.

#define EXPECT_CALL_IS_EVENT(_key_call, ...) \
  EXPECT_EQ(_key_call.type, kKeyCallOnKey);  \
  EXPECT_EVENT_EQUALS(_key_call.key_event, __VA_ARGS__);

#define EXPECT_CALL_IS_TEXT(_key_call, u16_string) \
  EXPECT_EQ(_key_call.type, kKeyCallOnText);       \
  EXPECT_EQ(_key_call.text, u16_string);

#define EXPECT_CALL_IS_TEXT_METHOD_CALL(_key_call, json_string) \
  EXPECT_EQ(_key_call.type, kKeyCallTextMethodCall);            \
  EXPECT_STREQ(_key_call.text_method_call.c_str(), json_string);

TEST(KeyboardTest, LowerCaseAHandled) {
  KeyboardTester tester;
  tester.Responding(true);

  // US Keyboard layout

  // Press A
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{'a', kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyA,
                       kLogicalKeyA, "a", kNotSynthesized);
  clear_key_calls();

  // Release A
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyA,
                       kLogicalKeyA, "", kNotSynthesized);
  clear_key_calls();
}

TEST(KeyboardTest, LowerCaseAUnhandled) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout

  // Press A
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{'a', kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyA,
                       kLogicalKeyA, "a", kNotSynthesized);
  EXPECT_CALL_IS_TEXT(key_calls[1], u"a");
  clear_key_calls();

  // Release A
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyA,
                       kLogicalKeyA, "", kNotSynthesized);
  clear_key_calls();
}

TEST(KeyboardTest, ArrowLeftHandled) {
  KeyboardTester tester;
  tester.Responding(true);

  // US Keyboard layout

  // Press ArrowLeft
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{VK_LEFT, kScanCodeArrowLeft, kExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalArrowLeft, kLogicalArrowLeft, "",
                       kNotSynthesized);
  clear_key_calls();

  // Release ArrowLeft
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{VK_LEFT, kScanCodeArrowLeft, kExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalArrowLeft,
                       kLogicalArrowLeft, "", kNotSynthesized);
  clear_key_calls();
}

TEST(KeyboardTest, ArrowLeftUnhandled) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout

  // Press ArrowLeft
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{VK_LEFT, kScanCodeArrowLeft, kExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalArrowLeft, kLogicalArrowLeft, "",
                       kNotSynthesized);
  clear_key_calls();

  // Release ArrowLeft
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{VK_LEFT, kScanCodeArrowLeft, kExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalArrowLeft,
                       kLogicalArrowLeft, "", kNotSynthesized);
  clear_key_calls();
}

TEST(KeyboardTest, ShiftLeftUnhandled) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout

  // Press ShiftLeft
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LSHIFT, true, false},
      WmKeyDownInfo{VK_SHIFT, kScanCodeShiftLeft, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalShiftLeft, kLogicalShiftLeft, "",
                       kNotSynthesized);
  clear_key_calls();

  // Release ShiftLeft
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LSHIFT, false, true},
      WmKeyUpInfo{VK_SHIFT, kScanCodeShiftLeft, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalShiftLeft,
                       kLogicalShiftLeft, "", kNotSynthesized);
  clear_key_calls();
}

TEST(KeyboardTest, ShiftRightUnhandled) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout

  // Press ShiftRight
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_RSHIFT, true, false},
      WmKeyDownInfo{VK_SHIFT, kScanCodeShiftRight, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalShiftRight, kLogicalShiftRight, "",
                       kNotSynthesized);
  clear_key_calls();

  // Release ShiftRight
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_RSHIFT, false, true},
      WmKeyUpInfo{VK_SHIFT, kScanCodeShiftRight, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp,
                       kPhysicalShiftRight, kLogicalShiftRight, "",
                       kNotSynthesized);
  clear_key_calls();
}

TEST(KeyboardTest, CtrlLeftUnhandled) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout

  // Press CtrlLeft
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LCONTROL, true, false},
      WmKeyDownInfo{VK_CONTROL, kScanCodeControl, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalControlLeft, kLogicalControlLeft, "",
                       kNotSynthesized);
  clear_key_calls();

  // Release CtrlLeft
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LCONTROL, false, true},
      WmKeyUpInfo{VK_SHIFT, kScanCodeControl, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp,
                       kPhysicalControlLeft, kLogicalControlLeft, "",
                       kNotSynthesized);
  clear_key_calls();
}

TEST(KeyboardTest, CtrlRightUnhandled) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout

  // Press CtrlRight
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_RCONTROL, true, false},
      WmKeyDownInfo{VK_CONTROL, kScanCodeControl, kExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalControlRight, kLogicalControlRight, "",
                       kNotSynthesized);
  clear_key_calls();

  // Release CtrlRight
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_RCONTROL, false, true},
      WmKeyUpInfo{VK_CONTROL, kScanCodeControl, kExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp,
                       kPhysicalControlRight, kLogicalControlRight, "",
                       kNotSynthesized);
  clear_key_calls();
}

TEST(KeyboardTest, AltLeftUnhandled) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout

  // Press AltLeft. AltLeft is a SysKeyDown event.
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LMENU, true, false},
      WmSysKeyDownInfo{VK_MENU, kScanCodeAlt, kNotExtended, kWasUp}.Build(
          kWmResultDefault)});  // Always pass to the default WndProc.

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalAltLeft,
                       kLogicalAltLeft, "", kNotSynthesized);
  clear_key_calls();

  // Release AltLeft. AltLeft is a SysKeyUp event.
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LMENU, false, true},
      WmSysKeyUpInfo{VK_MENU, kScanCodeAlt, kNotExtended}.Build(
          kWmResultDefault)});  // Always pass to the default WndProc.

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalAltLeft,
                       kLogicalAltLeft, "", kNotSynthesized);
  clear_key_calls();
}

TEST(KeyboardTest, AltRightUnhandled) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout

  // Press AltRight. AltRight is a SysKeyDown event.
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_RMENU, true, false},
      WmSysKeyDownInfo{VK_MENU, kScanCodeAlt, kExtended, kWasUp}.Build(
          kWmResultDefault)});  // Always pass to the default WndProc.

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalAltRight, kLogicalAltRight, "",
                       kNotSynthesized);
  clear_key_calls();

  // Release AltRight. AltRight is a SysKeyUp event.
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_RMENU, false, true},
      WmSysKeyUpInfo{VK_MENU, kScanCodeAlt, kExtended}.Build(
          kWmResultDefault)});  // Always pass to the default WndProc.

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalAltRight,
                       kLogicalAltRight, "", kNotSynthesized);
  clear_key_calls();
}

TEST(KeyboardTest, MetaLeftUnhandled) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout

  // Press MetaLeft
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LWIN, true, false},
      WmKeyDownInfo{VK_LWIN, kScanCodeMetaLeft, kExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalMetaLeft, kLogicalMetaLeft, "",
                       kNotSynthesized);
  clear_key_calls();

  // Release MetaLeft
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LWIN, false, true},
      WmKeyUpInfo{VK_LWIN, kScanCodeMetaLeft, kExtended}.Build(kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalMetaLeft,
                       kLogicalMetaLeft, "", kNotSynthesized);
  clear_key_calls();
}

TEST(KeyboardTest, MetaRightUnhandled) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout

  // Press MetaRight
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_RWIN, true, false},
      WmKeyDownInfo{VK_RWIN, kScanCodeMetaRight, kExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalMetaRight, kLogicalMetaRight, "",
                       kNotSynthesized);
  clear_key_calls();

  // Release MetaRight
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_RWIN, false, true},
      WmKeyUpInfo{VK_RWIN, kScanCodeMetaRight, kExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalMetaRight,
                       kLogicalMetaRight, "", kNotSynthesized);
  clear_key_calls();
}

// Press Shift-A. This is special because Win32 gives 'A' as character for the
// KeyA press.
TEST(KeyboardTest, ShiftLeftKeyA) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout

  // Press ShiftLeft
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LSHIFT, true, true},
      WmKeyDownInfo{VK_SHIFT, kScanCodeShiftLeft, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalShiftLeft, kLogicalShiftLeft, "",
                       kNotSynthesized);
  clear_key_calls();

  // Press A
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{'A', kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyA,
                       kLogicalKeyA, "A", kNotSynthesized);
  EXPECT_CALL_IS_TEXT(key_calls[1], u"A");
  clear_key_calls();

  // Release ShiftLeft
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LSHIFT, false, true},
      WmKeyUpInfo{VK_SHIFT, kScanCodeShiftLeft, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalShiftLeft,
                       kLogicalShiftLeft, "", kNotSynthesized);
  clear_key_calls();

  // Release A
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyA,
                       kLogicalKeyA, "", kNotSynthesized);
  clear_key_calls();
}

// Press Ctrl-A. This is special because Win32 gives 0x01 as character for the
// KeyA press.
TEST(KeyboardTest, CtrlLeftKeyA) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout

  // Press ControlLeft
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LCONTROL, true, true},
      WmKeyDownInfo{VK_CONTROL, kScanCodeControl, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalControlLeft, kLogicalControlLeft, "",
                       kNotSynthesized);
  clear_key_calls();

  // Press A
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{0x01, kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyA,
                       kLogicalKeyA, "", kNotSynthesized);
  clear_key_calls();

  // Release A
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyA,
                       kLogicalKeyA, "", kNotSynthesized);
  clear_key_calls();

  // Release ControlLeft
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LCONTROL, false, true},
      WmKeyUpInfo{VK_CONTROL, kScanCodeControl, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp,
                       kPhysicalControlLeft, kLogicalControlLeft, "",
                       kNotSynthesized);
  clear_key_calls();
}

// Press Ctrl-1. This is special because it yields no WM_CHAR for the 1.
TEST(KeyboardTest, CtrlLeftDigit1) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout

  // Press ControlLeft
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LCONTROL, true, true},
      WmKeyDownInfo{VK_CONTROL, kScanCodeControl, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalControlLeft, kLogicalControlLeft, "",
                       kNotSynthesized);
  clear_key_calls();

  // Press 1
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{kVirtualDigit1, kScanCodeDigit1, kNotExtended, kWasUp}
          .Build(kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalDigit1,
                       kLogicalDigit1, "", kNotSynthesized);
  clear_key_calls();

  // Release 1
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{kVirtualDigit1, kScanCodeDigit1, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalDigit1,
                       kLogicalDigit1, "", kNotSynthesized);
  clear_key_calls();

  // Release ControlLeft
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LCONTROL, false, true},
      WmKeyUpInfo{VK_CONTROL, kScanCodeControl, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp,
                       kPhysicalControlLeft, kLogicalControlLeft, "",
                       kNotSynthesized);
  clear_key_calls();
}

// Press 1 on a French keyboard. This is special because it yields WM_CHAR
// with char_code '&'.
TEST(KeyboardTest, Digit1OnFrenchLayout) {
  KeyboardTester tester;
  tester.Responding(false);

  tester.SetLayout(LayoutFrench);

  // Press 1
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{kVirtualDigit1, kScanCodeDigit1, kNotExtended, kWasUp}
          .Build(kWmResultZero),
      WmCharInfo{'&', kScanCodeDigit1, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalDigit1,
                       kLogicalDigit1, "&", kNotSynthesized);
  EXPECT_CALL_IS_TEXT(key_calls[1], u"&");
  clear_key_calls();

  // Release 1
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{kVirtualDigit1, kScanCodeDigit1, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalDigit1,
                       kLogicalDigit1, "", kNotSynthesized);
  clear_key_calls();
}

// This tests AltGr-Q on a German keyboard, which should print '@'.
TEST(KeyboardTest, AltGrModifiedKey) {
  KeyboardTester tester;
  tester.Responding(false);

  // German Keyboard layout

  // Press AltGr, which Win32 precedes with a ContrlLeft down.
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LCONTROL, true, true},
      WmKeyDownInfo{VK_LCONTROL, kScanCodeControl, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmKeyDownInfo{VK_MENU, kScanCodeAlt, kExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalControlLeft, kLogicalControlLeft, "",
                       kNotSynthesized);
  EXPECT_CALL_IS_EVENT(key_calls[1], kFlutterKeyEventTypeDown,
                       kPhysicalAltRight, kLogicalAltRight, "",
                       kNotSynthesized);
  clear_key_calls();

  // Press Q
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{kVirtualKeyQ, kScanCodeKeyQ, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{'@', kScanCodeKeyQ, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyQ,
                       kLogicalKeyQ, "@", kNotSynthesized);
  EXPECT_CALL_IS_TEXT(key_calls[1], u"@");
  clear_key_calls();

  // Release Q
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{kVirtualKeyQ, kScanCodeKeyQ, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyQ,
                       kLogicalKeyQ, "", kNotSynthesized);
  clear_key_calls();

  // Release AltGr. Win32 doesn't dispatch ControlLeft up. Instead Flutter will
  // dispatch one. The AltGr is a system key, therefore will be handled by
  // Win32's default WndProc.
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LCONTROL, false, true},
      WmSysKeyUpInfo{VK_MENU, kScanCodeAlt, kExtended}.Build(
          kWmResultDefault)});

  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp,
                       kPhysicalControlLeft, kLogicalControlLeft, "",
                       kNotSynthesized);
  EXPECT_CALL_IS_EVENT(key_calls[1], kFlutterKeyEventTypeUp, kPhysicalAltRight,
                       kLogicalAltRight, "", kNotSynthesized);
  clear_key_calls();
}

// Test the following two key sequences at the same time:
//
// 1. Tap AltGr, then tap AltGr.
// 2. Tap AltGr, hold CtrlLeft, tap AltGr, release CtrlLeft.
//
// The two sequences are indistinguishable until the very end when a CtrlLeft
// up event might or might not follow.
//
//   Sequence 1: CtrlLeft down, AltRight down, AltRight up
//   Sequence 2: CtrlLeft down, AltRight down, AltRight up, CtrlLeft up
//
// This is because pressing AltGr alone causes Win32 to send a fake "CtrlLeft
// down" event first (see |IsKeyDownAltRight| for detailed explanation).
TEST(KeyboardTest, AltGrTwice) {
  KeyboardTester tester;
  tester.Responding(false);

  // 1. AltGr down.

  // The key down event causes a ControlLeft down and a AltRight (extended
  // AltLeft) down.
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LCONTROL, true, true},
      WmKeyDownInfo{VK_LCONTROL, kScanCodeControl, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmKeyDownInfo{VK_MENU, kScanCodeAlt, kExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalControlLeft, kLogicalControlLeft, "",
                       kNotSynthesized);
  EXPECT_CALL_IS_EVENT(key_calls[1], kFlutterKeyEventTypeDown,
                       kPhysicalAltRight, kLogicalAltRight, "",
                       kNotSynthesized);
  clear_key_calls();

  // 2. AltGr up.

  // The key up event only causes a AltRight (extended AltLeft) up.
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LCONTROL, false, true},
      KeyStateChange{VK_RMENU, false, true},
      WmSysKeyUpInfo{VK_MENU, kScanCodeAlt, kExtended}.Build(
          kWmResultDefault)});
  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp,
                       kPhysicalControlLeft, kLogicalControlLeft, "",
                       kNotSynthesized);
  EXPECT_CALL_IS_EVENT(key_calls[1], kFlutterKeyEventTypeUp, kPhysicalAltRight,
                       kLogicalAltRight, "", kNotSynthesized);
  clear_key_calls();

  // 3. AltGr down (or: ControlLeft down then AltRight down.)

  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LCONTROL, true, false},
      WmKeyDownInfo{VK_LCONTROL, kScanCodeControl, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmKeyDownInfo{VK_MENU, kScanCodeAlt, kExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalControlLeft, kLogicalControlLeft, "",
                       kNotSynthesized);
  EXPECT_CALL_IS_EVENT(key_calls[1], kFlutterKeyEventTypeDown,
                       kPhysicalAltRight, kLogicalAltRight, "",
                       kNotSynthesized);
  clear_key_calls();

  // 4. AltGr up.

  // The key up event only causes a AltRight (extended AltLeft) up.
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_RMENU, false, false},
      KeyStateChange{VK_LCONTROL, false, false},
      WmSysKeyUpInfo{VK_MENU, kScanCodeAlt, kExtended}.Build(
          kWmResultDefault)});
  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp,
                       kPhysicalControlLeft, kLogicalControlLeft, "",
                       kNotSynthesized);
  EXPECT_CALL_IS_EVENT(key_calls[1], kFlutterKeyEventTypeUp, kPhysicalAltRight,
                       kLogicalAltRight, "", kNotSynthesized);
  clear_key_calls();

  // 5. For key sequence 2: a real ControlLeft up.
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{VK_LCONTROL, kScanCodeControl, kNotExtended}.Build(
          kWmResultZero)});
  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, 0, 0, "",
                       kNotSynthesized);
  clear_key_calls();
}

// This tests dead key ^ then E on a French keyboard, which should be combined
// into ê.
TEST(KeyboardTest, DeadKeyThatCombines) {
  KeyboardTester tester;
  tester.Responding(false);

  tester.SetLayout(LayoutFrench);

  // Press ^¨ (US: Left bracket)
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{0xDD, kScanCodeBracketLeft, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmDeadCharInfo{'^', kScanCodeBracketLeft, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalBracketLeft, kLogicalBracketRight, "^",
                       kNotSynthesized);
  clear_key_calls();

  // Release ^¨
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{0xDD, kScanCodeBracketLeft, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp,
                       kPhysicalBracketLeft, kLogicalBracketRight, "",
                       kNotSynthesized);
  clear_key_calls();

  // Press E
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{kVirtualKeyE, kScanCodeKeyE, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{0xEA, kScanCodeKeyE, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyE,
                       kLogicalKeyE, "ê", kNotSynthesized);
  EXPECT_CALL_IS_TEXT(key_calls[1], u"ê");
  clear_key_calls();

  // Release E
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{kVirtualKeyE, kScanCodeKeyE, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyE,
                       kLogicalKeyE, "", kNotSynthesized);
  clear_key_calls();
}

// This tests dead key ^ then E on a US INTL keyboard, which should be combined
// into ê.
//
// It is different from French AZERTY because the character that the ^ key is
// mapped to does not contain the dead key character somehow.
TEST(KeyboardTest, DeadKeyWithoutDeadMaskThatCombines) {
  KeyboardTester tester;
  tester.Responding(false);

  // Press ShiftLeft
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LSHIFT, true, true},
      WmKeyDownInfo{VK_SHIFT, kScanCodeShiftLeft, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalShiftLeft, kLogicalShiftLeft, "",
                       kNotSynthesized);
  clear_key_calls();

  // Press 6^
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{'6', kScanCodeDigit6, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmDeadCharInfo{'^', kScanCodeDigit6, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalDigit6,
                       kLogicalDigit6, "6", kNotSynthesized);
  clear_key_calls();

  // Release 6^
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{'6', kScanCodeDigit6, kNotExtended}.Build(kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalDigit6,
                       kLogicalDigit6, "", kNotSynthesized);
  clear_key_calls();

  // Release ShiftLeft
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_LSHIFT, false, true},
      WmKeyUpInfo{VK_SHIFT, kScanCodeShiftLeft, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalShiftLeft,
                       kLogicalShiftLeft, "", kNotSynthesized);
  clear_key_calls();

  // Press E
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{kVirtualKeyE, kScanCodeKeyE, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{0xEA, kScanCodeKeyE, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyE,
                       kLogicalKeyE, "ê", kNotSynthesized);
  EXPECT_CALL_IS_TEXT(key_calls[1], u"ê");
  clear_key_calls();

  // Release E
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{kVirtualKeyE, kScanCodeKeyE, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyE,
                       kLogicalKeyE, "", kNotSynthesized);
  clear_key_calls();
}

// This tests dead key ^ then & (US: 1) on a French keyboard, which do not
// combine and should output "^&".
TEST(KeyboardTest, DeadKeyThatDoesNotCombine) {
  KeyboardTester tester;
  tester.Responding(false);

  tester.SetLayout(LayoutFrench);

  // Press ^¨ (US: Left bracket)
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{0xDD, kScanCodeBracketLeft, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmDeadCharInfo{'^', kScanCodeBracketLeft, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalBracketLeft, kLogicalBracketRight, "^",
                       kNotSynthesized);
  clear_key_calls();

  // Release ^¨
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{0xDD, kScanCodeBracketLeft, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp,
                       kPhysicalBracketLeft, kLogicalBracketRight, "",
                       kNotSynthesized);
  clear_key_calls();

  // Press 1
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{kVirtualDigit1, kScanCodeDigit1, kNotExtended, kWasUp}
          .Build(kWmResultZero),
      WmCharInfo{'^', kScanCodeDigit1, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{'&', kScanCodeDigit1, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 3);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalDigit1,
                       kLogicalDigit1, "^", kNotSynthesized);
  EXPECT_CALL_IS_TEXT(key_calls[1], u"^");
  EXPECT_CALL_IS_TEXT(key_calls[2], u"&");
  clear_key_calls();

  // Release 1
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{kVirtualDigit1, kScanCodeDigit1, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalDigit1,
                       kLogicalDigit1, "", kNotSynthesized);
  clear_key_calls();
}

// This tests dead key `, then dead key `, then e.
//
// It should output ``e, instead of `è.
TEST(KeyboardTest, DeadKeyTwiceThenLetter) {
  KeyboardTester tester;
  tester.Responding(false);

  // US INTL layout.

  // Press `
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{0xC0, kScanCodeBackquote, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmDeadCharInfo{'`', kScanCodeBackquote, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalBackquote, kLogicalBackquote, "`",
                       kNotSynthesized);
  clear_key_calls();

  // Release `
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{0xC0, kScanCodeBackquote, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalBackquote,
                       kLogicalBackquote, "", kNotSynthesized);
  clear_key_calls();

  // Press ` again.
  // The response should be slow.
  std::vector<MockKeyResponseController::ResponseCallback> recorded_callbacks;
  tester.LateResponding(
      [&recorded_callbacks](
          const FlutterKeyEvent* event,
          MockKeyResponseController::ResponseCallback callback) {
        recorded_callbacks.push_back(callback);
      });

  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{0xC0, kScanCodeBackquote, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{'`', kScanCodeBackquote, kNotExtended, kWasUp, kBeingReleased,
                 kNoContext, 1, /*bit25*/ true}
          .Build(kWmResultZero),
      WmCharInfo{'`', kScanCodeBackquote, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(recorded_callbacks.size(), 1);
  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalBackquote, kLogicalBackquote, "`",
                       kNotSynthesized);
  clear_key_calls();
  // Key down event responded with false.
  recorded_callbacks.front()(false);
  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_TEXT(key_calls[0], u"`");
  EXPECT_CALL_IS_TEXT(key_calls[1], u"`");
  clear_key_calls();

  tester.Responding(false);

  // Release `
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{0xC0, kScanCodeBackquote, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalBackquote,
                       kLogicalBackquote, "", kNotSynthesized);
  clear_key_calls();
}

// This tests when the resulting character needs to be combined with surrogates.
TEST(KeyboardTest, MultibyteCharacter) {
  KeyboardTester tester;
  tester.Responding(false);

  // Gothic Keyboard layout. (We need a layout that yields non-BMP characters
  // without IME, which is actually very rare.)

  // Press key W of a US keyboard, which should yield character '𐍅'.
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{kVirtualKeyW, kScanCodeKeyW, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{0xd800, kScanCodeKeyW, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{0xdf45, kScanCodeKeyW, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  const char* st = key_calls[0].key_event.character;

  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyW,
                       kLogicalKeyW, "𐍅", kNotSynthesized);
  EXPECT_CALL_IS_TEXT(key_calls[1], u"𐍅");
  clear_key_calls();

  // Release W
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{kVirtualKeyW, kScanCodeKeyW, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyW,
                       kLogicalKeyW, "", kNotSynthesized);
  clear_key_calls();
}

// A key down event for shift right must not be redispatched even if
// the framework returns unhandled.
//
// The reason for this test is documented in |IsKeyDownShiftRight|.
TEST(KeyboardTest, NeverRedispatchShiftRightKeyDown) {
  KeyboardTester tester;
  tester.Responding(false);

  // Press ShiftRight and the delegate responds false.
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_RSHIFT, true, true},
      WmKeyDownInfo{VK_SHIFT, kScanCodeShiftRight, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  clear_key_calls();
}

// Pressing modifiers during IME events should work properly by not sending any
// events.
//
// Regression test for https://github.com/flutter/flutter/issues/95888 .
TEST(KeyboardTest, ImeModifierEventsAreIgnored) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout.

  // To make the keyboard into IME mode, there should have been events like
  // letter key down with VK_PROCESSKEY. Omit them in this test since they don't
  // seem significant.

  // Press CtrlRight in IME mode.
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      KeyStateChange{VK_RCONTROL, true, false},
      WmKeyDownInfo{VK_PROCESSKEY, kScanCodeControl, kExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, 0, 0, "",
                       kNotSynthesized);
  clear_key_calls();
}

TEST(KeyboardTest, DisorderlyRespondedEvents) {
  KeyboardTester tester;

  // Store callbacks to manually call them.
  std::vector<MockKeyResponseController::ResponseCallback> recorded_callbacks;
  tester.LateResponding(
      [&recorded_callbacks](
          const FlutterKeyEvent* event,
          MockKeyResponseController::ResponseCallback callback) {
        recorded_callbacks.push_back(callback);
      });

  // Press A
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{'a', kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  // Press B
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{kVirtualKeyB, kScanCodeKeyB, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{'b', kScanCodeKeyB, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_EQ(recorded_callbacks.size(), 2);
  clear_key_calls();

  // Resolve the second event first to test disordered responses.
  recorded_callbacks.back()(false);

  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();

  // Resolve the first event.
  recorded_callbacks.front()(false);

  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_TEXT(key_calls[0], u"a");
  EXPECT_CALL_IS_TEXT(key_calls[1], u"b");
  clear_key_calls();
}

// Regression test for a crash in an earlier implementation.
//
// In real life, the framework responds slowly. The next real event might
// arrive earlier than the framework response, and if the 2nd event has an
// identical hash as the one waiting for response, an earlier implementation
// will crash upon the response.
TEST(KeyboardTest, SlowFrameworkResponse) {
  KeyboardTester tester;

  std::vector<MockKeyResponseController::ResponseCallback> recorded_callbacks;

  // Store callbacks to manually call them.
  tester.LateResponding(
      [&recorded_callbacks](
          const FlutterKeyEvent* event,
          MockKeyResponseController::ResponseCallback callback) {
        recorded_callbacks.push_back(callback);
      });

  // Press A
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{'a', kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  // Hold A
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended, kWasDown}.Build(
          kWmResultZero),
      WmCharInfo{'a', kScanCodeKeyA, kNotExtended, kWasDown}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_EQ(recorded_callbacks.size(), 2);
  clear_key_calls();

  // The first response.
  recorded_callbacks.front()(false);

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_TEXT(key_calls[0], u"a");
  clear_key_calls();

  // The second response.
  recorded_callbacks.back()(false);

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_TEXT(key_calls[0], u"a");
  clear_key_calls();
}

// Regression test for https://github.com/flutter/flutter/issues/84210.
//
// When the framework response is slow during a sequence of identical messages,
// make sure the real messages are not mistaken as redispatched messages,
// in order to not mess up the order of events.
//
// In this test we use:
//
//   KeyA down, KeyA up, (down event responded with false), KeyA down, KeyA up,
//
// The code must not take the 2nd real key down events as a redispatched event.
TEST(KeyboardTest, SlowFrameworkResponseForIdenticalEvents) {
  KeyboardTester tester;

  std::vector<MockKeyResponseController::ResponseCallback> recorded_callbacks;

  // Store callbacks to manually call them.
  tester.LateResponding(
      [&recorded_callbacks](
          const FlutterKeyEvent* event,
          MockKeyResponseController::ResponseCallback callback) {
        recorded_callbacks.push_back(callback);
      });

  // Press A
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{'a', kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyA,
                       kLogicalKeyA, "a", kNotSynthesized);
  clear_key_calls();

  // Release A
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyA,
                       kLogicalKeyA, "", kNotSynthesized);
  clear_key_calls();

  // The first down event responded with false.
  EXPECT_EQ(recorded_callbacks.size(), 2);
  recorded_callbacks.front()(false);

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_TEXT(key_calls[0], u"a");
  clear_key_calls();

  // Press A again
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{'a', kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyA,
                       kLogicalKeyA, "a", kNotSynthesized);
  clear_key_calls();

  // Release A again
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyA,
                       kLogicalKeyA, "", kNotSynthesized);
  clear_key_calls();
}

TEST(KeyboardTest, TextInputSubmit) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout

  tester.GetView().HandleMessage(
      "flutter/textinput", "TextInput.setClient",
      R"|([108, {"inputAction": "TextInputAction.none"}])|");

  // Press Enter
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{VK_RETURN, kScanCodeEnter, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{'\n', kScanCodeEnter, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalEnter,
                       kLogicalEnter, "", kNotSynthesized);
  EXPECT_CALL_IS_TEXT_METHOD_CALL(
      key_calls[1],
      "{"
      R"|("method":"TextInputClient.performAction",)|"
      R"|("args":[108,"TextInputAction.none"])|"
      "}");
  clear_key_calls();

  // Release Enter
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{VK_RETURN, kScanCodeEnter, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalEnter,
                       kLogicalEnter, "", kNotSynthesized);
  clear_key_calls();

  // Make sure OnText is not obstructed after pressing Enter.
  //
  // Regression test for https://github.com/flutter/flutter/issues/97706.

  // Press A
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyDownInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{'a', kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyA,
                       kLogicalKeyA, "a", kNotSynthesized);
  EXPECT_CALL_IS_TEXT(key_calls[1], u"a");
  clear_key_calls();

  // Release A
  tester.InjectKeyboardChanges(std::vector<KeyboardChange>{
      WmKeyUpInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended}.Build(
          kWmResultZero)});

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyA,
                       kLogicalKeyA, "", kNotSynthesized);
  clear_key_calls();
}

}  // namespace testing
}  // namespace flutter
