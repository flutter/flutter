// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

static LPARAM CreateKeyEventLparam(USHORT scancode,
                                   bool extended,
                                   bool was_down,
                                   USHORT repeat_count = 1,
                                   bool context_code = 0,
                                   bool transition_state = 0) {
  return ((LPARAM(transition_state) << 31) | (LPARAM(was_down) << 30) |
          (LPARAM(context_code) << 29) | (LPARAM(extended ? 0x1 : 0x0) << 24) |
          (LPARAM(scancode) << 16) | LPARAM(repeat_count));
}

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

class MockKeyboardManagerWin32Delegate
    : public KeyboardManagerWin32::WindowDelegate,
      public MockMessageQueue {
 public:
  MockKeyboardManagerWin32Delegate(WindowBindingHandlerDelegate* view)
      : view_(view), map_vk_to_char_(LayoutDefault) {
    keyboard_manager_ = std::make_unique<KeyboardManagerWin32>(this);
  }
  virtual ~MockKeyboardManagerWin32Delegate() {}

  // |WindowWin32|
  bool OnKey(int key,
             int scancode,
             int action,
             char32_t character,
             bool extended,
             bool was_down) override {
    return view_->OnKey(key, scancode, action, character, extended, was_down);
  }

  // |WindowWin32|
  void OnText(const std::u16string& text) override { view_->OnText(text); }

  void SetLayout(MapVkToCharHandler map_vk_to_char) {
    map_vk_to_char_ =
        map_vk_to_char == nullptr ? LayoutDefault : map_vk_to_char;
  }

 protected:
  virtual BOOL Win32PeekMessage(LPMSG lpMsg,
                                UINT wMsgFilterMin,
                                UINT wMsgFilterMax,
                                UINT wRemoveMsg) override {
    return MockMessageQueue::Win32PeekMessage(lpMsg, wMsgFilterMin,
                                              wMsgFilterMax, wRemoveMsg);
  }

  virtual uint32_t Win32MapVkToChar(uint32_t virtual_key) override {
    return map_vk_to_char_(virtual_key);
  }

  virtual LRESULT Win32SendMessage(UINT const message,
                                   WPARAM const wparam,
                                   LPARAM const lparam) override {
    return keyboard_manager_->HandleMessage(message, wparam, lparam)
               ? 0
               : kWmResultDefault;
  }

 private:
  WindowBindingHandlerDelegate* view_;

  std::unique_ptr<KeyboardManagerWin32> keyboard_manager_;

  MapVkToCharHandler map_vk_to_char_;
};

class TestKeystate {
 public:
  void Set(uint32_t virtual_key, bool pressed, bool toggled_on = false) {
    state_[virtual_key] = (pressed ? kStateMaskPressed : 0) |
                          (toggled_on ? kStateMaskToggled : 0);
  }

  SHORT Get(uint32_t virtual_key) { return state_[virtual_key]; }

  KeyboardKeyEmbedderHandler::GetKeyStateHandler Getter() {
    return [this](uint32_t virtual_key) { return Get(virtual_key); };
  }

 private:
  std::map<uint32_t, SHORT> state_;
};

typedef struct {
  UINT cInputs;
  KEYBDINPUT kbdinput;
  int cbSize;
} SendInputInfo;

// A FlutterWindowsView that overrides the RegisterKeyboardHandlers function
// to register the keyboard hook handlers that can be spied upon.
class TestFlutterWindowsView : public FlutterWindowsView {
 public:
  typedef std::function<void(const std::u16string& text)> U16StringHandler;

  TestFlutterWindowsView(U16StringHandler on_text)
      // The WindowBindingHandler is used for window size and such, and doesn't
      // affect keyboard.
      : FlutterWindowsView(
            std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>()),
        on_text_(std::move(on_text)),
        redispatch_char(0) {}

  uint32_t redispatch_char;

  void OnText(const std::u16string& text) override { on_text_(text); }

