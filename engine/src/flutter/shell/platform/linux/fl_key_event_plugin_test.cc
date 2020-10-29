// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_key_event_plugin.h"

#include <iostream>
#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_basic_message_channel.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_standard_message_codec.h"
#include "flutter/shell/platform/linux/testing/fl_test.h"
#include "flutter/shell/platform/linux/testing/mock_renderer.h"

const char* expected_value = nullptr;

// Called when the message response is received in the send_key_event test.
static void echo_response_cb(GObject* object,
                             GAsyncResult* result,
                             gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlValue) message = fl_basic_message_channel_send_finish(
      FL_BASIC_MESSAGE_CHANNEL(object), result, &error);
  EXPECT_NE(message, nullptr);
  EXPECT_EQ(error, nullptr);

  EXPECT_EQ(fl_value_get_type(message), FL_VALUE_TYPE_MAP);
  EXPECT_STREQ(fl_value_to_string(message), expected_value);
  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Test sending a letter "A";
TEST(FlKeyEventPluginTest, SendKeyEvent) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlKeyEventPlugin) plugin =
      fl_key_event_plugin_new(messenger, echo_response_cb, "test/echo");

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
  fl_key_event_plugin_send_key_event(plugin, &key_event, loop);

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);

  key_event = GdkEventKey{
      GDK_KEY_RELEASE,                       // event type
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
      "{type: keyup, keymap: linux, scanCode: 4, toolkit: gtk, keyCode: 65, "
      "modifiers: 0, unicodeScalarValues: 65}";
  fl_key_event_plugin_send_key_event(plugin, &key_event, loop);

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);
}

void test_lock_event(guint key_code,
                     const char* down_expected,
                     const char* up_expected) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlKeyEventPlugin) plugin =
      fl_key_event_plugin_new(messenger, echo_response_cb, "test/echo");

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
  fl_key_event_plugin_send_key_event(plugin, &key_event, loop);

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);

  key_event.type = GDK_KEY_RELEASE;

  expected_value = up_expected;
  fl_key_event_plugin_send_key_event(plugin, &key_event, loop);

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);
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
