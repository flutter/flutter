// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_key_event_plugin.h"
#include "flutter/shell/platform/linux/fl_key_event_plugin_private.h"

#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/testing/fl_test.h"
#include "flutter/shell/platform/linux/testing/mock_text_input_plugin.h"

static const char* expected_value = nullptr;
static gboolean expected_handled = FALSE;
static uint64_t expected_id = 0;
static FlKeyEventPlugin* expected_self = nullptr;

// Called when the message response is received in the send_key_event test.
static void echo_response_cb(GObject* object,
                             FlValue* message,
                             gboolean handled,
                             gpointer user_data) {
  EXPECT_NE(message, nullptr);
  EXPECT_EQ(fl_value_get_type(message), FL_VALUE_TYPE_MAP);
  EXPECT_STREQ(fl_value_to_string(message), expected_value);
  EXPECT_EQ(handled, expected_handled);
  if (expected_self != nullptr) {
    if (handled) {
      EXPECT_EQ(
          fl_key_event_plugin_find_pending_event(expected_self, expected_id),
          nullptr);
    } else {
      EXPECT_NE(
          fl_key_event_plugin_find_pending_event(expected_self, expected_id),
          nullptr);
    }
  }

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

static gboolean handle_keypress(FlTextInputPlugin* plugin, GdkEventKey* event) {
  return TRUE;
}

static gboolean ignore_keypress(FlTextInputPlugin* plugin, GdkEventKey* event) {
  return FALSE;
}

// Test sending a letter "A";
TEST(FlKeyEventPluginTest, SendKeyEvent) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlTextInputPlugin) text_input_plugin =
      FL_TEXT_INPUT_PLUGIN(fl_mock_text_input_plugin_new(handle_keypress));
  g_autoptr(FlKeyEventPlugin) plugin = fl_key_event_plugin_new(
      messenger, text_input_plugin, echo_response_cb, "test/echo");

  char string[] = "A";
  GdkEventKey key_event = GdkEventKey{
      GDK_KEY_PRESS,                         // event type
      nullptr,                               // window (not needed)
      FALSE,                                 // event was sent explicitly
      12345,                                 // time
      0x0,                                   // modifier state
      GDK_KEY_A,                             // key code
      1,                                     // length of string representation
      reinterpret_cast<gchar*>(&string[0]),  // string representation
      0x04,                                  // scan code
      0,                                     // keyboard group
      0,                                     // is a modifier
  };

  expected_value =
      "{type: keydown, keymap: linux, scanCode: 4, toolkit: gtk, keyCode: 65, "
      "modifiers: 0, unicodeScalarValues: 65}";
  expected_handled = FALSE;
  fl_key_event_plugin_send_key_event(plugin, &key_event, loop);

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);
  EXPECT_NE(fl_key_event_plugin_find_pending_event(
                plugin, fl_key_event_plugin_get_event_id(&key_event)),
            nullptr);

  key_event = GdkEventKey{
      GDK_KEY_RELEASE,                       // event type
      nullptr,                               // window (not needed)
      FALSE,                                 // event was sent explicitly
      23456,                                 // time
      0x0,                                   // modifier state
      GDK_KEY_A,                             // key code
      1,                                     // length of string representation
      reinterpret_cast<gchar*>(&string[0]),  // string representation
      0x04,                                  // scan code
      0,                                     // keyboard group
      0,                                     // is a modifier
  };

  expected_value =
      "{type: keyup, keymap: linux, scanCode: 4, toolkit: gtk, keyCode: 65, "
      "modifiers: 0, unicodeScalarValues: 65}";
  expected_handled = FALSE;
  bool handled = fl_key_event_plugin_send_key_event(plugin, &key_event, loop);
  EXPECT_TRUE(handled);

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);
  EXPECT_NE(fl_key_event_plugin_find_pending_event(
                plugin, fl_key_event_plugin_get_event_id(&key_event)),
            nullptr);
}

