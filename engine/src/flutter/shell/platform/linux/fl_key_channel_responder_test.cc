// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_key_channel_responder.h"

#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/testing/fl_test.h"

static const char* expected_value = nullptr;
static gboolean expected_handled = FALSE;

static FlValue* echo_response_cb(FlValue* echoed_value) {
  gchar* text = fl_value_to_string(echoed_value);
  EXPECT_STREQ(text, expected_value);
  g_free(text);

  FlValue* value = fl_value_new_map();
  fl_value_set_string_take(value, "handled",
                           fl_value_new_bool(expected_handled));
  return value;
}

static void responder_callback(bool handled, gpointer user_data) {
  EXPECT_EQ(handled, expected_handled);
  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Test sending a letter "A";
TEST(FlKeyChannelResponderTest, SendKeyEvent) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  FlKeyChannelResponderMock mock{
      .value_converter = echo_response_cb,
      .channel_name = "test/echo",
  };
  g_autoptr(FlKeyResponder) responder =
      FL_KEY_RESPONDER(fl_key_channel_responder_new(messenger, &mock));

  g_autoptr(FlKeyEvent) event1 = fl_key_event_new(
      12345, TRUE, 0x04, GDK_KEY_A, static_cast<GdkModifierType>(0), 0);
  fl_key_responder_handle_event(responder, event1, responder_callback, loop);
  expected_value =
      "{type: keydown, keymap: linux, scanCode: 4, toolkit: gtk, keyCode: 65, "
      "modifiers: 0, unicodeScalarValues: 65}";
  expected_handled = FALSE;

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);

  g_autoptr(FlKeyEvent) event2 = fl_key_event_new(
      23456, FALSE, 0x04, GDK_KEY_A, static_cast<GdkModifierType>(0), 0);
  fl_key_responder_handle_event(responder, event2, responder_callback, loop);
  expected_value =
      "{type: keyup, keymap: linux, scanCode: 4, toolkit: gtk, keyCode: 65, "
      "modifiers: 0, unicodeScalarValues: 65}";
  expected_handled = FALSE;

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);
}

void test_lock_event(guint key_code,
                     const char* down_expected,
                     const char* up_expected) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  FlKeyChannelResponderMock mock{
      .value_converter = echo_response_cb,
      .channel_name = "test/echo",
  };
  g_autoptr(FlKeyResponder) responder =
      FL_KEY_RESPONDER(fl_key_channel_responder_new(messenger, &mock));

  g_autoptr(FlKeyEvent) event1 = fl_key_event_new(
      12345, TRUE, 0x04, key_code, static_cast<GdkModifierType>(0), 0);
  fl_key_responder_handle_event(responder, event1, responder_callback, loop);
  expected_value = down_expected;
  expected_handled = FALSE;

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);

  expected_value = up_expected;
  expected_handled = FALSE;
  g_autoptr(FlKeyEvent) event2 = fl_key_event_new(
      12346, FALSE, 0x04, key_code, static_cast<GdkModifierType>(0), 0);
  fl_key_responder_handle_event(responder, event2, responder_callback, loop);

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);
}

// Test sending a "NumLock" keypress.
TEST(FlKeyChannelResponderTest, SendNumLockKeyEvent) {
  test_lock_event(GDK_KEY_Num_Lock,
                  "{type: keydown, keymap: linux, scanCode: 4, toolkit: gtk, "
                  "keyCode: 65407, modifiers: 16}",
                  "{type: keyup, keymap: linux, scanCode: 4, toolkit: gtk, "
                  "keyCode: 65407, modifiers: 0}");
}

// Test sending a "CapsLock" keypress.
TEST(FlKeyChannelResponderTest, SendCapsLockKeyEvent) {
  test_lock_event(GDK_KEY_Caps_Lock,
                  "{type: keydown, keymap: linux, scanCode: 4, toolkit: gtk, "
                  "keyCode: 65509, modifiers: 2}",
                  "{type: keyup, keymap: linux, scanCode: 4, toolkit: gtk, "
                  "keyCode: 65509, modifiers: 0}");
}

// Test sending a "ShiftLock" keypress.
TEST(FlKeyChannelResponderTest, SendShiftLockKeyEvent) {
  test_lock_event(GDK_KEY_Shift_Lock,
                  "{type: keydown, keymap: linux, scanCode: 4, toolkit: gtk, "
                  "keyCode: 65510, modifiers: 2}",
                  "{type: keyup, keymap: linux, scanCode: 4, toolkit: gtk, "
                  "keyCode: 65510, modifiers: 0}");
}

TEST(FlKeyChannelResponderTest, TestKeyEventHandledByFramework) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  FlKeyChannelResponderMock mock{
      .value_converter = echo_response_cb,
      .channel_name = "test/echo",
  };
  g_autoptr(FlKeyResponder) responder =
      FL_KEY_RESPONDER(fl_key_channel_responder_new(messenger, &mock));

  g_autoptr(FlKeyEvent) event = fl_key_event_new(
      12345, TRUE, 0x04, GDK_KEY_A, static_cast<GdkModifierType>(0), 0);
  fl_key_responder_handle_event(responder, event, responder_callback, loop);
  expected_handled = TRUE;
  expected_value =
      "{type: keydown, keymap: linux, scanCode: 4, toolkit: gtk, "
      "keyCode: 65, modifiers: 0, unicodeScalarValues: 65}";

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);
}

TEST(FlKeyChannelResponderTest, UseSpecifiedLogicalKey) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  FlKeyChannelResponderMock mock{
      .value_converter = echo_response_cb,
      .channel_name = "test/echo",
  };
  g_autoptr(FlKeyResponder) responder =
      FL_KEY_RESPONDER(fl_key_channel_responder_new(messenger, &mock));

  g_autoptr(FlKeyEvent) event = fl_key_event_new(
      12345, TRUE, 0x04, GDK_KEY_A, static_cast<GdkModifierType>(0), 0);
  fl_key_responder_handle_event(responder, event, responder_callback, loop,
                                888);
  expected_handled = TRUE;
  expected_value =
      "{type: keydown, keymap: linux, scanCode: 4, toolkit: gtk, "
      "keyCode: 65, modifiers: 0, unicodeScalarValues: 65, "
      "specifiedLogicalKey: 888}";

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);
}