  int InjectPendingEvents(MockMessageQueue* queue, uint32_t redispatch_char) {
    std::vector<Win32Message> messages;
    int num_pending_responds = pending_responds_.size();
    for (const SendInputInfo& input : pending_responds_) {
      const KEYBDINPUT kbdinput = input.kbdinput;
      const UINT message =
          (kbdinput.dwFlags & KEYEVENTF_KEYUP) ? WM_KEYUP : WM_KEYDOWN;
      const bool is_key_up = kbdinput.dwFlags & KEYEVENTF_KEYUP;
      const LPARAM lparam = CreateKeyEventLparam(
          kbdinput.wScan, kbdinput.dwFlags & KEYEVENTF_EXTENDEDKEY, is_key_up);
      // TODO(dkwingsmt): Don't check the message results for redispatched
      // messages for now, because making them work takes non-trivial rework
      // to our current structure.
      // https://github.com/flutter/flutter/issues/87843 If this is resolved,
      // change them to kWmResultDefault.
      messages.push_back(
          Win32Message{message, kbdinput.wVk, lparam, kWmResultDontCheck});
      if (redispatch_char != 0 && (kbdinput.dwFlags & KEYEVENTF_KEYUP) == 0) {
        messages.push_back(
            Win32Message{WM_CHAR, redispatch_char, lparam, kWmResultDontCheck});
      }
    }

    queue->InjectMessageList(messages.size(), messages.data());
    pending_responds_.clear();
    return num_pending_responds;
  }

  void SetKeyState(uint32_t key, bool pressed, bool toggled_on) {
    key_state_.Set(key, pressed, toggled_on);
  }

 protected:
  void RegisterKeyboardHandlers(
      BinaryMessenger* messenger,
      KeyboardKeyHandler::EventDispatcher dispatch_event,
      KeyboardKeyEmbedderHandler::GetKeyStateHandler get_key_state) override {
    FlutterWindowsView::RegisterKeyboardHandlers(
        messenger,
        [this](UINT cInputs, LPINPUT pInputs, int cbSize) -> UINT {
          return this->SendInput(cInputs, pInputs, cbSize);
        },
        key_state_.Getter());
  }

 private:
  UINT SendInput(UINT cInputs, LPINPUT pInputs, int cbSize) {
    pending_responds_.push_back({cInputs, pInputs->ki, cbSize});
    return 1;
  }

  U16StringHandler on_text_;
  std::vector<SendInputInfo> pending_responds_;
  TestKeystate key_state_;
};

typedef enum {
  kKeyCallOnKey,
  kKeyCallOnText,
} KeyCallType;

typedef struct {
  KeyCallType type;

  // Only one of the following fields should be assigned.
  FlutterKeyEvent key_event;
  std::u16string text;
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

std::unique_ptr<FlutterWindowsEngine> GetTestEngine();

class KeyboardTester {
 public:
  explicit KeyboardTester() {
    view_ = std::make_unique<TestFlutterWindowsView>(
        [](const std::u16string& text) {
          key_calls.push_back(KeyCall{
              .type = kKeyCallOnText,
              .text = text,
          });
        });
    view_->SetEngine(std::move(GetTestEngine()));
    window_ = std::make_unique<MockKeyboardManagerWin32Delegate>(view_.get());
  }

  void SetKeyState(uint32_t key, bool pressed, bool toggled_on) {
    view_->SetKeyState(key, pressed, toggled_on);
  }

  void Responding(bool response) { test_response = response; }

  void SetLayout(MapVkToCharHandler layout) { window_->SetLayout(layout); }

  void InjectMessages(int count, Win32Message message1, ...) {
    Win32Message messages[count];
    messages[0] = message1;
    va_list args;
    va_start(args, message1);
    for (int i = 1; i < count; i += 1) {
      messages[i] = va_arg(args, Win32Message);
    }
    va_end(args);
    window_->InjectMessageList(count, messages);
  }

  // Inject all events called with |SendInput| to the event queue,
  // then process the event queue.
  //
  // Returns the number of events injected.
  //
  // If |redispatch_char| is not 0, then WM_KEYDOWN events will
  // also redispatch a WM_CHAR event with that value as lparam.
  int InjectPendingEvents(uint32_t redispatch_char = 0) {
    return view_->InjectPendingEvents(window_.get(), redispatch_char);
  }

  static bool test_response;

 private:
  std::unique_ptr<TestFlutterWindowsView> view_;
  std::unique_ptr<MockKeyboardManagerWin32Delegate> window_;
};

bool KeyboardTester::test_response = false;

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

  MockEmbedderApiForKeyboard(
      modifier, [] { return KeyboardTester::test_response; },
      [](const FlutterKeyEvent* event) {
        FlutterKeyEvent clone_event = *event;
        clone_event.character = event->character == nullptr
                                    ? nullptr
                                    : clone_string(event->character);
        key_calls.push_back(KeyCall{
            .type = kKeyCallOnKey,
            .key_event = clone_event,
        });
        return KeyboardTester::test_response;
      });

  engine->RunWithEntrypoint(nullptr);
  return engine;
}

