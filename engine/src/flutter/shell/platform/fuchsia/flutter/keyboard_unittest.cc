// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Testing the stateful Fuchsia Input3 keyboard interactions.  This test case
// is not intended to be exhaustive: it is intended to capture the tests that
// demonstrate how we think Input3 interaction should work, and possibly
// regression tests if we catch some behavior that needs to be guarded long
// term.  Pragmatically, this should be enough to ensure no specific bug
// happens twice.

#include "flutter/shell/platform/fuchsia/flutter/keyboard.h"

#include <fuchsia/input/cpp/fidl.h>
#include <fuchsia/ui/input/cpp/fidl.h>
#include <fuchsia/ui/input3/cpp/fidl.h>

#include <gtest/gtest.h>
#include <zircon/time.h>
#include <vector>

namespace flutter_runner {
namespace {

using fuchsia::input::Key;
using fuchsia::ui::input::kModifierCapsLock;
using fuchsia::ui::input::kModifierLeftAlt;
using fuchsia::ui::input::kModifierLeftControl;
using fuchsia::ui::input::kModifierLeftShift;
using fuchsia::ui::input::kModifierNone;
using fuchsia::ui::input::kModifierRightAlt;
using fuchsia::ui::input::kModifierRightControl;
using fuchsia::ui::input::kModifierRightShift;
using fuchsia::ui::input3::KeyEvent;
using fuchsia::ui::input3::KeyEventType;

class KeyboardTest : public testing::Test {
 protected:
  static void SetUpTestCase() { testing::Test::SetUpTestCase(); }

  // Creates a new key event for testing.
  KeyEvent NewKeyEvent(KeyEventType event_type, Key key) {
    KeyEvent event;
    // Assume events are delivered with correct timing.
    event.set_timestamp(++timestamp_);
    event.set_type(event_type);
    event.set_key(key);
    return event;
  }

  // Makes the keyboard consume all the provided `events`.  The end state of
  // the keyboard is as if all of the specified events happened between the
  // start state of the keyboard and its end state.
  void ConsumeEvents(Keyboard* keyboard, const std::vector<KeyEvent>& events) {
    for (const auto& event : events) {
      KeyEvent e;
      event.Clone(&e);
      keyboard->ConsumeEvent(std::move(e));
    }
  }

  // Converts a pressed key to usage value.
  uint32_t ToUsage(Key key) { return static_cast<uint64_t>(key) & 0xFFFF; }

