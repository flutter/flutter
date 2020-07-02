// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Included first as it collides with the X11 headers.
#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_method_codec_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_basic_message_channel.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_method_channel.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_standard_method_codec.h"
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

// Called when when the method call response is received in the InvokeMethod
// test.
static void method_response_cb(GObject* object,
                               GAsyncResult* result,
                               gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(
      FL_METHOD_CHANNEL(object), result, &error);
  EXPECT_NE(response, nullptr);
  EXPECT_EQ(error, nullptr);

  FlValue* r = fl_method_response_get_result(response, &error);
  EXPECT_NE(r, nullptr);
  EXPECT_EQ(error, nullptr);

  EXPECT_EQ(fl_value_get_type(r), FL_VALUE_TYPE_STRING);
  EXPECT_STREQ(fl_value_get_string(r), "Hello World!");

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks if invoking a method returns a value.
TEST(FlMethodChannelTest, InvokeMethod) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      messenger, "test/standard-method", FL_METHOD_CODEC(codec));

  g_autoptr(FlValue) args = fl_value_new_string("Hello World!");
  fl_method_channel_invoke_method(channel, "Echo", args, nullptr,
                                  method_response_cb, loop);

  // Blocks here until method_response_cb is called.
  g_main_loop_run(loop);
}

// Called when when the method call response is received in the
// InvokeMethodNullptrArgsMessage test.
static void nullptr_args_response_cb(GObject* object,
                                     GAsyncResult* result,
                                     gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(
      FL_METHOD_CHANNEL(object), result, &error);
  EXPECT_NE(response, nullptr);
  EXPECT_EQ(error, nullptr);

  FlValue* r = fl_method_response_get_result(response, &error);
  EXPECT_NE(r, nullptr);
  EXPECT_EQ(error, nullptr);
  EXPECT_EQ(fl_value_get_type(r), FL_VALUE_TYPE_NULL);

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks if a method can be invoked with nullptr for arguments.
TEST(FlMethodChannelTest, InvokeMethodNullptrArgsMessage) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      messenger, "test/standard-method", FL_METHOD_CODEC(codec));

  fl_method_channel_invoke_method(channel, "Echo", nullptr, nullptr,
                                  nullptr_args_response_cb, loop);

  // Blocks here until nullptr_args_response_cb is called.
  g_main_loop_run(loop);
}

// Called when when the method call response is received in the
// InvokeMethodError test.
static void error_response_cb(GObject* object,
                              GAsyncResult* result,
                              gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(
      FL_METHOD_CHANNEL(object), result, &error);
  EXPECT_NE(response, nullptr);
  EXPECT_EQ(error, nullptr);

  EXPECT_TRUE(FL_IS_METHOD_ERROR_RESPONSE(response));
  EXPECT_STREQ(
      fl_method_error_response_get_code(FL_METHOD_ERROR_RESPONSE(response)),
      "CODE");
  EXPECT_STREQ(
      fl_method_error_response_get_message(FL_METHOD_ERROR_RESPONSE(response)),
      "MESSAGE");
  FlValue* details =
      fl_method_error_response_get_details(FL_METHOD_ERROR_RESPONSE(response));
  EXPECT_NE(details, nullptr);
  EXPECT_EQ(fl_value_get_type(details), FL_VALUE_TYPE_STRING);
  EXPECT_STREQ(fl_value_get_string(details), "DETAILS");

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks if an error response from a method call is handled.
TEST(FlMethodChannelTest, InvokeMethodError) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      messenger, "test/standard-method", FL_METHOD_CODEC(codec));

  g_autoptr(FlValue) args = fl_value_new_list();
  fl_value_append_take(args, fl_value_new_string("CODE"));
  fl_value_append_take(args, fl_value_new_string("MESSAGE"));
  fl_value_append_take(args, fl_value_new_string("DETAILS"));
  fl_method_channel_invoke_method(channel, "Error", args, nullptr,
                                  error_response_cb, loop);

  // Blocks here until error_response_cb is called.
  g_main_loop_run(loop);
}

// Called when when the method call response is received in the
// InvokeMethodNotImplemented test.
static void not_implemented_response_cb(GObject* object,
                                        GAsyncResult* result,
                                        gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(
      FL_METHOD_CHANNEL(object), result, &error);
  EXPECT_NE(response, nullptr);
  EXPECT_EQ(error, nullptr);

  EXPECT_TRUE(FL_IS_METHOD_NOT_IMPLEMENTED_RESPONSE(response));

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks if a not implemeneted response from a method call is handled.
TEST(FlMethodChannelTest, InvokeMethodNotImplemented) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      messenger, "test/standard-method", FL_METHOD_CODEC(codec));

  fl_method_channel_invoke_method(channel, "NotImplemented", nullptr, nullptr,
                                  not_implemented_response_cb, loop);

  // Blocks here until not_implemented_response_cb is called.
  g_main_loop_run(loop);
}