void test_lock_event(guint key_code,
                     const char* down_expected,
                     const char* up_expected) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlTextInputPlugin) text_input_plugin =
      FL_TEXT_INPUT_PLUGIN(fl_mock_text_input_plugin_new(handle_keypress));
  g_autoptr(FlKeyEventPlugin) plugin = fl_key_event_plugin_new(
      messenger, text_input_plugin, echo_response_cb, "test/echo");

  GdkEventKey key_event = GdkEventKey{
      GDK_KEY_PRESS,  // event type
      nullptr,        // window (not needed)
      FALSE,          // event was sent explicitly
      12345,          // time
      0x10,           // modifier state
      key_code,       // key code
      1,              // length of string representation
      nullptr,        // string representation
      0x04,           // scan code
      0,              // keyboard group
      0,              // is a modifier
  };

  expected_value = down_expected;
  expected_handled = FALSE;
  bool handled = fl_key_event_plugin_send_key_event(plugin, &key_event, loop);
  EXPECT_TRUE(handled);

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);
  EXPECT_NE(fl_key_event_plugin_find_pending_event(
                plugin, fl_key_event_plugin_get_event_id(&key_event)),
            nullptr);

  key_event.type = GDK_KEY_RELEASE;
  key_event.time++;

  expected_value = up_expected;
  expected_handled = FALSE;
  fl_key_event_plugin_send_key_event(plugin, &key_event, loop);

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);
  EXPECT_NE(fl_key_event_plugin_find_pending_event(
                plugin, fl_key_event_plugin_get_event_id(&key_event)),
            nullptr);
}

// Test sending a "NumLock" keypress.
TEST(FlKeyEventPluginTest, SendNumLockKeyEvent) {
  test_lock_event(GDK_KEY_Num_Lock,
                  "{type: keydown, keymap: linux, scanCode: 4, toolkit: gtk, "
                  "keyCode: 65407, modifiers: 16}",
                  "{type: keyup, keymap: linux, scanCode: 4, toolkit: gtk, "
                  "keyCode: 65407, modifiers: 0}");
}

// Test sending a "CapsLock" keypress.
TEST(FlKeyEventPluginTest, SendCapsLockKeyEvent) {
  test_lock_event(GDK_KEY_Caps_Lock,
                  "{type: keydown, keymap: linux, scanCode: 4, toolkit: gtk, "
                  "keyCode: 65509, modifiers: 2}",
                  "{type: keyup, keymap: linux, scanCode: 4, toolkit: gtk, "
                  "keyCode: 65509, modifiers: 0}");
}

// Test sending a "ShiftLock" keypress.
TEST(FlKeyEventPluginTest, SendShiftLockKeyEvent) {
  test_lock_event(GDK_KEY_Shift_Lock,
                  "{type: keydown, keymap: linux, scanCode: 4, toolkit: gtk, "
                  "keyCode: 65510, modifiers: 2}",
                  "{type: keyup, keymap: linux, scanCode: 4, toolkit: gtk, "
                  "keyCode: 65510, modifiers: 0}");
}

TEST(FlKeyEventPluginTest, TestKeyEventHandledByFramework) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlTextInputPlugin) text_input_plugin =
      FL_TEXT_INPUT_PLUGIN(fl_mock_text_input_plugin_new(handle_keypress));
  g_autoptr(FlKeyEventPlugin) plugin = fl_key_event_plugin_new(
      messenger, text_input_plugin, echo_response_cb, "test/key-event-handled");

  GdkEventKey key_event = GdkEventKey{
      GDK_KEY_PRESS,  // event type
      nullptr,        // window (not needed)
      FALSE,          // event was sent explicitly
      12345,          // time
      0x10,           // modifier state
      GDK_KEY_A,      // key code
      1,              // length of string representation
      nullptr,        // string representation
      0x04,           // scan code
      0,              // keyboard group
      0,              // is a modifier
  };

  expected_value = "{handled: true}";
  expected_handled = TRUE;
  bool handled = fl_key_event_plugin_send_key_event(plugin, &key_event, loop);
  // Should always be true, because the event was delayed.
  EXPECT_TRUE(handled);

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);
  EXPECT_EQ(fl_key_event_plugin_find_pending_event(
                plugin, fl_key_event_plugin_get_event_id(&key_event)),
            nullptr);
}

