// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/keyboard_key_embedder_handler.h"

#include <string>
#include <vector>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/windows/testing/engine_modifier.h"
#include "gtest/gtest.h"

namespace flutter {

namespace {

constexpr SHORT kStateMaskToggled = 0x01;
constexpr SHORT kStateMaskPressed = 0x80;

class TestFlutterKeyEvent : public FlutterKeyEvent {
 public:
  TestFlutterKeyEvent(const FlutterKeyEvent& src,
                      FlutterKeyEventCallback callback,
                      void* user_data)
      : character_str(src.character), callback(callback), user_data(user_data) {
    struct_size = src.struct_size;
    timestamp = src.timestamp;
    type = src.type;
    physical = src.physical;
    logical = src.logical;
    character = character_str.c_str();
    synthesized = src.synthesized;
  }

  TestFlutterKeyEvent(TestFlutterKeyEvent&& source)
      : FlutterKeyEvent(source),
        callback(std::move(source.callback)),
        user_data(source.user_data) {
    character = character_str.c_str();
  }

  FlutterKeyEventCallback callback;
  void* user_data;

 private:
  const std::string character_str;
};

class TestKeystate {
 public:
  void Set(int virtual_key, bool pressed, bool toggled_on = false) {
    state_[virtual_key] = (pressed ? kStateMaskPressed : 0) |
                          (toggled_on ? kStateMaskToggled : 0);
  }

  SHORT Get(int virtual_key) { return state_[virtual_key]; }

  KeyboardKeyEmbedderHandler::GetKeyStateHandler Getter() {
    return [this](int virtual_key) { return Get(virtual_key); };
  }

