// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Included first as it collides with the X11 headers.
#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_method_codec_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_basic_message_channel.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_event_channel.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_method_channel.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_standard_method_codec.h"
#include "flutter/shell/platform/linux/testing/mock_renderer.h"

// Data passed in tests.
typedef struct {
  GMainLoop* loop;
  int count;
} TestData;

// Creates a mock engine that responds to platform messages.
static FlEngine* make_mock_engine() {
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlMockRenderer) renderer = fl_mock_renderer_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project, FL_RENDERER(renderer));
  g_autoptr(GError) engine_error = nullptr;
  EXPECT_TRUE(fl_engine_start(engine, &engine_error));
  EXPECT_EQ(engine_error, nullptr);

  return static_cast<FlEngine*>(g_object_ref(engine));
}

// Triggers the engine to start listening to the channel.
static void listen_channel(FlBinaryMessenger* messenger, FlValue* args) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      messenger, "test/standard-method", FL_METHOD_CODEC(codec));

  // Trigger the engine to make a method call.
  g_autoptr(FlValue) invoke_args = fl_value_new_list();
  fl_value_append_take(invoke_args, fl_value_new_string("test/standard-event"));
  fl_value_append_take(invoke_args, fl_value_new_string("listen"));
  fl_value_append(invoke_args,
                  args != nullptr ? fl_value_ref(args) : fl_value_new_null());
  fl_method_channel_invoke_method(channel, "InvokeMethod", invoke_args, nullptr,
                                  nullptr, nullptr);
}

// Triggers the engine to cancel the subscription to the channel.
static void cancel_channel(FlBinaryMessenger* messenger, FlValue* args) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      messenger, "test/standard-method", FL_METHOD_CODEC(codec));

  // Trigger the engine to make a method call.
  g_autoptr(FlValue) invoke_args = fl_value_new_list();
  fl_value_append_take(invoke_args, fl_value_new_string("test/standard-event"));
  fl_value_append_take(invoke_args, fl_value_new_string("cancel"));
  fl_value_append_take(
      invoke_args, args != nullptr ? fl_value_ref(args) : fl_value_new_null());
  fl_method_channel_invoke_method(channel, "InvokeMethod", invoke_args, nullptr,
                                  nullptr, nullptr);
}

// Called when when the remote end starts listening on the channel.
static FlMethodErrorResponse* listen_listen_cb(FlEventChannel* channel,
                                               FlValue* args,
                                               gpointer user_data) {
  EXPECT_EQ(fl_value_get_type(args), FL_VALUE_TYPE_NULL);

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));

  return nullptr;
}

// Checks we detect a listen event.
TEST(FlEventChannelTest, Listen) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlEventChannel* channel = fl_event_channel_new(
      messenger, "test/standard-event", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(channel, listen_listen_cb, nullptr, loop,
                                       nullptr);

  listen_channel(messenger, nullptr);

  // Blocks here until listen_listen_cb called.
  g_main_loop_run(loop);

  // Manually unref because the compiler complains 'channel' is unused.
  g_object_unref(channel);
}

// Called when when the remote end starts listening on the channel.
static FlMethodErrorResponse* listen_exception_listen_cb(
    FlEventChannel* channel,
    FlValue* args,
    gpointer user_data) {
  return fl_method_error_response_new("LISTEN-ERROR", "LISTEN-ERROR-MESSAGE",
                                      nullptr);
}