 private:
  zx_time_t timestamp_ = 0;
};

// This test checks that if a caps lock has been pressed when we didn't have
// focus, the effect of caps lock remains.  Only this first test case is
// commented to explain how the test case works.
TEST_F(KeyboardTest, CapsLockSync) {
  // Place the key events since the beginning of time into `keys`.
  std::vector<KeyEvent> keys;
  keys.emplace_back(NewKeyEvent(KeyEventType::SYNC, Key::CAPS_LOCK));

  // Replay them on the keyboard.
  Keyboard keyboard;
  ConsumeEvents(&keyboard, keys);

  // Verify the state of the keyboard's public API:
  // - check that the key sync had no code point (it was a caps lock press).
  // - check that the registered usage was that of caps lock.
  // - check that the net effect is that the caps lock modifier is locked
  // active.
  EXPECT_EQ(0u, keyboard.LastCodePoint());
  EXPECT_EQ(ToUsage(Key::CAPS_LOCK), keyboard.LastHIDUsage());
  EXPECT_EQ(kModifierCapsLock, keyboard.Modifiers());
}

TEST_F(KeyboardTest, CapsLockPress) {
  std::vector<KeyEvent> keys;
  keys.emplace_back(NewKeyEvent(KeyEventType::PRESSED, Key::CAPS_LOCK));

  Keyboard keyboard;
  ConsumeEvents(&keyboard, keys);

  EXPECT_EQ(0u, keyboard.LastCodePoint());
  EXPECT_EQ(ToUsage(Key::CAPS_LOCK), keyboard.LastHIDUsage());
  EXPECT_EQ(kModifierCapsLock, keyboard.Modifiers());
}

TEST_F(KeyboardTest, CapsLockPressRelease) {
  std::vector<KeyEvent> keys;
  keys.emplace_back(NewKeyEvent(KeyEventType::PRESSED, Key::CAPS_LOCK));
  keys.emplace_back(NewKeyEvent(KeyEventType::RELEASED, Key::CAPS_LOCK));

  Keyboard keyboard;
  ConsumeEvents(&keyboard, keys);

  EXPECT_EQ(0u, keyboard.LastCodePoint());
  EXPECT_EQ(ToUsage(Key::CAPS_LOCK), keyboard.LastHIDUsage());
  EXPECT_EQ(kModifierCapsLock, keyboard.Modifiers());
}

TEST_F(KeyboardTest, ShiftA) {
  std::vector<KeyEvent> keys;
  keys.emplace_back(NewKeyEvent(KeyEventType::PRESSED, Key::LEFT_SHIFT));
  keys.emplace_back(NewKeyEvent(KeyEventType::PRESSED, Key::A));

  Keyboard keyboard;
  ConsumeEvents(&keyboard, keys);

  EXPECT_EQ(static_cast<uint32_t>('A'), keyboard.LastCodePoint());
  EXPECT_EQ(ToUsage(Key::A), keyboard.LastHIDUsage());
  EXPECT_EQ(kModifierLeftShift, keyboard.Modifiers());
}

TEST_F(KeyboardTest, ShiftAWithRelease) {
  std::vector<KeyEvent> keys;
  keys.emplace_back(NewKeyEvent(KeyEventType::PRESSED, Key::LEFT_SHIFT));
  keys.emplace_back(NewKeyEvent(KeyEventType::PRESSED, Key::A));
  keys.emplace_back(NewKeyEvent(KeyEventType::RELEASED, Key::A));

  Keyboard keyboard;
  ConsumeEvents(&keyboard, keys);

  EXPECT_EQ(static_cast<uint32_t>('A'), keyboard.LastCodePoint());
  EXPECT_EQ(ToUsage(Key::A), keyboard.LastHIDUsage());
  EXPECT_EQ(kModifierLeftShift, keyboard.Modifiers());
}

TEST_F(KeyboardTest, ShiftAWithReleaseShift) {
  std::vector<KeyEvent> keys;
  keys.emplace_back(NewKeyEvent(KeyEventType::PRESSED, Key::LEFT_SHIFT));
  keys.emplace_back(NewKeyEvent(KeyEventType::PRESSED, Key::A));
  keys.emplace_back(NewKeyEvent(KeyEventType::RELEASED, Key::LEFT_SHIFT));
  keys.emplace_back(NewKeyEvent(KeyEventType::RELEASED, Key::A));

  Keyboard keyboard;
  ConsumeEvents(&keyboard, keys);

  EXPECT_EQ(static_cast<uint32_t>('a'), keyboard.LastCodePoint());
  EXPECT_EQ(ToUsage(Key::A), keyboard.LastHIDUsage());
  EXPECT_EQ(kModifierNone, keyboard.Modifiers());
}

TEST_F(KeyboardTest, LowcaseA) {
  std::vector<KeyEvent> keys;
  keys.emplace_back(NewKeyEvent(KeyEventType::PRESSED, Key::A));
  keys.emplace_back(NewKeyEvent(KeyEventType::RELEASED, Key::A));

  Keyboard keyboard;
  ConsumeEvents(&keyboard, keys);

  EXPECT_EQ(static_cast<uint32_t>('a'), keyboard.LastCodePoint());
  EXPECT_EQ(ToUsage(Key::A), keyboard.LastHIDUsage());
  EXPECT_EQ(kModifierNone, keyboard.Modifiers());
}

}  // namespace
}  // namespace flutter_runner