 private:
  std::map<int, SHORT> state_;
};

}  // namespace

namespace testing {

namespace {
constexpr uint64_t kScanCodeKeyA = 0x1e;
constexpr uint64_t kScanCodeNumpad1 = 0x4f;
constexpr uint64_t kScanCodeNumLock = 0x45;
constexpr uint64_t kScanCodeControl = 0x1d;
constexpr uint64_t kScanCodeShiftLeft = 0x2a;
constexpr uint64_t kScanCodeShiftRight = 0x36;

constexpr uint64_t kVirtualKeyA = 0x41;

constexpr uint64_t kPhysicalKeyA = 0x00070004;
constexpr uint64_t kPhysicalControlLeft = 0x000700e0;
constexpr uint64_t kPhysicalControlRight = 0x000700e4;
constexpr uint64_t kPhysicalShiftLeft = 0x000700e1;
constexpr uint64_t kPhysicalShiftRight = 0x000700e5;
constexpr uint64_t kPhysicalKeyNumLock = 0x00070053;

constexpr uint64_t kLogicalKeyA = 0x00000061;
constexpr uint64_t kLogicalControlLeft = 0x00300000105;
constexpr uint64_t kLogicalControlRight = 0x00400000105;
constexpr uint64_t kLogicalShiftLeft = 0x0030000010d;
constexpr uint64_t kLogicalShiftRight = 0x0040000010d;
constexpr uint64_t kLogicalKeyNumLock = 0x0000000010a;
}  // namespace

// Test the most basic key events.
//
// Press, hold, and release key A on an US keyboard.
TEST(KeyboardKeyEmbedderHandlerTest, BasicKeyPressingAndHolding) {
  TestKeystate key_state;
  std::vector<TestFlutterKeyEvent> results;
  TestFlutterKeyEvent* event;
  bool last_handled = false;

  std::unique_ptr<KeyboardKeyEmbedderHandler> handler =
      std::make_unique<KeyboardKeyEmbedderHandler>(
          [&results](const FlutterKeyEvent& event,
                     FlutterKeyEventCallback callback, void* user_data) {
            results.emplace_back(event, callback, user_data);
          },
          key_state.Getter());

  // Press KeyA.
  handler->KeyboardHook(
      kVirtualKeyA, kScanCodeKeyA, WM_KEYDOWN, 'a', false, false,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(event->physical, kPhysicalKeyA);
  EXPECT_EQ(event->logical, kLogicalKeyA);
  EXPECT_STREQ(event->character, "a");
  EXPECT_EQ(event->synthesized, false);

  event->callback(true, event->user_data);
  EXPECT_EQ(last_handled, true);
  results.clear();
  key_state.Set(kVirtualKeyA, true);

  // Hold KeyA.
  handler->KeyboardHook(
      kVirtualKeyA, kScanCodeKeyA, WM_KEYDOWN, 'a', false, true,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, true);
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeRepeat);
  EXPECT_EQ(event->physical, kPhysicalKeyA);
  EXPECT_EQ(event->logical, kLogicalKeyA);
  EXPECT_STREQ(event->character, "a");
  EXPECT_EQ(event->synthesized, false);

  event->callback(false, event->user_data);
  EXPECT_EQ(last_handled, false);
  results.clear();

  // Release KeyA.
  handler->KeyboardHook(
      kVirtualKeyA, kScanCodeKeyA, WM_KEYUP, 0, false, true,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(event->physical, kPhysicalKeyA);
  EXPECT_EQ(event->logical, kLogicalKeyA);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, false);
  event->callback(false, event->user_data);
}

// Press numpad 1, toggle NumLock, and release numpad 1 on an US
// keyboard.
//
// This is special because the virtual key for numpad 1 will
// change in this process.
TEST(KeyboardKeyEmbedderHandlerTest, ToggleNumLockDuringNumpadPress) {
  TestKeystate key_state;
  std::vector<TestFlutterKeyEvent> results;
  TestFlutterKeyEvent* event;
  bool last_handled = false;

  std::unique_ptr<KeyboardKeyEmbedderHandler> handler =
      std::make_unique<KeyboardKeyEmbedderHandler>(
          [&results](const FlutterKeyEvent& event,
                     FlutterKeyEventCallback callback, void* user_data) {
            results.emplace_back(event, callback, user_data);
          },
          key_state.Getter());

  // Press NumPad1.
  key_state.Set(VK_NUMPAD1, true);
  handler->KeyboardHook(
      VK_NUMPAD1, kScanCodeNumpad1, WM_KEYDOWN, 0, false, false,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(event->physical, 0x00070059);
  EXPECT_EQ(event->logical, 0x00200000031);
  // EXPECT_STREQ(event->character, "1"); // TODO
  EXPECT_EQ(event->synthesized, false);
  results.clear();

  // Press NumLock.
  key_state.Set(VK_NUMLOCK, true, true);
  handler->KeyboardHook(
      VK_NUMLOCK, kScanCodeNumLock, WM_KEYDOWN, 0, true, false,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(event->physical, 0x00070053);
  EXPECT_EQ(event->logical, 0x0000010a);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, false);
  results.clear();

  // Release NumLock.
  key_state.Set(VK_NUMLOCK, false, true);
  handler->KeyboardHook(
      VK_NUMLOCK, kScanCodeNumLock, WM_KEYUP, 0, true, true,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(event->physical, 0x00070053);
  EXPECT_EQ(event->logical, 0x0000010a);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, false);
  results.clear();

  // Release NumPad1. (The logical key is now NumpadEnd)
  handler->KeyboardHook(
      VK_END, kScanCodeNumpad1, WM_KEYUP, 0, false, true,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(event->physical, 0x00070059);
  EXPECT_EQ(event->logical, 0x00200000031);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, false);
  results.clear();
}

// Key presses that trigger IME should be ignored by this API (and handled by
// compose API).
TEST(KeyboardKeyEmbedderHandlerTest, ImeEventsAreIgnored) {
  TestKeystate key_state;
  std::vector<TestFlutterKeyEvent> results;
  TestFlutterKeyEvent* event;
  bool last_handled = false;

  std::unique_ptr<KeyboardKeyEmbedderHandler> handler =
      std::make_unique<KeyboardKeyEmbedderHandler>(
          [&results](const FlutterKeyEvent& event,
                     FlutterKeyEventCallback callback, void* user_data) {
            results.emplace_back(event, callback, user_data);
          },
          key_state.Getter());

  // Press A in an IME
  last_handled = false;
  handler->KeyboardHook(
      VK_PROCESSKEY, kScanCodeKeyA, WM_KEYDOWN, 0, true, false,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, true);

  last_handled = false;
  handler->KeyboardHook(
      // The up event for an IME press has a normal virtual key.
      kVirtualKeyA, kScanCodeKeyA, WM_KEYUP, 0, true, true,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, true);

  // The entire A press does not yield events.
  EXPECT_EQ(results.size(), 0);

  // Press A out of an IME
  key_state.Set(kVirtualKeyA, true);
  last_handled = false;
  handler->KeyboardHook(
      kVirtualKeyA, kScanCodeKeyA, WM_KEYDOWN, 0, true, false,
      [&last_handled](bool handled) { last_handled = handled; });
  // Not decided yet
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  event->callback(true, event->user_data);
  EXPECT_EQ(last_handled, true);
  results.clear();

  last_handled = false;
  key_state.Set(kVirtualKeyA, false);
  handler->KeyboardHook(
      kVirtualKeyA, kScanCodeKeyA, WM_KEYUP, 0, true, false,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  event->callback(true, event->user_data);
  EXPECT_EQ(last_handled, true);
}

// Test if modifier keys that are told apart by the extended bit
// can be identified.
TEST(KeyboardKeyEmbedderHandlerTest, ModifierKeysByExtendedBit) {
  TestKeystate key_state;
  std::vector<TestFlutterKeyEvent> results;
  TestFlutterKeyEvent* event;
  bool last_handled = false;

  std::unique_ptr<KeyboardKeyEmbedderHandler> handler =
      std::make_unique<KeyboardKeyEmbedderHandler>(
          [&results](const FlutterKeyEvent& event,
                     FlutterKeyEventCallback callback, void* user_data) {
            results.emplace_back(event, callback, user_data);
          },
          key_state.Getter());

  // Press Ctrl left.
  last_handled = false;
  key_state.Set(VK_LCONTROL, true);
  handler->KeyboardHook(
      VK_CONTROL, kScanCodeControl, WM_KEYDOWN, 0, false, false,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(event->physical, kPhysicalControlLeft);
  EXPECT_EQ(event->logical, kLogicalControlLeft);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, false);

  event->callback(true, event->user_data);
  EXPECT_EQ(last_handled, true);
  results.clear();

  // Press Ctrl right.
  last_handled = false;
  key_state.Set(VK_RCONTROL, true);
  handler->KeyboardHook(
      VK_CONTROL, kScanCodeControl, WM_KEYDOWN, 0, true, true,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(event->physical, kPhysicalControlRight);
  EXPECT_EQ(event->logical, kLogicalControlRight);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, false);

  event->callback(true, event->user_data);
  EXPECT_EQ(last_handled, true);
  results.clear();

  // Release Ctrl left.
  last_handled = false;
  key_state.Set(VK_LCONTROL, false);
  handler->KeyboardHook(
      VK_CONTROL, kScanCodeControl, WM_KEYUP, 0, false, true,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(event->physical, kPhysicalControlLeft);
  EXPECT_EQ(event->logical, kLogicalControlLeft);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, false);

  event->callback(true, event->user_data);
  EXPECT_EQ(last_handled, true);
  results.clear();

  // Release Ctrl right.
  last_handled = false;
  key_state.Set(VK_RCONTROL, false);
  handler->KeyboardHook(
      VK_CONTROL, kScanCodeControl, WM_KEYUP, 0, true, true,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(event->physical, kPhysicalControlRight);
  EXPECT_EQ(event->logical, kLogicalControlRight);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, false);

  event->callback(true, event->user_data);
  EXPECT_EQ(last_handled, true);
  results.clear();
}

// Test if modifier keys that are told apart by the virtual key
// can be identified.
TEST(KeyboardKeyEmbedderHandlerTest, ModifierKeysByVirtualKey) {
  TestKeystate key_state;
  std::vector<TestFlutterKeyEvent> results;
  TestFlutterKeyEvent* event;
  bool last_handled = false;

  std::unique_ptr<KeyboardKeyEmbedderHandler> handler =
      std::make_unique<KeyboardKeyEmbedderHandler>(
          [&results](const FlutterKeyEvent& event,
                     FlutterKeyEventCallback callback, void* user_data) {
            results.emplace_back(event, callback, user_data);
          },
          key_state.Getter());

  // Press Shift left.
  last_handled = false;
  key_state.Set(VK_LSHIFT, true);
  handler->KeyboardHook(
      VK_LSHIFT, kScanCodeShiftLeft, WM_KEYDOWN, 0, false, false,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(event->physical, kPhysicalShiftLeft);
  EXPECT_EQ(event->logical, kLogicalShiftLeft);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, false);

  event->callback(true, event->user_data);
  EXPECT_EQ(last_handled, true);
  results.clear();

  // Press Shift right.
  last_handled = false;
  key_state.Set(VK_RSHIFT, true);
  handler->KeyboardHook(
      VK_RSHIFT, kScanCodeShiftRight, WM_KEYDOWN, 0, false, false,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(event->physical, kPhysicalShiftRight);
  EXPECT_EQ(event->logical, kLogicalShiftRight);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, false);

  event->callback(true, event->user_data);
  EXPECT_EQ(last_handled, true);
  results.clear();

  // Release Shift left.
  last_handled = false;
  key_state.Set(VK_LSHIFT, false);
  handler->KeyboardHook(
      VK_LSHIFT, kScanCodeShiftLeft, WM_KEYUP, 0, false, true,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(event->physical, kPhysicalShiftLeft);
  EXPECT_EQ(event->logical, kLogicalShiftLeft);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, false);

  event->callback(true, event->user_data);
  EXPECT_EQ(last_handled, true);
  results.clear();

  // Release Shift right.
  last_handled = false;
  key_state.Set(VK_RSHIFT, false);
  handler->KeyboardHook(
      VK_RSHIFT, kScanCodeShiftRight, WM_KEYUP, 0, false, true,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(event->physical, kPhysicalShiftRight);
  EXPECT_EQ(event->logical, kLogicalShiftRight);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, false);

  event->callback(true, event->user_data);
  EXPECT_EQ(last_handled, true);
  results.clear();
}

TEST(KeyboardKeyEmbedderHandlerTest, AbruptRepeatIsConvertedToDown) {
  TestKeystate key_state;
  std::vector<TestFlutterKeyEvent> results;
  TestFlutterKeyEvent* event;
  bool last_handled = false;

  std::unique_ptr<KeyboardKeyEmbedderHandler> handler =
      std::make_unique<KeyboardKeyEmbedderHandler>(
          [&results](const FlutterKeyEvent& event,
                     FlutterKeyEventCallback callback, void* user_data) {
            results.emplace_back(event, callback, user_data);
          },
          key_state.Getter());
  last_handled = false;

  key_state.Set(kVirtualKeyA, true);

  // Press A (with was_down true)
  handler->KeyboardHook(
      kVirtualKeyA, kScanCodeKeyA, WM_KEYDOWN, 'a', false, true,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(event->physical, kPhysicalKeyA);
  EXPECT_EQ(event->logical, kLogicalKeyA);
  EXPECT_STREQ(event->character, "a");
  EXPECT_EQ(event->synthesized, false);

  event->callback(true, event->user_data);
  EXPECT_EQ(last_handled, true);
  results.clear();

  // Release A
  last_handled = false;
  key_state.Set(kVirtualKeyA, false);
  handler->KeyboardHook(
      kVirtualKeyA, kScanCodeKeyA, WM_KEYUP, 'a', false, true,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(event->physical, kPhysicalKeyA);
  EXPECT_EQ(event->logical, kLogicalKeyA);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, false);

  event->callback(true, event->user_data);
  EXPECT_EQ(last_handled, true);
  results.clear();
}

TEST(KeyboardKeyEmbedderHandlerTest, SynthesizeForDesyncPressingState) {
  TestKeystate key_state;
  std::vector<TestFlutterKeyEvent> results;
  TestFlutterKeyEvent* event;
  bool last_handled = false;

  std::unique_ptr<KeyboardKeyEmbedderHandler> handler =
      std::make_unique<KeyboardKeyEmbedderHandler>(
          [&results](const FlutterKeyEvent& event,
                     FlutterKeyEventCallback callback, void* user_data) {
            results.emplace_back(event, callback, user_data);
          },
          key_state.Getter());

  // A key down of control left is missed.
  key_state.Set(VK_LCONTROL, true);

  // Send a normal event
  key_state.Set(kVirtualKeyA, true);
  handler->KeyboardHook(
      kVirtualKeyA, kScanCodeKeyA, WM_KEYDOWN, 'a', false, false,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 2);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(event->physical, kPhysicalControlLeft);
  EXPECT_EQ(event->logical, kLogicalControlLeft);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, true);
  EXPECT_EQ(event->callback, nullptr);

  event = &results[1];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(event->physical, kPhysicalKeyA);
  EXPECT_EQ(event->logical, kLogicalKeyA);
  EXPECT_STREQ(event->character, "a");
  EXPECT_EQ(event->synthesized, false);

  last_handled = true;
  event->callback(false, event->user_data);
  EXPECT_EQ(last_handled, false);
  results.clear();

  // A key down of control right is missed.
  key_state.Set(VK_LCONTROL, false);

  // Hold KeyA.
  handler->KeyboardHook(
      kVirtualKeyA, kScanCodeKeyA, WM_KEYDOWN, 'a', false, true,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 2);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(event->physical, kPhysicalControlLeft);
  EXPECT_EQ(event->logical, kLogicalControlLeft);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, true);
  EXPECT_EQ(event->callback, nullptr);

  event = &results[1];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeRepeat);
  EXPECT_EQ(event->physical, kPhysicalKeyA);
  EXPECT_EQ(event->logical, kLogicalKeyA);
  EXPECT_STREQ(event->character, "a");
  EXPECT_EQ(event->synthesized, false);

  last_handled = true;
  event->callback(false, event->user_data);
  EXPECT_EQ(last_handled, false);
  results.clear();

  // Release KeyA.
  key_state.Set(kVirtualKeyA, false);
  handler->KeyboardHook(
      kVirtualKeyA, kScanCodeKeyA, WM_KEYUP, 0, false, true,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(event->physical, kPhysicalKeyA);
  EXPECT_EQ(event->logical, kLogicalKeyA);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, false);
  event->callback(false, event->user_data);
}

TEST(KeyboardKeyEmbedderHandlerTest, SynthesizeForDesyncToggledState) {
  TestKeystate key_state;
  std::vector<TestFlutterKeyEvent> results;
  TestFlutterKeyEvent* event;
  bool last_handled = false;

  std::unique_ptr<KeyboardKeyEmbedderHandler> handler =
      std::make_unique<KeyboardKeyEmbedderHandler>(
          [&results](const FlutterKeyEvent& event,
                     FlutterKeyEventCallback callback, void* user_data) {
            results.emplace_back(event, callback, user_data);
          },
          key_state.Getter());

  // The NumLock is desynchronized by toggled on
  key_state.Set(VK_NUMLOCK, false, true);

  // Send a normal event
  key_state.Set(kVirtualKeyA, true);
  handler->KeyboardHook(
      kVirtualKeyA, kScanCodeKeyA, WM_KEYDOWN, 'a', false, false,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 3);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(event->physical, kPhysicalKeyNumLock);
  EXPECT_EQ(event->logical, kLogicalKeyNumLock);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, true);

