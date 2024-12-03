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
#include "flutter/shell/platform/linux/testing/fl_test.h"
#include "flutter/shell/platform/linux/testing/mock_renderer.h"

// Called when the method call response is received in the InvokeMethod
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
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      messenger, "test/standard-method", FL_METHOD_CODEC(codec));

  g_autoptr(FlValue) args = fl_value_new_string("Hello World!");
  fl_method_channel_invoke_method(channel, "Echo", args, nullptr,
                                  method_response_cb, loop);

  // Blocks here until method_response_cb is called.
  g_main_loop_run(loop);
}

// Called when the method call response is received in the
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
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      messenger, "test/standard-method", FL_METHOD_CODEC(codec));

  fl_method_channel_invoke_method(channel, "Echo", nullptr, nullptr,
                                  nullptr_args_response_cb, loop);

  // Blocks here until nullptr_args_response_cb is called.
  g_main_loop_run(loop);
}

// Called when the method call response is received in the
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
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
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

// Called when the method call response is received in the
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
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      messenger, "test/standard-method", FL_METHOD_CODEC(codec));

  fl_method_channel_invoke_method(channel, "NotImplemented", nullptr, nullptr,
                                  not_implemented_response_cb, loop);

  // Blocks here until not_implemented_response_cb is called.
  g_main_loop_run(loop);
}

// Called when the method call response is received in the
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
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
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
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
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
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
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
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
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

// A test method codec that always generates errors on responses.
G_DECLARE_FINAL_TYPE(TestMethodCodec,
                     test_method_codec,
                     TEST,
                     METHOD_CODEC,
                     FlMethodCodec)

struct _TestMethodCodec {
  FlMethodCodec parent_instance;

  FlStandardMethodCodec* wrapped_codec;
};

G_DEFINE_TYPE(TestMethodCodec, test_method_codec, fl_method_codec_get_type())

static void test_method_codec_dispose(GObject* object) {
  TestMethodCodec* self = TEST_METHOD_CODEC(object);

  g_clear_object(&self->wrapped_codec);

  G_OBJECT_CLASS(test_method_codec_parent_class)->dispose(object);
}

// Implements FlMethodCodec::encode_method_call.
static GBytes* test_method_codec_encode_method_call(FlMethodCodec* codec,
                                                    const gchar* name,
                                                    FlValue* args,
                                                    GError** error) {
  EXPECT_TRUE(TEST_IS_METHOD_CODEC(codec));
  TestMethodCodec* self = TEST_METHOD_CODEC(codec);
  return fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(self->wrapped_codec), name, args, error);
}

// Implements FlMethodCodec::decode_method_call.
static gboolean test_method_codec_decode_method_call(FlMethodCodec* codec,
                                                     GBytes* message,
                                                     gchar** name,
                                                     FlValue** args,
                                                     GError** error) {
  EXPECT_TRUE(TEST_IS_METHOD_CODEC(codec));
  TestMethodCodec* self = TEST_METHOD_CODEC(codec);
  return fl_method_codec_decode_method_call(
      FL_METHOD_CODEC(self->wrapped_codec), message, name, args, error);
}

// Implements FlMethodCodec::encode_success_envelope.
static GBytes* test_method_codec_encode_success_envelope(FlMethodCodec* codec,
                                                         FlValue* result,
                                                         GError** error) {
  g_set_error(error, FL_MESSAGE_CODEC_ERROR, FL_MESSAGE_CODEC_ERROR_FAILED,
              "Unsupported type");
  return nullptr;
}

// Implements FlMethodCodec::encode_error_envelope.
static GBytes* test_method_codec_encode_error_envelope(FlMethodCodec* codec,
                                                       const gchar* code,
                                                       const gchar* message,
                                                       FlValue* details,
                                                       GError** error) {
  g_set_error(error, FL_MESSAGE_CODEC_ERROR, FL_MESSAGE_CODEC_ERROR_FAILED,
              "Unsupported type");
  return nullptr;
}

// Implements FlMethodCodec::encode_decode_response.
static FlMethodResponse* test_method_codec_decode_response(FlMethodCodec* codec,
                                                           GBytes* message,
                                                           GError** error) {
  EXPECT_TRUE(TEST_IS_METHOD_CODEC(codec));
  TestMethodCodec* self = TEST_METHOD_CODEC(codec);
  return fl_method_codec_decode_response(FL_METHOD_CODEC(self->wrapped_codec),
                                         message, error);
}

