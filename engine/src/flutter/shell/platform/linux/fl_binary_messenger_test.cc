// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Included first as it collides with the X11 headers.
#include "gtest/gtest.h"

#include <cstring>

#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"
#include "flutter/shell/platform/linux/testing/fl_test.h"
#include "flutter/shell/platform/linux/testing/mock_renderer.h"

// Checks sending nullptr for a message works.
TEST(FlBinaryMessengerTest, SendNullptrMessage) {
  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  fl_binary_messenger_send_on_channel(messenger, "test/echo", nullptr, nullptr,
                                      nullptr, nullptr);
}

// Checks sending a zero length message works.
TEST(FlBinaryMessengerTest, SendEmptyMessage) {
  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(GBytes) message = g_bytes_new(nullptr, 0);
  fl_binary_messenger_send_on_channel(messenger, "test/echo", message, nullptr,
                                      nullptr, nullptr);
}

// Called when the message response is received in the SendMessage test.
static void echo_response_cb(GObject* object,
                             GAsyncResult* result,
                             gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(GBytes) message = fl_binary_messenger_send_on_channel_finish(
      FL_BINARY_MESSENGER(object), result, &error);
  EXPECT_NE(message, nullptr);
  EXPECT_EQ(error, nullptr);

  g_autofree gchar* text =
      g_strndup(static_cast<const gchar*>(g_bytes_get_data(message, nullptr)),
                g_bytes_get_size(message));
  EXPECT_STREQ(text, "Hello World!");

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks sending a message works.
TEST(FlBinaryMessengerTest, SendMessage) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  const char* text = "Hello World!";
  g_autoptr(GBytes) message = g_bytes_new(text, strlen(text));
  fl_binary_messenger_send_on_channel(messenger, "test/echo", message, nullptr,
                                      echo_response_cb, loop);

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);
}

// Called when the message response is received in the NullptrResponse test.
static void nullptr_response_cb(GObject* object,
                                GAsyncResult* result,
                                gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(GBytes) message = fl_binary_messenger_send_on_channel_finish(
      FL_BINARY_MESSENGER(object), result, &error);
  EXPECT_NE(message, nullptr);
  EXPECT_EQ(error, nullptr);

  EXPECT_EQ(g_bytes_get_size(message), static_cast<gsize>(0));

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks the engine returning a nullptr message work.
TEST(FlBinaryMessengerTest, NullptrResponse) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  const char* text = "Hello World!";
  g_autoptr(GBytes) message = g_bytes_new(text, strlen(text));
  fl_binary_messenger_send_on_channel(messenger, "test/nullptr-response",
                                      message, nullptr, nullptr_response_cb,
                                      loop);

  // Blocks here until nullptr_response_cb is called.
  g_main_loop_run(loop);
}

// Called when the message response is received in the SendFailure test.
static void failure_response_cb(GObject* object,
                                GAsyncResult* result,
                                gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(GBytes) message = fl_binary_messenger_send_on_channel_finish(
      FL_BINARY_MESSENGER(object), result, &error);
  EXPECT_EQ(message, nullptr);
  EXPECT_NE(error, nullptr);

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks the engine reporting a send failure is handled.
TEST(FlBinaryMessengerTest, SendFailure) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  fl_binary_messenger_send_on_channel(messenger, "test/failure", nullptr,
                                      nullptr, failure_response_cb, loop);

  // Blocks here until failure_response_cb is called.
  g_main_loop_run(loop);
}

// Called when a message is received from the engine in the ReceiveMessage test.
static void message_cb(FlBinaryMessenger* messenger,
                       const gchar* channel,
                       GBytes* message,
                       FlBinaryMessengerResponseHandle* response_handle,
                       gpointer user_data) {
  EXPECT_NE(message, nullptr);
  g_autofree gchar* text =
      g_strndup(static_cast<const gchar*>(g_bytes_get_data(message, nullptr)),
                g_bytes_get_size(message));
  EXPECT_STREQ(text, "Marco!");

  const char* response_text = "Polo!";
  g_autoptr(GBytes) response =
      g_bytes_new(response_text, strlen(response_text));
  g_autoptr(GError) error = nullptr;
  EXPECT_TRUE(fl_binary_messenger_send_response(messenger, response_handle,
                                                response, &error));
  EXPECT_EQ(error, nullptr);
}

// Called when a the test engine notifies us what response we sent in the
// ReceiveMessage test.
static void response_cb(FlBinaryMessenger* messenger,
                        const gchar* channel,
                        GBytes* message,
                        FlBinaryMessengerResponseHandle* response_handle,
                        gpointer user_data) {
  EXPECT_NE(message, nullptr);
  g_autofree gchar* text =
      g_strndup(static_cast<const gchar*>(g_bytes_get_data(message, nullptr)),
                g_bytes_get_size(message));
  EXPECT_STREQ(text, "Polo!");

  fl_binary_messenger_send_response(messenger, response_handle, nullptr,
                                    nullptr);

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks the shell able to receive and respond to messages from the engine.
TEST(FlBinaryMessengerTest, ReceiveMessage) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);

  // Listen for messages from the engine.
  fl_binary_messenger_set_message_handler_on_channel(
      messenger, "test/messages", message_cb, nullptr, nullptr);

  // Listen for response from the engine.
  fl_binary_messenger_set_message_handler_on_channel(
      messenger, "test/responses", response_cb, loop, nullptr);

  // Trigger the engine to send a message.
  const char* text = "Marco!";
  g_autoptr(GBytes) message = g_bytes_new(text, strlen(text));
  fl_binary_messenger_send_on_channel(messenger, "test/send-message", message,
                                      nullptr, nullptr, nullptr);

  // Blocks here until response_cb is called.
  g_main_loop_run(loop);
}