  event = &results[1];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(event->physical, kPhysicalKeyNumLock);
  EXPECT_EQ(event->logical, kLogicalKeyNumLock);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, true);

  event = &results[2];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(event->physical, kPhysicalKeyA);
  EXPECT_EQ(event->logical, kLogicalKeyA);
  EXPECT_STREQ(event->character, "a");
  EXPECT_EQ(event->synthesized, false);

  event->callback(true, event->user_data);
  EXPECT_EQ(last_handled, true);
  results.clear();

  // Test if the NumLock is mis-toggled while it should also be pressed
  key_state.Set(VK_NUMLOCK, true, true);

  // Send a normal event
  handler->KeyboardHook(
      kVirtualKeyA, kScanCodeKeyA, WM_KEYDOWN, 'a', false, true,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, true);
  EXPECT_EQ(results.size(), 2);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(event->physical, kPhysicalKeyNumLock);
  EXPECT_EQ(event->logical, kLogicalKeyNumLock);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, true);

  event = &results[1];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeRepeat);
  EXPECT_EQ(event->physical, kPhysicalKeyA);
  EXPECT_EQ(event->logical, kLogicalKeyA);
  EXPECT_STREQ(event->character, "a");
  EXPECT_EQ(event->synthesized, false);

  event->callback(false, event->user_data);
  EXPECT_EQ(last_handled, false);
  results.clear();

  // Numlock is pressed at this moment.

  // Test if the NumLock is mis-toggled while it should also be released
  key_state.Set(VK_NUMLOCK, false, false);

  // Send a normal event
  key_state.Set(kVirtualKeyA, false);
  handler->KeyboardHook(
      kVirtualKeyA, kScanCodeKeyA, WM_KEYUP, 0, false, true,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(results.size(), 4);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(event->physical, kPhysicalKeyNumLock);
  EXPECT_EQ(event->logical, kLogicalKeyNumLock);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, true);
  EXPECT_EQ(event->callback, nullptr);

  event = &results[1];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(event->physical, kPhysicalKeyNumLock);
  EXPECT_EQ(event->logical, kLogicalKeyNumLock);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, true);
  EXPECT_EQ(event->callback, nullptr);

  event = &results[2];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(event->physical, kPhysicalKeyNumLock);
  EXPECT_EQ(event->logical, kLogicalKeyNumLock);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, true);
  EXPECT_EQ(event->callback, nullptr);

  event = &results[3];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(event->physical, kPhysicalKeyA);
  EXPECT_EQ(event->logical, kLogicalKeyA);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, false);
  event->callback(false, event->user_data);
}