static void test_method_codec_class_init(TestMethodCodecClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = test_method_codec_dispose;
  FL_METHOD_CODEC_CLASS(klass)->encode_method_call =
      test_method_codec_encode_method_call;
  FL_METHOD_CODEC_CLASS(klass)->decode_method_call =
      test_method_codec_decode_method_call;
  FL_METHOD_CODEC_CLASS(klass)->encode_success_envelope =
      test_method_codec_encode_success_envelope;
  FL_METHOD_CODEC_CLASS(klass)->encode_error_envelope =
      test_method_codec_encode_error_envelope;
  FL_METHOD_CODEC_CLASS(klass)->decode_response =
      test_method_codec_decode_response;
}

static void test_method_codec_init(TestMethodCodec* self) {
  self->wrapped_codec = fl_standard_method_codec_new();
}

TestMethodCodec* test_method_codec_new() {
  return TEST_METHOD_CODEC(g_object_new(test_method_codec_get_type(), nullptr));
}

// Called when a method call is received from the engine in the
// ReceiveMethodCallRespondSuccessError test.
static void method_call_success_error_cb(FlMethodChannel* channel,
                                         FlMethodCall* method_call,
                                         gpointer user_data) {
  g_autoptr(FlValue) result = fl_value_new_int(42);
  g_autoptr(GError) response_error = nullptr;
  EXPECT_FALSE(
      fl_method_call_respond_success(method_call, result, &response_error));
  EXPECT_NE(response_error, nullptr);

  // Respond to stop a warning occurring about not responding.
  fl_method_call_respond_not_implemented(method_call, nullptr);

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks error correctly handled if provide an unsupported arg in a method call
// response.
TEST(FlMethodChannelTest, ReceiveMethodCallRespondSuccessError) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  g_autoptr(TestMethodCodec) codec = test_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      messenger, "test/standard-method", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel, method_call_success_error_cb, loop, nullptr);

  // Trigger the engine to make a method call.
  g_autoptr(FlValue) args = fl_value_new_list();
  fl_value_append_take(args, fl_value_new_string("test/standard-method"));
  fl_value_append_take(args, fl_value_new_string("Foo"));
  fl_value_append_take(args, fl_value_new_string("Marco!"));
  fl_method_channel_invoke_method(channel, "InvokeMethod", args, nullptr,
                                  nullptr, loop);

  // Blocks here until method_call_success_error_cb is called.
  g_main_loop_run(loop);
}

// Called when a method call is received from the engine in the
// ReceiveMethodCallRespondErrorError test.
static void method_call_error_error_cb(FlMethodChannel* channel,
                                       FlMethodCall* method_call,
                                       gpointer user_data) {
  g_autoptr(FlValue) details = fl_value_new_int(42);
  g_autoptr(GError) response_error = nullptr;
  EXPECT_FALSE(fl_method_call_respond_error(method_call, "error", "ERROR",
                                            details, &response_error));
  EXPECT_NE(response_error, nullptr);

  // Respond to stop a warning occurring about not responding.
  fl_method_call_respond_not_implemented(method_call, nullptr);

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks error correctly handled if provide an unsupported arg in a method call
// response.
TEST(FlMethodChannelTest, ReceiveMethodCallRespondErrorError) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  g_autoptr(TestMethodCodec) codec = test_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      messenger, "test/standard-method", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_error_error_cb,
                                            loop, nullptr);

  // Trigger the engine to make a method call.
  g_autoptr(FlValue) args = fl_value_new_list();
  fl_value_append_take(args, fl_value_new_string("test/standard-method"));
  fl_value_append_take(args, fl_value_new_string("Foo"));
  fl_value_append_take(args, fl_value_new_string("Marco!"));
  fl_method_channel_invoke_method(channel, "InvokeMethod", args, nullptr,
                                  nullptr, loop);

  // Blocks here until method_call_error_error_cb is called.
  g_main_loop_run(loop);
}

struct UserDataReassignMethod {
  GMainLoop* loop;
  int count;
};

// This callback parses the user data as UserDataReassignMethod,
// increases its `count`, and quits `loop`.
static void reassign_method_cb(FlMethodChannel* channel,
                               FlMethodCall* method_call,
                               gpointer raw_user_data) {
  UserDataReassignMethod* user_data =
      static_cast<UserDataReassignMethod*>(raw_user_data);
  user_data->count += 1;

  g_autoptr(FlValue) result = fl_value_new_string("Polo!");
  g_autoptr(GError) error = nullptr;
  EXPECT_TRUE(fl_method_call_respond_success(method_call, result, &error));
  EXPECT_EQ(error, nullptr);

  g_main_loop_quit(user_data->loop);
}

