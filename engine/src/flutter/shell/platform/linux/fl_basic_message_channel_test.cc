// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Included first as it collides with the X11 headers.
#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_basic_message_channel.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_standard_message_codec.h"
#include "flutter/shell/platform/linux/testing/mock_renderer.h"

// Creates a mock engine that responds to platform messages.
static FlEngine* make_mock_engine() {
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlMockRenderer) renderer = fl_mock_renderer_new();
  g_autoptr(GError) renderer_error = nullptr;
  EXPECT_TRUE(fl_renderer_setup(FL_RENDERER(renderer), &renderer_error));
  EXPECT_EQ(renderer_error, nullptr);
  g_autoptr(FlEngine) engine = fl_engine_new(project, FL_RENDERER(renderer));
  g_autoptr(GError) engine_error = nullptr;
  EXPECT_TRUE(fl_engine_start(engine, &engine_error));
  EXPECT_EQ(engine_error, nullptr);

  return static_cast<FlEngine*>(g_object_ref(engine));
}

// Called when the message response is received in the SendMessage test.
static void echo_response_cb(GObject* object,
                             GAsyncResult* result,
                             gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlValue) message = fl_basic_message_channel_send_finish(
      FL_BASIC_MESSAGE_CHANNEL(object), result, &error);
  EXPECT_NE(message, nullptr);
  EXPECT_EQ(error, nullptr);

  EXPECT_EQ(fl_value_get_type(message), FL_VALUE_TYPE_STRING);
  EXPECT_STREQ(fl_value_get_string(message), "Hello World!");

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks sending a message works.
TEST(FlBasicMessageChannelTest, SendMessage) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMessageCodec) codec = fl_standard_message_codec_new();
  g_autoptr(FlBasicMessageChannel) channel = fl_basic_message_channel_new(
      messenger, "test/echo", FL_MESSAGE_CODEC(codec));
  g_autoptr(FlValue) message = fl_value_new_string("Hello World!");
  fl_basic_message_channel_send(channel, message, nullptr, echo_response_cb,
                                loop);

  // Blocks here until echo_response_cb is called.
  g_main_loop_run(loop);
}

// Called when the message response is received in the SendFailure test.
static void failure_response_cb(GObject* object,
                                GAsyncResult* result,
                                gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlValue) message = fl_basic_message_channel_send_finish(
      FL_BASIC_MESSAGE_CHANNEL(object), result, &error);
  EXPECT_EQ(message, nullptr);
  EXPECT_NE(error, nullptr);

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks the engine reporting a send failure is handled.
TEST(FlBasicMessageChannelTest, SendFailure) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMessageCodec) codec = fl_standard_message_codec_new();
  g_autoptr(FlBasicMessageChannel) channel = fl_basic_message_channel_new(
      messenger, "test/failure", FL_MESSAGE_CODEC(codec));
  g_autoptr(FlValue) message = fl_value_new_string("Hello World!");
  fl_basic_message_channel_send(channel, message, nullptr, failure_response_cb,
                                loop);

  // Blocks here until failure_response_cb is called.
  g_main_loop_run(loop);
}

// Called when a message is received from the engine in the ReceiveMessage test.
static void message_cb(FlBasicMessageChannel* channel,
                       FlValue* message,
                       FlBasicMessageChannelResponseHandle* response_handle,
                       gpointer user_data) {
  EXPECT_NE(message, nullptr);
  EXPECT_EQ(fl_value_get_type(message), FL_VALUE_TYPE_STRING);
  EXPECT_STREQ(fl_value_get_string(message), "Marco!");

  g_autoptr(GError) error = nullptr;
  g_autoptr(FlValue) response = fl_value_new_string("Polo!");
  EXPECT_TRUE(fl_basic_message_channel_respond(channel, response_handle,
                                               response, &error));
  EXPECT_EQ(error, nullptr);
}

// Called when a the test engine notifies us what response we sent in the
// ReceiveMessage test.
static void response_cb(FlBasicMessageChannel* channel,
                        FlValue* message,
                        FlBasicMessageChannelResponseHandle* response_handle,
                        gpointer user_data) {
  EXPECT_NE(message, nullptr);
  EXPECT_EQ(fl_value_get_type(message), FL_VALUE_TYPE_STRING);
  EXPECT_STREQ(fl_value_get_string(message), "Polo!");

  fl_basic_message_channel_respond(channel, response_handle, nullptr, nullptr);

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks the shell able to receive and respond to messages from the engine.
TEST(FlBasicMessageChannelTest, ReceiveMessage) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);

  // Listen for messages from the engine.
  g_autoptr(FlStandardMessageCodec) codec = fl_standard_message_codec_new();
  g_autoptr(FlBasicMessageChannel) messages_channel =
      fl_basic_message_channel_new(messenger, "test/messages",
                                   FL_MESSAGE_CODEC(codec));
  fl_basic_message_channel_set_message_handler(messages_channel, message_cb,
                                               nullptr, nullptr);

  // Listen for response from the engine.
  g_autoptr(FlBasicMessageChannel) responses_channel =
      fl_basic_message_channel_new(messenger, "test/responses",
                                   FL_MESSAGE_CODEC(codec));
  fl_basic_message_channel_set_message_handler(responses_channel, response_cb,
                                               loop, nullptr);

  // Triggger the engine to send a message.
  g_autoptr(FlBasicMessageChannel) control_channel =
      fl_basic_message_channel_new(messenger, "test/send-message",
                                   FL_MESSAGE_CODEC(codec));
  g_autoptr(FlValue) message = fl_value_new_string("Marco!");
  fl_basic_message_channel_send(control_channel, message, nullptr, nullptr,
                                nullptr);

  // Blocks here until response_cb is called.
  g_main_loop_run(loop);
}