TEST(KeyboardKeyEmbedderHandlerTest, SynthesizeForDesyncToggledStateByItself) {
  TestKeystate key_state;
  std::vector<TestFlutterKeyEvent> results;
  TestFlutterKeyEvent* event;
  bool last_handled = false;

  std::unique_ptr<KeyboardKeyEmbedderHandler> handler =
      std::make_unique<KeyboardKeyEmbedderHandler>(
          [&results](const FlutterKeyEvent& event,
                     FlutterKeyEventCallback callback, void* user_data) {
            results.emplace_back(event, callback, user_data);
          },
          key_state.Getter());

  // When NumLock is down
  key_state.Set(VK_NUMLOCK, true, true);
  handler->KeyboardHook(
      VK_NUMLOCK, kScanCodeNumLock, WM_KEYDOWN, 0, true, false,
      [&last_handled](bool handled) { last_handled = handled; });
  event = &results.back();
  event->callback(false, event->user_data);
  results.clear();

  // Numlock is desynchronized by being off and released
  key_state.Set(VK_NUMLOCK, false, false);
  // Send a NumLock key up
  handler->KeyboardHook(
      VK_NUMLOCK, kScanCodeNumLock, WM_KEYUP, 0, true, true,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 3);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(event->physical, kPhysicalKeyNumLock);
  EXPECT_EQ(event->logical, kLogicalKeyNumLock);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, true);
  EXPECT_EQ(event->callback, nullptr);

  event = &results[1];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(event->physical, kPhysicalKeyNumLock);
  EXPECT_EQ(event->logical, kLogicalKeyNumLock);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, true);
  EXPECT_EQ(event->callback, nullptr);

  event = &results[2];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(event->physical, kPhysicalKeyNumLock);
  EXPECT_EQ(event->logical, kLogicalKeyNumLock);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, false);

  last_handled = false;
  event->callback(true, event->user_data);
  EXPECT_EQ(last_handled, true);
}