// Make sure that the following steps will work properly:
//
// 1. Register a method channel.
// 2. Dispose the method channel, and it's unregistered.
// 3. Register a new channel with the same name.
//
// This is a regression test to https://github.com/flutter/flutter/issues/90817.
TEST(FlMethodChannelTest, ReplaceADisposedMethodChannel) {
  const char* method_name = "test/standard-method";
  // The loop is used to pause the main process until the callback is fully
  // executed.
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);
  g_autoptr(FlEngine) engine = make_mock_engine();
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();

  g_autoptr(FlValue) args = fl_value_new_list();
  fl_value_append_take(args, fl_value_new_string(method_name));
  fl_value_append_take(args, fl_value_new_string("FOO"));
  fl_value_append_take(args, fl_value_new_string("BAR"));

  // Register the first channel and test if it works.
  UserDataReassignMethod user_data1{
      .loop = loop,
      .count = 100,
  };
  FlMethodChannel* channel1 =
      fl_method_channel_new(messenger, method_name, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel1, reassign_method_cb,
                                            &user_data1, nullptr);

  fl_method_channel_invoke_method(channel1, "InvokeMethod", args, nullptr,
                                  nullptr, nullptr);
  g_main_loop_run(loop);
  EXPECT_EQ(user_data1.count, 101);

  // Dispose the first channel.
  g_object_unref(channel1);

  // Register the second channel and test if it works.
  UserDataReassignMethod user_data2{
      .loop = loop,
      .count = 100,
  };
  g_autoptr(FlMethodChannel) channel2 =
      fl_method_channel_new(messenger, method_name, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel2, reassign_method_cb,
                                            &user_data2, nullptr);

  fl_method_channel_invoke_method(channel2, "InvokeMethod", args, nullptr,
                                  nullptr, nullptr);
  g_main_loop_run(loop);

  EXPECT_EQ(user_data1.count, 101);
  EXPECT_EQ(user_data2.count, 101);
}

// Make sure that the following steps will work properly:
//
// 1. Register a method channel.
// 2. Register the same name with a new channel.
// 3. Dispose the previous method channel.
//
// This is a regression test to https://github.com/flutter/flutter/issues/90817.
TEST(FlMethodChannelTest, DisposeAReplacedMethodChannel) {
  const char* method_name = "test/standard-method";
  // The loop is used to pause the main process until the callback is fully
  // executed.
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);
  g_autoptr(FlEngine) engine = make_mock_engine();
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();

  g_autoptr(FlValue) args = fl_value_new_list();
  fl_value_append_take(args, fl_value_new_string(method_name));
  fl_value_append_take(args, fl_value_new_string("FOO"));
  fl_value_append_take(args, fl_value_new_string("BAR"));

  // Register the first channel and test if it works.
  UserDataReassignMethod user_data1{
      .loop = loop,
      .count = 100,
  };
  FlMethodChannel* channel1 =
      fl_method_channel_new(messenger, method_name, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel1, reassign_method_cb,
                                            &user_data1, nullptr);

  fl_method_channel_invoke_method(channel1, "InvokeMethod", args, nullptr,
                                  nullptr, nullptr);
  g_main_loop_run(loop);
  EXPECT_EQ(user_data1.count, 101);

  // Register a new channel to the same name.
  UserDataReassignMethod user_data2{
      .loop = loop,
      .count = 100,
  };
  g_autoptr(FlMethodChannel) channel2 =
      fl_method_channel_new(messenger, method_name, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel2, reassign_method_cb,
                                            &user_data2, nullptr);

  fl_method_channel_invoke_method(channel2, "InvokeMethod", args, nullptr,
                                  nullptr, nullptr);
  g_main_loop_run(loop);
  EXPECT_EQ(user_data1.count, 101);
  EXPECT_EQ(user_data2.count, 101);

  // Dispose the first channel. The new channel should keep working.
  g_object_unref(channel1);

  fl_method_channel_invoke_method(channel2, "InvokeMethod", args, nullptr,
                                  nullptr, nullptr);
  g_main_loop_run(loop);
  EXPECT_EQ(user_data1.count, 101);
  EXPECT_EQ(user_data2.count, 102);
}

// Called when the method call response is received in the CustomType
// test.
static void custom_type_response_cb(GObject* object,
                                    GAsyncResult* result,
                                    gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(
      FL_METHOD_CHANNEL(object), result, &error);
  EXPECT_EQ(response, nullptr);
  EXPECT_NE(error, nullptr);
  EXPECT_STREQ(error->message, "Custom value not implemented");

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks invoking a method with a custom type generates an error.
TEST(FlMethodChannelTest, CustomType) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      messenger, "test/standard-method", FL_METHOD_CODEC(codec));

  g_autoptr(FlValue) args = fl_value_new_custom(42, nullptr, nullptr);
  fl_method_channel_invoke_method(channel, "Echo", args, nullptr,
                                  custom_type_response_cb, loop);

  // Blocks here until custom_type_response_cb is called.
  g_main_loop_run(loop);
}