// Called when when the method call response is received in the
// InvokeMethodFailure test.
static void failure_response_cb(GObject* object,
                                GAsyncResult* result,
                                gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(
      FL_METHOD_CHANNEL(object), result, &error);
  EXPECT_EQ(response, nullptr);
  EXPECT_NE(error, nullptr);

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks if an engine failure calling a method call is handled.
TEST(FlMethodChannelTest, InvokeMethodFailure) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(messenger, "test/failure", FL_METHOD_CODEC(codec));

  fl_method_channel_invoke_method(channel, "Echo", nullptr, nullptr,
                                  failure_response_cb, loop);

  // Blocks here until failure_response_cb is called.
  g_main_loop_run(loop);
}

// Called when a method call is received from the engine in the
// ReceiveMethodCallRespondSuccess test.
static void method_call_success_cb(FlMethodChannel* channel,
                                   FlMethodCall* method_call,
                                   gpointer user_data) {
  EXPECT_STREQ(fl_method_call_get_name(method_call), "Foo");
  EXPECT_EQ(fl_value_get_type(fl_method_call_get_args(method_call)),
            FL_VALUE_TYPE_STRING);
  EXPECT_STREQ(fl_value_get_string(fl_method_call_get_args(method_call)),
               "Marco!");

  g_autoptr(FlValue) result = fl_value_new_string("Polo!");
  g_autoptr(GError) error = nullptr;
  EXPECT_TRUE(fl_method_call_respond_success(method_call, result, &error));
  EXPECT_EQ(error, nullptr);
}

// Called when a the test engine notifies us what response we sent in the
// ReceiveMethodCallRespondSuccess test.
static void method_call_success_response_cb(
    FlBinaryMessenger* messenger,
    const gchar* channel,
    GBytes* message,
    FlBinaryMessengerResponseHandle* response_handle,
    gpointer user_data) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlMethodResponse) response =
      fl_method_codec_decode_response(FL_METHOD_CODEC(codec), message, &error);
  EXPECT_NE(response, nullptr);
  EXPECT_EQ(error, nullptr);

  EXPECT_TRUE(FL_IS_METHOD_SUCCESS_RESPONSE(response));
  FlValue* result = fl_method_success_response_get_result(
      FL_METHOD_SUCCESS_RESPONSE(response));
  EXPECT_EQ(fl_value_get_type(result), FL_VALUE_TYPE_STRING);
  EXPECT_STREQ(fl_value_get_string(result), "Polo!");

  fl_binary_messenger_send_response(messenger, response_handle, nullptr,
                                    nullptr);

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks the shell able to receive and respond to method calls from the engine.
TEST(FlMethodChannelTest, ReceiveMethodCallRespondSuccess) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      messenger, "test/standard-method", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_success_cb,
                                            nullptr, nullptr);

  // Listen for response from the engine.
  fl_binary_messenger_set_message_handler_on_channel(
      messenger, "test/responses", method_call_success_response_cb, loop,
      nullptr);

  // Trigger the engine to make a method call.
  g_autoptr(FlValue) args = fl_value_new_list();
  fl_value_append_take(args, fl_value_new_string("test/standard-method"));
  fl_value_append_take(args, fl_value_new_string("Foo"));
  fl_value_append_take(args, fl_value_new_string("Marco!"));
  fl_method_channel_invoke_method(channel, "InvokeMethod", args, nullptr,
                                  nullptr, loop);

  // Blocks here until method_call_success_response_cb is called.
  g_main_loop_run(loop);
}

// Called when a method call is received from the engine in the
// ReceiveMethodCallRespondError test.
static void method_call_error_cb(FlMethodChannel* channel,
                                 FlMethodCall* method_call,
                                 gpointer user_data) {
  EXPECT_STREQ(fl_method_call_get_name(method_call), "Foo");
  EXPECT_EQ(fl_value_get_type(fl_method_call_get_args(method_call)),
            FL_VALUE_TYPE_STRING);
  EXPECT_STREQ(fl_value_get_string(fl_method_call_get_args(method_call)),
               "Marco!");

  g_autoptr(FlValue) details = fl_value_new_string("DETAILS");
  g_autoptr(GError) error = nullptr;
  EXPECT_TRUE(fl_method_call_respond_error(method_call, "CODE", "MESSAGE",
                                           details, &error));
  EXPECT_EQ(error, nullptr);
}