constexpr uint64_t kScanCodeKeyA = 0x1e;
constexpr uint64_t kScanCodeKeyE = 0x12;
constexpr uint64_t kScanCodeKeyQ = 0x10;
constexpr uint64_t kScanCodeKeyW = 0x11;
constexpr uint64_t kScanCodeDigit1 = 0x02;
constexpr uint64_t kScanCodeDigit6 = 0x07;
// constexpr uint64_t kScanCodeNumpad1 = 0x4f;
// constexpr uint64_t kScanCodeNumLock = 0x45;
constexpr uint64_t kScanCodeControl = 0x1d;
constexpr uint64_t kScanCodeAlt = 0x38;
constexpr uint64_t kScanCodeShiftLeft = 0x2a;
// constexpr uint64_t kScanCodeShiftRight = 0x36;
constexpr uint64_t kScanCodeBracketLeft = 0x1a;

constexpr uint64_t kVirtualDigit1 = 0x31;
constexpr uint64_t kVirtualKeyA = 0x41;
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

TEST(KeyboardTest, LowerCaseAHandled) {
  KeyboardTester tester;
  tester.Responding(true);

  // US Keyboard layout

  // Press A
  tester.InjectMessages(
      2,
      WmKeyDownInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{'a', kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyA,
                       kLogicalKeyA, "a", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents('a');
  EXPECT_EQ(key_calls.size(), 0);

  // Release A
  tester.InjectMessages(
      1, WmKeyUpInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended}.Build(
             kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyA,
                       kLogicalKeyA, "", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
}

TEST(KeyboardTest, LowerCaseAUnhandled) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout

  // Press A
  tester.InjectMessages(
      2,
      WmKeyDownInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{'a', kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyA,
                       kLogicalKeyA, "a", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents('a');
  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_TEXT(key_calls[0], u"a");
  clear_key_calls();

  // Release A
  tester.InjectMessages(
      1, WmKeyUpInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended}.Build(
             kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyA,
                       kLogicalKeyA, "", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
}

// Press Shift-A. This is special because Win32 gives 'A' as character for the
// KeyA press.
TEST(KeyboardTest, ShiftLeftKeyA) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout

  // Press ShiftLeft
  tester.SetKeyState(VK_LSHIFT, true, true);
  tester.InjectMessages(
      1,
      WmKeyDownInfo{VK_SHIFT, kScanCodeShiftLeft, kNotExtended, kWasUp}.Build(
          kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalShiftLeft, kLogicalShiftLeft, "",
                       kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();

  // Press A
  tester.InjectMessages(
      2,
      WmKeyDownInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{'A', kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyA,
                       kLogicalKeyA, "A", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents('A');
  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_TEXT(key_calls[0], u"A");
  clear_key_calls();

  // Release ShiftLeft
  tester.SetKeyState(VK_LSHIFT, false, true);
  tester.InjectMessages(
      1, WmKeyUpInfo{VK_SHIFT, kScanCodeShiftLeft, kNotExtended}.Build(
             kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalShiftLeft,
                       kLogicalShiftLeft, "", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();

  // Release A
  tester.InjectMessages(
      1, WmKeyUpInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended}.Build(
             kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyA,
                       kLogicalKeyA, "", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
}

// Press Ctrl-A. This is special because Win32 gives 0x01 as character for the
// KeyA press.
TEST(KeyboardTest, CtrlLeftKeyA) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout

  // Press ControlLeft
  tester.SetKeyState(VK_LCONTROL, true, true);
  tester.InjectMessages(
      1,
      WmKeyDownInfo{VK_CONTROL, kScanCodeControl, kNotExtended, kWasUp}.Build(
          kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalControlLeft, kLogicalControlLeft, "",
                       kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();

  // Press A
  tester.InjectMessages(
      2,
      WmKeyDownInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{0x01, kScanCodeKeyA, kNotExtended, kWasUp}.Build(
          kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyA,
                       kLogicalKeyA, "", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents(0);
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();

  // Release A
  tester.InjectMessages(
      1, WmKeyUpInfo{kVirtualKeyA, kScanCodeKeyA, kNotExtended}.Build(
             kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyA,
                       kLogicalKeyA, "", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);

  // Release ControlLeft
  tester.SetKeyState(VK_LCONTROL, false, true);
  tester.InjectMessages(
      1, WmKeyUpInfo{VK_CONTROL, kScanCodeControl, kNotExtended}.Build(
             kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp,
                       kPhysicalControlLeft, kLogicalControlLeft, "",
                       kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();
}

// Press Ctrl-1. This is special because it yields no WM_CHAR for the 1.
TEST(KeyboardTest, CtrlLeftDigit1) {
  KeyboardTester tester;
  tester.Responding(false);

  // US Keyboard layout

  // Press ControlLeft
  tester.SetKeyState(VK_LCONTROL, true, true);
  tester.InjectMessages(
      1,
      WmKeyDownInfo{VK_CONTROL, kScanCodeControl, kNotExtended, kWasUp}.Build(
          kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalControlLeft, kLogicalControlLeft, "",
                       kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();

  // Press 1
  tester.InjectMessages(
      1, WmKeyDownInfo{kVirtualDigit1, kScanCodeDigit1, kNotExtended, kWasUp}
             .Build(kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalDigit1,
                       kLogicalDigit1, "", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents(0);
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();

  // Release 1
  tester.InjectMessages(
      1, WmKeyUpInfo{kVirtualDigit1, kScanCodeDigit1, kNotExtended}.Build(
             kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalDigit1,
                       kLogicalDigit1, "", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);

  // Release ControlLeft
  tester.SetKeyState(VK_LCONTROL, false, true);
  tester.InjectMessages(
      1, WmKeyUpInfo{VK_CONTROL, kScanCodeControl, kNotExtended}.Build(
             kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp,
                       kPhysicalControlLeft, kLogicalControlLeft, "",
                       kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();
}

// Press 1 on a French keyboard. This is special because it yields WM_CHAR
// with char_code '&'.
TEST(KeyboardTest, Digit1OnFrenchLayout) {
  KeyboardTester tester;
  tester.Responding(false);

  tester.SetLayout(LayoutFrench);

  // Press 1
  tester.InjectMessages(
      2,
      WmKeyDownInfo{kVirtualDigit1, kScanCodeDigit1, kNotExtended, kWasUp}
          .Build(kWmResultZero),
      WmCharInfo{'&', kScanCodeDigit1, kNotExtended, kWasUp}.Build(
          kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalDigit1,
                       kLogicalDigit1, "&", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents('&');
  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_TEXT(key_calls[0], u"&");
  clear_key_calls();

  // Release 1
  tester.InjectMessages(
      1, WmKeyUpInfo{kVirtualDigit1, kScanCodeDigit1, kNotExtended}.Build(
             kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalDigit1,
                       kLogicalDigit1, "", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
}

// This tests AltGr-Q on a German keyboard, which should print '@'.
TEST(KeyboardTest, AltGrModifiedKey) {
  KeyboardTester tester;
  tester.Responding(false);

  // German Keyboard layout

  // Press AltGr, which Win32 precedes with a ContrlLeft down.
  tester.SetKeyState(VK_LCONTROL, true, true);
  tester.InjectMessages(
      2,
      WmKeyDownInfo{VK_LCONTROL, kScanCodeControl, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmKeyDownInfo{VK_MENU, kScanCodeAlt, kExtended, kWasUp}.Build(
          kWmResultZero));

  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalControlLeft, kLogicalControlLeft, "",
                       kNotSynthesized);
  EXPECT_CALL_IS_EVENT(key_calls[1], kFlutterKeyEventTypeDown,
                       kPhysicalAltRight, kLogicalAltRight, "",
                       kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();

  // Press Q
  tester.InjectMessages(
      2,
      WmKeyDownInfo{kVirtualKeyQ, kScanCodeKeyQ, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{'@', kScanCodeKeyQ, kNotExtended, kWasUp}.Build(
          kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyQ,
                       kLogicalKeyQ, "@", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents('@');
  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_TEXT(key_calls[0], u"@");
  clear_key_calls();

  // Release Q
  tester.InjectMessages(
      1, WmKeyUpInfo{kVirtualKeyQ, kScanCodeKeyQ, kNotExtended}.Build(
             kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyQ,
                       kLogicalKeyQ, "", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);

  // Release AltGr. Win32 doesn't dispatch ControlLeft up. Instead Flutter will
  // dispatch one. The AltGr is a system key, so will be handled by Win32's
  // default WndProc.
  tester.InjectMessages(
      1,
      WmSysKeyUpInfo{VK_MENU, kScanCodeAlt, kExtended}.Build(kWmResultDefault));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalAltRight,
                       kLogicalAltRight, "", kNotSynthesized);
  clear_key_calls();

  tester.SetKeyState(VK_LCONTROL, false, false);
  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp,
                       kPhysicalControlLeft, kLogicalControlLeft, "",
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
  tester.InjectMessages(
      2,
      WmKeyDownInfo{0xDD, kScanCodeBracketLeft, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmDeadCharInfo{'^', kScanCodeBracketLeft, kNotExtended, kWasUp}.Build(
          kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalBracketLeft, kLogicalBracketRight, "^",
                       kNotSynthesized);
  clear_key_calls();

  EXPECT_EQ(tester.InjectPendingEvents(), 0);
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();

  // Release ^¨
  tester.InjectMessages(
      1, WmKeyUpInfo{0xDD, kScanCodeBracketLeft, kNotExtended}.Build(
             kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp,
                       kPhysicalBracketLeft, kLogicalBracketRight, "",
                       kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();

  // Press E
  tester.InjectMessages(
      2,
      WmKeyDownInfo{kVirtualKeyE, kScanCodeKeyE, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{0xEA, kScanCodeKeyE, kNotExtended, kWasUp}.Build(
          kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyE,
                       kLogicalKeyE, "ê", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents(
      0xEA);  // The redispatched event uses unmodified 'e'
  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_TEXT(key_calls[0], u"ê");
  clear_key_calls();

  // Release E
  tester.InjectMessages(
      1, WmKeyUpInfo{kVirtualKeyE, kScanCodeKeyE, kNotExtended}.Build(
             kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyE,
                       kLogicalKeyE, "", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
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
  tester.SetKeyState(VK_LSHIFT, true, true);
  tester.InjectMessages(
      1,
      WmKeyDownInfo{VK_SHIFT, kScanCodeShiftLeft, kNotExtended, kWasUp}.Build(
          kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalShiftLeft, kLogicalShiftLeft, "",
                       kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();

  // Press 6^
  tester.InjectMessages(
      2,
      WmKeyDownInfo{'6', kScanCodeDigit6, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmDeadCharInfo{'^', kScanCodeDigit6, kNotExtended, kWasUp}.Build(
          kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalDigit6,
                       kLogicalDigit6, "6", kNotSynthesized);
  clear_key_calls();

  EXPECT_EQ(tester.InjectPendingEvents(), 0);
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();

  // Release 6^
  tester.InjectMessages(
      1, WmKeyUpInfo{'6', kScanCodeDigit6, kNotExtended}.Build(kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalDigit6,
                       kLogicalDigit6, "", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();

  // Release ShiftLeft
  tester.SetKeyState(VK_LSHIFT, false, true);
  tester.InjectMessages(
      1, WmKeyUpInfo{VK_SHIFT, kScanCodeShiftLeft, kNotExtended}.Build(
             kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalShiftLeft,
                       kLogicalShiftLeft, "", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();

  // Press E
  tester.InjectMessages(
      2,
      WmKeyDownInfo{kVirtualKeyE, kScanCodeKeyE, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{0xEA, kScanCodeKeyE, kNotExtended, kWasUp}.Build(
          kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyE,
                       kLogicalKeyE, "ê", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents(
      0xEA);  // The redispatched event uses unmodified 'e'
  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_TEXT(key_calls[0], u"ê");
  clear_key_calls();

  // Release E
  tester.InjectMessages(
      1, WmKeyUpInfo{kVirtualKeyE, kScanCodeKeyE, kNotExtended}.Build(
             kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyE,
                       kLogicalKeyE, "", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
}

// This tests dead key ^ then & (US: 1) on a French keyboard, which do not
// combine and should output "^&".
TEST(KeyboardTest, DeadKeyThatDoesNotCombine) {
  KeyboardTester tester;
  tester.Responding(false);

  tester.SetLayout(LayoutFrench);

  // Press ^¨ (US: Left bracket)
  tester.InjectMessages(
      2,
      WmKeyDownInfo{0xDD, kScanCodeBracketLeft, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmDeadCharInfo{'^', kScanCodeBracketLeft, kNotExtended, kWasUp}.Build(
          kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown,
                       kPhysicalBracketLeft, kLogicalBracketRight, "^",
                       kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents(0);  // No WM_DEADCHAR messages sent here.
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();

  // Release ^¨
  tester.InjectMessages(
      1, WmKeyUpInfo{0xDD, kScanCodeBracketLeft, kNotExtended}.Build(
             kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp,
                       kPhysicalBracketLeft, kLogicalBracketRight, "",
                       kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();

  // Press 1
  tester.InjectMessages(
      3,
      WmKeyDownInfo{kVirtualDigit1, kScanCodeDigit1, kNotExtended, kWasUp}
          .Build(kWmResultZero),
      WmCharInfo{'^', kScanCodeDigit1, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{'&', kScanCodeDigit1, kNotExtended, kWasUp}.Build(
          kWmResultZero));

  EXPECT_EQ(key_calls.size(), 2);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalDigit1,
                       kLogicalDigit1, "^", kNotSynthesized);
  EXPECT_CALL_IS_TEXT(key_calls[1], u"^");
  clear_key_calls();

  tester.InjectPendingEvents('&');
  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_TEXT(key_calls[0], u"&");
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();

  // Release 1
  tester.InjectMessages(
      1, WmKeyUpInfo{kVirtualDigit1, kScanCodeDigit1, kNotExtended}.Build(
             kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalDigit1,
                       kLogicalDigit1, "", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
}

// This tests when the resulting character needs to be combined with surrogates.
TEST(KeyboardTest, MultibyteCharacter) {
  KeyboardTester tester;
  tester.Responding(false);

  // Gothic Keyboard layout. (We need a layout that yields non-BMP characters
  // without IME, which that is actually very rare.)

  // Press key W of a US keyboard, which should yield character '𐍅'.
  tester.InjectMessages(
      3,
      WmKeyDownInfo{kVirtualKeyW, kScanCodeKeyW, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{0xd800, kScanCodeKeyW, kNotExtended, kWasUp}.Build(
          kWmResultZero),
      WmCharInfo{0xdf45, kScanCodeKeyW, kNotExtended, kWasUp}.Build(
          kWmResultZero));

  const char* st = key_calls[0].key_event.character;

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeDown, kPhysicalKeyW,
                       kLogicalKeyW, "𐍅", kNotSynthesized);
  clear_key_calls();

  // Inject the redispatched high surrogate.
  tester.InjectPendingEvents(0xd800);
  // Manually inject the redispatched low surrogate.
  tester.InjectMessages(
      1, WmCharInfo{0xdf45, kScanCodeKeyW, kNotExtended, kWasUp}.Build(
             kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_TEXT(key_calls[0], u"𐍅");
  clear_key_calls();

  // Release W
  tester.InjectMessages(
      1, WmKeyUpInfo{kVirtualKeyW, kScanCodeKeyW, kNotExtended}.Build(
             kWmResultZero));

  EXPECT_EQ(key_calls.size(), 1);
  EXPECT_CALL_IS_EVENT(key_calls[0], kFlutterKeyEventTypeUp, kPhysicalKeyW,
                       kLogicalKeyW, "", kNotSynthesized);
  clear_key_calls();

  tester.InjectPendingEvents();
  EXPECT_EQ(key_calls.size(), 0);
  clear_key_calls();
}

}  // namespace testing
}  // namespace flutter