TEST(FlKeyEventPluginTest, TestKeyEventHandledByTextInputPlugin) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlTextInputPlugin) text_input_plugin =
      FL_TEXT_INPUT_PLUGIN(fl_mock_text_input_plugin_new(handle_keypress));
  g_autoptr(FlKeyEventPlugin) plugin =
      fl_key_event_plugin_new(messenger, text_input_plugin, echo_response_cb,
                              "test/key-event-not-handled");

  GdkEventKey key_event = GdkEventKey{
      GDK_KEY_PRESS,  // event type
      nullptr,        // window (not needed)
      FALSE,          // event was sent explicitly
      12345,          // time
      0x10,           // modifier state
      GDK_KEY_A,      // key code
      1,              // length of string representation
      nullptr,        // string representation
      0x04,           // scan code
      0,              // keyboard group
      0,              // is a modifier
  };

  expected_value = "{handled: false}";
  expected_handled = TRUE;
  bool handled = fl_key_event_plugin_send_key_event(plugin, &key_event, loop);
  // Should always be true, because the event was delayed.
  EXPECT_TRUE(handled);

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);
  EXPECT_EQ(fl_key_event_plugin_find_pending_event(
                plugin, fl_key_event_plugin_get_event_id(&key_event)),
            nullptr);
}

TEST(FlKeyEventPluginTest, TestKeyEventNotHandledByTextInputPlugin) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlTextInputPlugin) text_input_plugin =
      FL_TEXT_INPUT_PLUGIN(fl_mock_text_input_plugin_new(ignore_keypress));
  g_autoptr(FlKeyEventPlugin) plugin =
      fl_key_event_plugin_new(messenger, text_input_plugin, echo_response_cb,
                              "test/key-event-not-handled");

  GdkEventKey key_event = GdkEventKey{
      GDK_KEY_PRESS,  // event type
      nullptr,        // window (not needed)
      FALSE,          // event was sent explicitly
      12345,          // time
      0x10,           // modifier state
      GDK_KEY_A,      // key code
      1,              // length of string representation
      nullptr,        // string representation
      0x04,           // scan code
      0,              // keyboard group
      0,              // is a modifier
  };

  expected_value = "{handled: false}";
  expected_handled = FALSE;
  bool handled = fl_key_event_plugin_send_key_event(plugin, &key_event, loop);
  // Should always be true, because the event was delayed.
  EXPECT_TRUE(handled);

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);
  EXPECT_NE(fl_key_event_plugin_find_pending_event(
                plugin, fl_key_event_plugin_get_event_id(&key_event)),
            nullptr);
}

TEST(FlKeyEventPluginTest, TestKeyEventResponseOutOfOrderFromFramework) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlTextInputPlugin) text_input_plugin =
      FL_TEXT_INPUT_PLUGIN(fl_mock_text_input_plugin_new(handle_keypress));
  g_autoptr(FlKeyEventPlugin) plugin = fl_key_event_plugin_new(
      messenger, text_input_plugin, echo_response_cb, "test/key-event-delayed");

  GdkEventKey key_event = GdkEventKey{
      GDK_KEY_PRESS,  // event type
      nullptr,        // window (not needed)
      FALSE,          // event was sent explicitly
      12345,          // time
      0x10,           // modifier state
      GDK_KEY_A,      // key code
      1,              // length of string representation
      nullptr,        // string representation
      0x04,           // scan code
      0,              // keyboard group
      0,              // is a modifier
  };

  expected_value = "{handled: true}";
  expected_handled = TRUE;
  expected_self = plugin;
  uint64_t event_id_a = fl_key_event_plugin_get_event_id(&key_event);
  expected_id = event_id_a;
  bool handled = fl_key_event_plugin_send_key_event(plugin, &key_event, loop);
  // Should always be true, because the event was delayed.
  EXPECT_TRUE(handled);
  EXPECT_EQ(fl_key_event_plugin_find_pending_event(plugin, event_id_a)->keyval,
            static_cast<guint>(GDK_KEY_A));

  // Send a second key event that will be out of order.
  key_event.keyval = GDK_KEY_B;
  key_event.hardware_keycode = 0x05;
  uint64_t event_id_b = fl_key_event_plugin_get_event_id(&key_event);
  expected_id = event_id_b;
  handled = fl_key_event_plugin_send_key_event(plugin, &key_event, loop);
  EXPECT_TRUE(handled);
  EXPECT_EQ(fl_key_event_plugin_find_pending_event(plugin, event_id_b)->keyval,
            static_cast<guint>(GDK_KEY_B));

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);

  // Make sure they both were removed
  EXPECT_EQ(fl_key_event_plugin_find_pending_event(plugin, event_id_a),
            nullptr);
  EXPECT_EQ(fl_key_event_plugin_find_pending_event(plugin, event_id_b),
            nullptr);
  expected_self = nullptr;
  expected_id = 0;
}