TEST(KeyboardKeyEmbedderHandlerTest, SynthesizeWithInitialTogglingState) {
  TestKeystate key_state;
  std::vector<TestFlutterKeyEvent> results;
  TestFlutterKeyEvent* event;
  bool last_handled = false;

  // The app starts with NumLock toggled on
  key_state.Set(VK_NUMLOCK, false, true);

  std::unique_ptr<KeyboardKeyEmbedderHandler> handler =
      std::make_unique<KeyboardKeyEmbedderHandler>(
          [&results](const FlutterKeyEvent& event,
                     FlutterKeyEventCallback callback, void* user_data) {
            results.emplace_back(event, callback, user_data);
          },
          key_state.Getter());

  // NumLock key down
  key_state.Set(VK_NUMLOCK, true, false);
  handler->KeyboardHook(
      VK_NUMLOCK, kScanCodeNumLock, WM_KEYDOWN, 0, true, false,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 1);
  event = &results[0];
  EXPECT_EQ(event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(event->physical, kPhysicalKeyNumLock);
  EXPECT_EQ(event->logical, kLogicalKeyNumLock);
  EXPECT_STREQ(event->character, "");
  EXPECT_EQ(event->synthesized, false);

  event->callback(true, event->user_data);
  EXPECT_EQ(last_handled, true);
  results.clear();
}

// A key down event for shift right must not be redispatched even if
// the framework returns unhandled.
//
// The reason for this test is documented in |IsEventThatMustNotRedispatch|.
TEST(KeyboardKeyEmbedderHandlerTest, NeverRedispatchShiftRightKeyDown) {
  TestKeystate key_state;
  std::vector<TestFlutterKeyEvent> results;
  TestFlutterKeyEvent* event;
  bool last_handled = false;

  std::unique_ptr<KeyboardKeyEmbedderHandler> handler =
      std::make_unique<KeyboardKeyEmbedderHandler>(
          [&results](const FlutterKeyEvent& event,
                     FlutterKeyEventCallback callback, void* user_data) {
            results.emplace_back(event, callback, user_data);
          },
          key_state.Getter());

  // Press ShiftRight.
  key_state.Set(VK_RSHIFT, true);
  handler->KeyboardHook(
      VK_RSHIFT, kScanCodeShiftRight, WM_KEYDOWN, 0, false, false,
      [&last_handled](bool handled) { last_handled = handled; });
  EXPECT_EQ(last_handled, false);
  EXPECT_EQ(results.size(), 1);

  // Framework does not handle it
  event = &results[0];
  event->callback(false, event->user_data);
  // Still responds with handling the event
  EXPECT_EQ(last_handled, true);
  results.clear();
}

}  // namespace testing
}  // namespace flutter