// Called when a the test engine notifies us what response we sent in the
// ReceiveMethodCallRespondError test.
static void method_call_error_response_cb(
    FlBinaryMessenger* messenger,
    const gchar* channel,
    GBytes* message,
    FlBinaryMessengerResponseHandle* response_handle,
    gpointer user_data) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlMethodResponse) response =
      fl_method_codec_decode_response(FL_METHOD_CODEC(codec), message, &error);
  EXPECT_NE(response, nullptr);
  EXPECT_EQ(error, nullptr);

  EXPECT_TRUE(FL_IS_METHOD_ERROR_RESPONSE(response));
  EXPECT_STREQ(
      fl_method_error_response_get_code(FL_METHOD_ERROR_RESPONSE(response)),
      "CODE");
  EXPECT_STREQ(
      fl_method_error_response_get_message(FL_METHOD_ERROR_RESPONSE(response)),
      "MESSAGE");
  FlValue* details =
      fl_method_error_response_get_details(FL_METHOD_ERROR_RESPONSE(response));
  EXPECT_EQ(fl_value_get_type(details), FL_VALUE_TYPE_STRING);
  EXPECT_STREQ(fl_value_get_string(details), "DETAILS");

  fl_binary_messenger_send_response(messenger, response_handle, nullptr,
                                    nullptr);

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks the shell able to receive and respond to method calls from the engine.
TEST(FlMethodChannelTest, ReceiveMethodCallRespondError) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      messenger, "test/standard-method", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_error_cb,
                                            nullptr, nullptr);

  // Listen for response from the engine.
  fl_binary_messenger_set_message_handler_on_channel(
      messenger, "test/responses", method_call_error_response_cb, loop,
      nullptr);

  // Trigger the engine to make a method call.
  g_autoptr(FlValue) args = fl_value_new_list();
  fl_value_append_take(args, fl_value_new_string("test/standard-method"));
  fl_value_append_take(args, fl_value_new_string("Foo"));
  fl_value_append_take(args, fl_value_new_string("Marco!"));
  fl_method_channel_invoke_method(channel, "InvokeMethod", args, nullptr,
                                  nullptr, loop);

  // Blocks here until method_call_error_response_cb is called.
  g_main_loop_run(loop);
}

// Called when a method call is received from the engine in the
// ReceiveMethodCallRespondNotImplemented test.
static void method_call_not_implemented_cb(FlMethodChannel* channel,
                                           FlMethodCall* method_call,
                                           gpointer user_data) {
  EXPECT_STREQ(fl_method_call_get_name(method_call), "Foo");
  EXPECT_EQ(fl_value_get_type(fl_method_call_get_args(method_call)),
            FL_VALUE_TYPE_STRING);
  EXPECT_STREQ(fl_value_get_string(fl_method_call_get_args(method_call)),
               "Marco!");

  g_autoptr(GError) error = nullptr;
  EXPECT_TRUE(fl_method_call_respond_not_implemented(method_call, &error));
  EXPECT_EQ(error, nullptr);
}

// Called when a the test engine notifies us what response we sent in the
// ReceiveMethodCallRespondNotImplemented test.
static void method_call_not_implemented_response_cb(
    FlBinaryMessenger* messenger,
    const gchar* channel,
    GBytes* message,
    FlBinaryMessengerResponseHandle* response_handle,
    gpointer user_data) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlMethodResponse) response =
      fl_method_codec_decode_response(FL_METHOD_CODEC(codec), message, &error);
  EXPECT_NE(response, nullptr);
  EXPECT_EQ(error, nullptr);

  EXPECT_TRUE(FL_IS_METHOD_NOT_IMPLEMENTED_RESPONSE(response));

  fl_binary_messenger_send_response(messenger, response_handle, nullptr,
                                    nullptr);

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks the shell able to receive and respond to method calls from the engine.
TEST(FlMethodChannelTest, ReceiveMethodCallRespondNotImplemented) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      messenger, "test/standard-method", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel, method_call_not_implemented_cb, nullptr, nullptr);

  // Listen for response from the engine.
  fl_binary_messenger_set_message_handler_on_channel(
      messenger, "test/responses", method_call_not_implemented_response_cb,
      loop, nullptr);

  // Trigger the engine to make a method call.
  g_autoptr(FlValue) args = fl_value_new_list();
  fl_value_append_take(args, fl_value_new_string("test/standard-method"));
  fl_value_append_take(args, fl_value_new_string("Foo"));
  fl_value_append_take(args, fl_value_new_string("Marco!"));
  fl_method_channel_invoke_method(channel, "InvokeMethod", args, nullptr,
                                  nullptr, loop);

  // Blocks here until method_call_not_implemented_response_cb is called.
  g_main_loop_run(loop);
}
