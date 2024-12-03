// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Included first as it collides with the X11 headers.
#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/public/flutter_linux/fl_basic_message_channel.h"

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_message_codec.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_standard_message_codec.h"
#include "flutter/shell/platform/linux/testing/fl_test.h"
#include "flutter/shell/platform/linux/testing/mock_renderer.h"

// Checks sending a message without a response works.
// MOCK_ENGINE_PROC is leaky by design
// NOLINTBEGIN(clang-analyzer-core.StackAddressEscape)
TEST(FlBasicMessageChannelTest, SendMessageWithoutResponse) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlutterEngineProcTable* embedder_api = fl_engine_get_embedder_api(engine);

  bool called = false;
  FlutterEngineSendPlatformMessageFnPtr old_handler =
      embedder_api->SendPlatformMessage;
  embedder_api->SendPlatformMessage = MOCK_ENGINE_PROC(
      SendPlatformMessage,
      ([&called, old_handler](auto engine,
                              const FlutterPlatformMessage* message) {
        if (strcmp(message->channel, "test") != 0) {
          return old_handler(engine, message);
        }

        called = true;
        EXPECT_EQ(message->response_handle, nullptr);

        g_autoptr(GBytes) message_bytes =
            g_bytes_new(message->message, message->message_size);
        g_autoptr(FlStandardMessageCodec) codec =
            fl_standard_message_codec_new();
        FlValue* message_value = fl_message_codec_decode_message(
            FL_MESSAGE_CODEC(codec), message_bytes, nullptr);
        EXPECT_EQ(fl_value_get_type(message_value), FL_VALUE_TYPE_STRING);
        EXPECT_STREQ(fl_value_get_string(message_value), "Hello World!");

        return kSuccess;
      }));

  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMessageCodec) codec = fl_standard_message_codec_new();
  g_autoptr(FlBasicMessageChannel) channel =
      fl_basic_message_channel_new(messenger, "test", FL_MESSAGE_CODEC(codec));
  g_autoptr(FlValue) message = fl_value_new_string("Hello World!");
  fl_basic_message_channel_send(channel, message, nullptr, nullptr, loop);

  EXPECT_TRUE(called);
}
// NOLINTEND(clang-analyzer-core.StackAddressEscape)

// Called when the message response is received in the SendMessageWithResponse
// test.
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

// Checks sending a message with a response works.
TEST(FlBasicMessageChannelTest, SendMessageWithResponse) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
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
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
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
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);

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

// Called when the message response is received in the
// SendNullMessageWithResponse test.
static void null_message_response_cb(GObject* object,
                                     GAsyncResult* result,
                                     gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlValue) message = fl_basic_message_channel_send_finish(
      FL_BASIC_MESSAGE_CHANNEL(object), result, &error);
  EXPECT_NE(message, nullptr);
  EXPECT_EQ(error, nullptr);

  EXPECT_EQ(fl_value_get_type(message), FL_VALUE_TYPE_NULL);

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks sending a null message with a response works.
TEST(FlBasicMessageChannelTest, SendNullMessageWithResponse) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMessageCodec) codec = fl_standard_message_codec_new();
  g_autoptr(FlBasicMessageChannel) channel = fl_basic_message_channel_new(
      messenger, "test/echo", FL_MESSAGE_CODEC(codec));
  fl_basic_message_channel_send(channel, nullptr, nullptr,
                                null_message_response_cb, loop);

  // Blocks here until null_message_response_cb is called.
  g_main_loop_run(loop);
}

// Called when the message response is received in the CustomType test.
static void custom_type_response_cb(GObject* object,
                                    GAsyncResult* result,
                                    gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlValue) message = fl_basic_message_channel_send_finish(
      FL_BASIC_MESSAGE_CHANNEL(object), result, &error);
  EXPECT_EQ(message, nullptr);
  EXPECT_NE(error, nullptr);
  EXPECT_STREQ(error->message, "Custom value not implemented");

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks sending a message with a custom type generates an error.
TEST(FlBasicMessageChannelTest, CustomType) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  // Attempt to send an integer with the string codec.
  g_autoptr(FlEngine) engine = make_mock_engine();
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMessageCodec) codec = fl_standard_message_codec_new();
  g_autoptr(FlBasicMessageChannel) channel = fl_basic_message_channel_new(
      messenger, "test/echo", FL_MESSAGE_CODEC(codec));
  g_autoptr(FlValue) message = fl_value_new_custom(42, nullptr, nullptr);
  fl_basic_message_channel_send(channel, message, nullptr,
                                custom_type_response_cb, loop);

  // Blocks here until custom_type_response_cb is called.
  g_main_loop_run(loop);
}