// Called when a the test engine notifies us what response we sent in the
// ListenException test.
static void listen_exception_response_cb(
    FlBinaryMessenger* messenger,
    const gchar* channel,
    GBytes* message,
    FlBinaryMessengerResponseHandle* response_handle,
    gpointer user_data) {
  fl_binary_messenger_send_response(messenger, response_handle, nullptr,
                                    nullptr);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlMethodResponse) response =
      fl_method_codec_decode_response(FL_METHOD_CODEC(codec), message, &error);
  EXPECT_NE(response, nullptr);
  EXPECT_EQ(error, nullptr);

  EXPECT_TRUE(FL_IS_METHOD_ERROR_RESPONSE(response));
  EXPECT_STREQ(
      fl_method_error_response_get_code(FL_METHOD_ERROR_RESPONSE(response)),
      "LISTEN-ERROR");
  EXPECT_STREQ(
      fl_method_error_response_get_message(FL_METHOD_ERROR_RESPONSE(response)),
      "LISTEN-ERROR-MESSAGE");

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks we can generate a listen exception.
TEST(FlEventChannelTest, ListenException) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlEventChannel* channel = fl_event_channel_new(
      messenger, "test/standard-event", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(channel, listen_exception_listen_cb,
                                       nullptr, loop, nullptr);

  // Listen for response to the engine.
  fl_binary_messenger_set_message_handler_on_channel(
      messenger, "test/responses", listen_exception_response_cb, loop, nullptr);

  listen_channel(messenger, nullptr);

  // Blocks here until listen_exception_response_cb called.
  g_main_loop_run(loop);

  // Manually unref because the compiler complains 'channel' is unused.
  g_object_unref(channel);
}

// Called when when the remote end cancels their subscription.
static FlMethodErrorResponse* cancel_cancel_cb(FlEventChannel* channel,
                                               FlValue* args,
                                               gpointer user_data) {
  EXPECT_EQ(fl_value_get_type(args), FL_VALUE_TYPE_NULL);

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));

  return nullptr;
}

// Checks we detect a cancel event.
TEST(FlEventChannelTest, Cancel) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlEventChannel* channel = fl_event_channel_new(
      messenger, "test/standard-event", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(channel, nullptr, cancel_cancel_cb, loop,
                                       nullptr);

  listen_channel(messenger, nullptr);
  cancel_channel(messenger, nullptr);

  // Blocks here until cancel_cancel_cb called.
  g_main_loop_run(loop);

  // Manually unref because the compiler complains 'channel' is unused.
  g_object_unref(channel);
}

// Called when when the remote end cancels their subscription.
static FlMethodErrorResponse* cancel_exception_cancel_cb(
    FlEventChannel* channel,
    FlValue* args,
    gpointer user_data) {
  return fl_method_error_response_new("CANCEL-ERROR", "CANCEL-ERROR-MESSAGE",
                                      nullptr);
}

// Called when a the test engine notifies us what response we sent in the
// CancelException test.
static void cancel_exception_response_cb(
    FlBinaryMessenger* messenger,
    const gchar* channel,
    GBytes* message,
    FlBinaryMessengerResponseHandle* response_handle,
    gpointer user_data) {
  TestData* data = static_cast<TestData*>(user_data);

  fl_binary_messenger_send_response(messenger, response_handle, nullptr,
                                    nullptr);

  data->count++;
  if (data->count == 2) {
    g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
    g_autoptr(GError) error = nullptr;
    g_autoptr(FlMethodResponse) response = fl_method_codec_decode_response(
        FL_METHOD_CODEC(codec), message, &error);
    EXPECT_NE(response, nullptr);
    EXPECT_EQ(error, nullptr);

    EXPECT_TRUE(FL_IS_METHOD_ERROR_RESPONSE(response));
    EXPECT_STREQ(
        fl_method_error_response_get_code(FL_METHOD_ERROR_RESPONSE(response)),
        "CANCEL-ERROR");
    EXPECT_STREQ(fl_method_error_response_get_message(
                     FL_METHOD_ERROR_RESPONSE(response)),
                 "CANCEL-ERROR-MESSAGE");

    g_main_loop_quit(data->loop);
  }
}

// Checks we can generate a cancel exception.
TEST(FlEventChannelTest, CancelException) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);
  TestData data;
  data.loop = loop;
  data.count = 0;

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlEventChannel* channel = fl_event_channel_new(
      messenger, "test/standard-event", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(
      channel, nullptr, cancel_exception_cancel_cb, &data, nullptr);

  // Listen for response to the engine.
  fl_binary_messenger_set_message_handler_on_channel(
      messenger, "test/responses", cancel_exception_response_cb, &data,
      nullptr);

  listen_channel(messenger, nullptr);
  cancel_channel(messenger, nullptr);

  // Blocks here until cancel_exception_response_cb called.
  g_main_loop_run(loop);

  // Manually unref because the compiler complains 'channel' is unused.
  g_object_unref(channel);
}

