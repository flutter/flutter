// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_mouse_cursor_handler.h"

#include "flutter/shell/platform/linux/public/flutter_linux/fl_method_response.h"
#include "flutter/shell/platform/linux/testing/fl_mock_binary_messenger.h"

#include "gtest/gtest.h"

// Activates a system cursor by sending an activateSystemCursor method call with
// the given kind, returning whether a response was received.
static gboolean activate_system_cursor(FlMockBinaryMessenger* messenger,
                                       FlValue* kind) {
  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string(args, "kind", kind);

  gboolean called = FALSE;
  fl_mock_binary_messenger_invoke_standard_method(
      messenger, "flutter/mousecursor", "activateSystemCursor", args,
      [](FlMockBinaryMessenger* messenger, FlMethodResponse* response,
         gpointer user_data) {
        gboolean* called = static_cast<gboolean*>(user_data);
        *called = TRUE;

        EXPECT_TRUE(FL_IS_METHOD_SUCCESS_RESPONSE(response));
      },
      &called);

  return called;
}

// A newly created handler has no cursor set.
TEST(FlMouseCursorHandlerTest, InitialCursorName) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  g_autoptr(FlMouseCursorHandler) handler =
      fl_mouse_cursor_handler_new(FL_BINARY_MESSENGER(messenger));

  EXPECT_STREQ(fl_mouse_cursor_handler_get_cursor_name(handler), "");
}

// Activating a known cursor kind maps it to the matching GTK cursor name.
TEST(FlMouseCursorHandlerTest, ActivateSystemCursor) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  g_autoptr(FlMouseCursorHandler) handler =
      fl_mouse_cursor_handler_new(FL_BINARY_MESSENGER(messenger));

  g_autoptr(FlValue) kind = fl_value_new_string("click");
  EXPECT_TRUE(activate_system_cursor(messenger, kind));

  EXPECT_STREQ(fl_mouse_cursor_handler_get_cursor_name(handler), "pointer");
}

// The "basic" cursor kind maps to the GTK "default" cursor.
TEST(FlMouseCursorHandlerTest, BasicCursor) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  g_autoptr(FlMouseCursorHandler) handler =
      fl_mouse_cursor_handler_new(FL_BINARY_MESSENGER(messenger));

  g_autoptr(FlValue) kind = fl_value_new_string("basic");
  EXPECT_TRUE(activate_system_cursor(messenger, kind));

  EXPECT_STREQ(fl_mouse_cursor_handler_get_cursor_name(handler), "default");
}

// An unknown cursor kind falls back to the GTK "default" cursor.
TEST(FlMouseCursorHandlerTest, UnknownCursorFallsBackToDefault) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  g_autoptr(FlMouseCursorHandler) handler =
      fl_mouse_cursor_handler_new(FL_BINARY_MESSENGER(messenger));

  g_autoptr(FlValue) kind = fl_value_new_string("madeUpCursorKind");
  EXPECT_TRUE(activate_system_cursor(messenger, kind));

  EXPECT_STREQ(fl_mouse_cursor_handler_get_cursor_name(handler), "default");
}

// A call whose argument map omits the "kind" key falls back to the GTK
// "default" cursor without crashing.
TEST(FlMouseCursorHandlerTest, MissingKindFallsBackToDefault) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  g_autoptr(FlMouseCursorHandler) handler =
      fl_mouse_cursor_handler_new(FL_BINARY_MESSENGER(messenger));

  gboolean called = FALSE;
  g_autoptr(FlValue) args = fl_value_new_map();
  fl_mock_binary_messenger_invoke_standard_method(
      messenger, "flutter/mousecursor", "activateSystemCursor", args,
      [](FlMockBinaryMessenger* messenger, FlMethodResponse* response,
         gpointer user_data) {
        gboolean* called = static_cast<gboolean*>(user_data);
        *called = TRUE;

        EXPECT_TRUE(FL_IS_METHOD_SUCCESS_RESPONSE(response));
      },
      &called);
  EXPECT_TRUE(called);

  EXPECT_STREQ(fl_mouse_cursor_handler_get_cursor_name(handler), "default");
}

// Changing the cursor emits the cursor-changed signal.
TEST(FlMouseCursorHandlerTest, CursorChangedSignal) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  g_autoptr(FlMouseCursorHandler) handler =
      fl_mouse_cursor_handler_new(FL_BINARY_MESSENGER(messenger));

  gboolean cursor_changed = FALSE;
  g_signal_connect_swapped(
      handler, "cursor-changed",
      G_CALLBACK(+[](gboolean* cursor_changed) { *cursor_changed = TRUE; }),
      &cursor_changed);

  g_autoptr(FlValue) kind = fl_value_new_string("grab");
  EXPECT_TRUE(activate_system_cursor(messenger, kind));

  EXPECT_TRUE(cursor_changed);
  EXPECT_STREQ(fl_mouse_cursor_handler_get_cursor_name(handler), "grab");
}

// A call with malformed (non-map) arguments returns an error response.
TEST(FlMouseCursorHandlerTest, BadArguments) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  g_autoptr(FlMouseCursorHandler) handler =
      fl_mouse_cursor_handler_new(FL_BINARY_MESSENGER(messenger));

  gboolean called = FALSE;
  g_autoptr(FlValue) args = fl_value_new_null();
  fl_mock_binary_messenger_invoke_standard_method(
      messenger, "flutter/mousecursor", "activateSystemCursor", args,
      [](FlMockBinaryMessenger* messenger, FlMethodResponse* response,
         gpointer user_data) {
        gboolean* called = static_cast<gboolean*>(user_data);
        *called = TRUE;

        EXPECT_TRUE(FL_IS_METHOD_ERROR_RESPONSE(response));
        EXPECT_STREQ(fl_method_error_response_get_code(
                         FL_METHOD_ERROR_RESPONSE(response)),
                     "Bad Arguments");
      },
      &called);
  EXPECT_TRUE(called);

  // The cursor is unchanged.
  EXPECT_STREQ(fl_mouse_cursor_handler_get_cursor_name(handler), "");
}

// An unknown method returns a not-implemented response.
TEST(FlMouseCursorHandlerTest, UnknownMethod) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  g_autoptr(FlMouseCursorHandler) handler =
      fl_mouse_cursor_handler_new(FL_BINARY_MESSENGER(messenger));

  gboolean called = FALSE;
  g_autoptr(FlValue) args = fl_value_new_null();
  fl_mock_binary_messenger_invoke_standard_method(
      messenger, "flutter/mousecursor", "someUnknownMethod", args,
      [](FlMockBinaryMessenger* messenger, FlMethodResponse* response,
         gpointer user_data) {
        gboolean* called = static_cast<gboolean*>(user_data);
        *called = TRUE;

        EXPECT_TRUE(FL_IS_METHOD_NOT_IMPLEMENTED_RESPONSE(response));
      },
      &called);
  EXPECT_TRUE(called);
}