// Called when when the remote end starts listening on the channel.
static FlMethodErrorResponse* args_listen_cb(FlEventChannel* channel,
                                             FlValue* args,
                                             gpointer user_data) {
  g_autoptr(FlValue) expected_args = fl_value_new_string("LISTEN-ARGS");
  EXPECT_TRUE(fl_value_equal(args, expected_args));

  return nullptr;
}

// Called when when the remote end cancels their subscription.
static FlMethodErrorResponse* args_cancel_cb(FlEventChannel* channel,
                                             FlValue* args,
                                             gpointer user_data) {
  g_autoptr(FlValue) expected_args = fl_value_new_string("CANCEL-ARGS");
  EXPECT_TRUE(fl_value_equal(args, expected_args));

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));

  return nullptr;
}

// Checks args are passed to listen/cancel.
TEST(FlEventChannelTest, Args) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlEventChannel* channel = fl_event_channel_new(
      messenger, "test/standard-event", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(channel, args_listen_cb, args_cancel_cb,
                                       loop, nullptr);

  g_autoptr(FlValue) listen_args = fl_value_new_string("LISTEN-ARGS");
  listen_channel(messenger, listen_args);
  g_autoptr(FlValue) cancel_args = fl_value_new_string("CANCEL-ARGS");
  cancel_channel(messenger, cancel_args);

  // Blocks here until args_cancel_cb called.
  g_main_loop_run(loop);

  // Manually unref because the compiler complains 'channel' is unused.
  g_object_unref(channel);
}

// Called when when the remote end starts listening on the channel.
static FlMethodErrorResponse* send_events_listen_cb(FlEventChannel* channel,
                                                    FlValue* args,
                                                    gpointer user_data) {
  // Send some events.
  for (int i = 0; i < 5; i++) {
    g_autoptr(FlValue) event = fl_value_new_int(i);
    g_autoptr(GError) error = nullptr;
    EXPECT_TRUE(fl_event_channel_send(channel, event, nullptr, &error));
    EXPECT_EQ(error, nullptr);
  }

  return nullptr;
}

// Called when a the test engine notifies us what event we sent in the
// Test test.
static void send_events_events_cb(
    FlBinaryMessenger* messenger,
    const gchar* channel,
    GBytes* message,
    FlBinaryMessengerResponseHandle* response_handle,
    gpointer user_data) {
  TestData* data = static_cast<TestData*>(user_data);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlMethodResponse) response =
      fl_method_codec_decode_response(FL_METHOD_CODEC(codec), message, &error);
  EXPECT_NE(response, nullptr);
  EXPECT_EQ(error, nullptr);

  FlValue* result = fl_method_response_get_result(response, &error);
  EXPECT_NE(result, nullptr);
  EXPECT_EQ(error, nullptr);

  EXPECT_EQ(fl_value_get_type(result), FL_VALUE_TYPE_INT);
  EXPECT_EQ(fl_value_get_int(result), data->count);
  data->count++;

  fl_binary_messenger_send_response(messenger, response_handle, nullptr,
                                    nullptr);

  // Got all the results!
  if (data->count == 5) {
    g_main_loop_quit(data->loop);
  }
}

// Checks can send events.
TEST(FlEventChannelTest, Test) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);
  TestData data;
  data.loop = loop;
  data.count = 0;

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlEventChannel* channel = fl_event_channel_new(
      messenger, "test/standard-event", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(channel, send_events_listen_cb, nullptr,
                                       &data, nullptr);

  // Listen for events from the engine.
  fl_binary_messenger_set_message_handler_on_channel(
      messenger, "test/events", send_events_events_cb, &data, nullptr);

  listen_channel(messenger, nullptr);
  cancel_channel(messenger, nullptr);

  // Blocks here until send_events_events_cb receives the last event.
  g_main_loop_run(loop);

  // Manually unref because the compiler complains 'channel' is unused.
  g_object_unref(channel);
}
