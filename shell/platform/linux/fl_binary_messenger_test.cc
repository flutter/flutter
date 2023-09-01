// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Included first as it collides with the X11 headers.
#include "gtest/gtest.h"

#include <pthread.h>
#include <cstring>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_method_channel.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_standard_method_codec.h"
#include "flutter/shell/platform/linux/testing/fl_test.h"
#include "flutter/shell/platform/linux/testing/mock_binary_messenger_response_handle.h"
#include "flutter/shell/platform/linux/testing/mock_renderer.h"

G_DECLARE_FINAL_TYPE(FlFakeBinaryMessenger,
                     fl_fake_binary_messenger,
                     FL,
                     FAKE_BINARY_MESSENGER,
                     GObject)

struct _FlFakeBinaryMessenger {
  GObject parent_instance;

  GMainLoop* loop;
  GAsyncReadyCallback send_callback;
  gpointer send_callback_user_data;
  FlBinaryMessengerMessageHandler message_handler;
  gpointer message_handler_user_data;
};

static void fl_fake_binary_messenger_iface_init(
    FlBinaryMessengerInterface* iface);

G_DEFINE_TYPE_WITH_CODE(
    FlFakeBinaryMessenger,
    fl_fake_binary_messenger,
    G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE(fl_binary_messenger_get_type(),
                          fl_fake_binary_messenger_iface_init))

static void fl_fake_binary_messenger_class_init(
    FlFakeBinaryMessengerClass* klass) {}

static gboolean send_message_cb(gpointer user_data) {
  FlFakeBinaryMessenger* self = FL_FAKE_BINARY_MESSENGER(user_data);

  const char* text = "Marco!";
  g_autoptr(GBytes) message = g_bytes_new(text, strlen(text));
  self->message_handler(FL_BINARY_MESSENGER(self), "CHANNEL", message,
                        FL_BINARY_MESSENGER_RESPONSE_HANDLE(
                            fl_mock_binary_messenger_response_handle_new()),
                        self->message_handler_user_data);

  return FALSE;
}

static void set_message_handler_on_channel(
    FlBinaryMessenger* messenger,
    const gchar* channel,
    FlBinaryMessengerMessageHandler handler,
    gpointer user_data,
    GDestroyNotify destroy_notify) {
  FlFakeBinaryMessenger* self = FL_FAKE_BINARY_MESSENGER(messenger);

  EXPECT_STREQ(channel, "CHANNEL");

  // Send message.
  self->message_handler = handler;
  self->message_handler_user_data = user_data;
  g_idle_add(send_message_cb, messenger);
}

static gboolean send_response(FlBinaryMessenger* messenger,
                              FlBinaryMessengerResponseHandle* response_handle,
                              GBytes* response,
                              GError** error) {
  FlFakeBinaryMessenger* self = FL_FAKE_BINARY_MESSENGER(messenger);

  EXPECT_TRUE(FL_IS_MOCK_BINARY_MESSENGER_RESPONSE_HANDLE(response_handle));

  g_autofree gchar* text =
      g_strndup(static_cast<const gchar*>(g_bytes_get_data(response, nullptr)),
                g_bytes_get_size(response));
  EXPECT_STREQ(text, "Polo!");

  g_main_loop_quit(self->loop);

  return TRUE;
}

static gboolean send_ready_cb(gpointer user_data) {
  FlFakeBinaryMessenger* self = FL_FAKE_BINARY_MESSENGER(user_data);

  self->send_callback(G_OBJECT(self), NULL, self->send_callback_user_data);

  return FALSE;
}

static void send_on_channel(FlBinaryMessenger* messenger,
                            const gchar* channel,
                            GBytes* message,
                            GCancellable* cancellable,
                            GAsyncReadyCallback callback,
                            gpointer user_data) {
  FlFakeBinaryMessenger* self = FL_FAKE_BINARY_MESSENGER(messenger);

  EXPECT_STREQ(channel, "CHANNEL");
  g_autofree gchar* text =
      g_strndup(static_cast<const gchar*>(g_bytes_get_data(message, nullptr)),
                g_bytes_get_size(message));
  EXPECT_STREQ(text, "Marco!");

  // Send response.
  self->send_callback = callback;
  self->send_callback_user_data = user_data;
  g_idle_add(send_ready_cb, messenger);
}

static GBytes* send_on_channel_finish(FlBinaryMessenger* messenger,
                                      GAsyncResult* result,
                                      GError** error) {
  const char* text = "Polo!";
  return g_bytes_new(text, strlen(text));
}

static void resize_channel(FlBinaryMessenger* messenger,
                           const gchar* channel,
                           int64_t new_size) {
  // Fake implementation. Do nothing.
}

static void set_allow_channel_overflow(FlBinaryMessenger* messenger,
                                       const gchar* channel,
                                       bool allowed) {
  // Fake implementation. Do nothing.
}

static void fl_fake_binary_messenger_iface_init(
    FlBinaryMessengerInterface* iface) {
  iface->set_message_handler_on_channel = set_message_handler_on_channel;
  iface->send_response = send_response;
  iface->send_on_channel = send_on_channel;
  iface->send_on_channel_finish = send_on_channel_finish;
  iface->resize_channel = resize_channel;
  iface->set_allow_channel_overflow = set_allow_channel_overflow;
}

static void fl_fake_binary_messenger_init(FlFakeBinaryMessenger* self) {}

static FlBinaryMessenger* fl_fake_binary_messenger_new(GMainLoop* loop) {
  FlFakeBinaryMessenger* self = FL_FAKE_BINARY_MESSENGER(
      g_object_new(fl_fake_binary_messenger_get_type(), NULL));
  self->loop = loop;
  return FL_BINARY_MESSENGER(self);
}

// Called when the message response is received in the FakeMessengerSend test.
static void fake_response_cb(GObject* object,
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
  EXPECT_STREQ(text, "Polo!");

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

// Checks can make a fake messenger and send a message.
TEST(FlBinaryMessengerTest, FakeMessengerSend) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlBinaryMessenger) messenger = fl_fake_binary_messenger_new(loop);
  EXPECT_TRUE(FL_IS_FAKE_BINARY_MESSENGER(messenger));

  const char* text = "Marco!";
  g_autoptr(GBytes) message = g_bytes_new(text, strlen(text));
  fl_binary_messenger_send_on_channel(messenger, "CHANNEL", message, nullptr,
                                      fake_response_cb, loop);

  // Blocks here until fake_response_cb is called.
  g_main_loop_run(loop);
}

// Called when a message is received in the FakeMessengerReceive test.
static void fake_message_cb(FlBinaryMessenger* messenger,
                            const gchar* channel,
                            GBytes* message,
                            FlBinaryMessengerResponseHandle* response_handle,
                            gpointer user_data) {
  EXPECT_STREQ(channel, "CHANNEL");

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

// Checks can make a fake messenger and receive a message.
TEST(FlBinaryMessengerTest, FakeMessengerReceive) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlBinaryMessenger) messenger = fl_fake_binary_messenger_new(loop);
  EXPECT_TRUE(FL_IS_FAKE_BINARY_MESSENGER(messenger));

  fl_binary_messenger_set_message_handler_on_channel(
      messenger, "CHANNEL", fake_message_cb, nullptr, nullptr);

  // Blocks here until response is received in fake messenger.
  g_main_loop_run(loop);
}

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

// MOCK_ENGINE_PROC is leaky by design.
// NOLINTBEGIN(clang-analyzer-core.StackAddressEscape)

// Checks if the 'resize' command is sent and is well-formed.
TEST(FlBinaryMessengerTest, ResizeChannel) {
  g_autoptr(FlEngine) engine = make_mock_engine();
  FlutterEngineProcTable* embedder_api = fl_engine_get_embedder_api(engine);

  bool called = false;

  FlutterEngineSendPlatformMessageFnPtr old_handler =
      embedder_api->SendPlatformMessage;
  embedder_api->SendPlatformMessage = MOCK_ENGINE_PROC(
      SendPlatformMessage,
      ([&called, old_handler](auto engine,
                              const FlutterPlatformMessage* message) {
        // Expect to receive a message on the "control" channel.
        if (strcmp(message->channel, "dev.flutter/channel-buffers") != 0) {
          return old_handler(engine, message);
        }

        called = true;

        // The expected content was created from the following Dart code:
        //   MethodCall call = MethodCall('resize', ['flutter/test',3]);
        //   StandardMethodCodec().encodeMethodCall(call).buffer.asUint8List();
        const int expected_message_size = 29;
        EXPECT_EQ(message->message_size,
                  static_cast<size_t>(expected_message_size));
        int expected[expected_message_size] = {
            7,   6,   114, 101, 115, 105, 122, 101, 12,  2,
            7,   12,  102, 108, 117, 116, 116, 101, 114, 47,
            116, 101, 115, 116, 3,   3,   0,   0,   0};
        for (size_t i = 0; i < expected_message_size; i++) {
          EXPECT_EQ(message->message[i], expected[i]);
        }

        return kSuccess;
      }));

  g_autoptr(GError) error = nullptr;
  EXPECT_TRUE(fl_engine_start(engine, &error));
  EXPECT_EQ(error, nullptr);

  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  fl_binary_messenger_resize_channel(messenger, "flutter/test", 3);

  EXPECT_TRUE(called);
}

// Checks if the 'overflow' command is sent and is well-formed.
TEST(FlBinaryMessengerTest, AllowOverflowChannel) {
  g_autoptr(FlEngine) engine = make_mock_engine();
  FlutterEngineProcTable* embedder_api = fl_engine_get_embedder_api(engine);

  bool called = false;

  FlutterEngineSendPlatformMessageFnPtr old_handler =
      embedder_api->SendPlatformMessage;
  embedder_api->SendPlatformMessage = MOCK_ENGINE_PROC(
      SendPlatformMessage,
      ([&called, old_handler](auto engine,
                              const FlutterPlatformMessage* message) {
        // Expect to receive a message on the "control" channel.
        if (strcmp(message->channel, "dev.flutter/channel-buffers") != 0) {
          return old_handler(engine, message);
        }

        called = true;

        // The expected content was created from the following Dart code:
        //   MethodCall call = MethodCall('overflow',['flutter/test', true]);
        //   StandardMethodCodec().encodeMethodCall(call).buffer.asUint8List();
        const int expected_message_size = 27;
        EXPECT_EQ(message->message_size,
                  static_cast<size_t>(expected_message_size));
        int expected[expected_message_size] = {
            7,   8,   111, 118, 101, 114, 102, 108, 111, 119, 12,  2,   7, 12,
            102, 108, 117, 116, 116, 101, 114, 47,  116, 101, 115, 116, 1};
        for (size_t i = 0; i < expected_message_size; i++) {
          EXPECT_EQ(message->message[i], expected[i]);
        }

        return kSuccess;
      }));

  g_autoptr(GError) error = nullptr;
  EXPECT_TRUE(fl_engine_start(engine, &error));
  EXPECT_EQ(error, nullptr);

  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);
  fl_binary_messenger_set_allow_channel_overflow(messenger, "flutter/test",
                                                 true);

  EXPECT_TRUE(called);
}

static gboolean quit_main_loop_cb(gpointer user_data) {
  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
  return FALSE;
}

// Checks if error returned when invoking a command on the control channel
// are handled.
TEST(FlBinaryMessengerTest, ControlChannelErrorResponse) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);
  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);

  g_autoptr(GError) error = nullptr;
  EXPECT_TRUE(fl_engine_start(engine, &error));
  EXPECT_EQ(error, nullptr);

  FlutterEngineProcTable* embedder_api = fl_engine_get_embedder_api(engine);

  bool called = false;

  FlutterEngineSendPlatformMessageFnPtr old_handler =
      embedder_api->SendPlatformMessage;
  embedder_api->SendPlatformMessage = MOCK_ENGINE_PROC(
      SendPlatformMessage,
      ([&called, old_handler, loop](auto engine,
                                    const FlutterPlatformMessage* message) {
        // Expect to receive a message on the "control" channel.
        if (strcmp(message->channel, "dev.flutter/channel-buffers") != 0) {
          return old_handler(engine, message);
        }

        called = true;

        // Register a callback to quit the main loop when binary messenger work
        // ends.
        g_idle_add(quit_main_loop_cb, loop);

        // Simulates an internal error.
        return kInvalidArguments;
      }));

  fl_binary_messenger_set_allow_channel_overflow(messenger, "flutter/test",
                                                 true);

  EXPECT_TRUE(called);

  // Blocks here until quit_main_loop_cb is called.
  g_main_loop_run(loop);
}

// NOLINTEND(clang-analyzer-core.StackAddressEscape)

struct RespondsOnBackgroundThreadInfo {
  FlBinaryMessenger* messenger;
  FlBinaryMessengerResponseHandle* response_handle;
  GMainLoop* loop;
};

static gboolean cleanup_responds_on_background_thread_info(gpointer user_data) {
  RespondsOnBackgroundThreadInfo* info =
      static_cast<RespondsOnBackgroundThreadInfo*>(user_data);
  GMainLoop* loop = info->loop;

  g_object_unref(info->messenger);
  g_object_unref(info->response_handle);
  free(info);

  g_main_loop_quit(static_cast<GMainLoop*>(loop));

  return G_SOURCE_REMOVE;
}

static void* response_from_thread_main(void* user_data) {
  RespondsOnBackgroundThreadInfo* info =
      static_cast<RespondsOnBackgroundThreadInfo*>(user_data);

  fl_binary_messenger_send_response(info->messenger, info->response_handle,
                                    nullptr, nullptr);

  g_idle_add(cleanup_responds_on_background_thread_info, info);

  return nullptr;
}

static void response_from_thread_cb(
    FlBinaryMessenger* messenger,
    const gchar* channel,
    GBytes* message,
    FlBinaryMessengerResponseHandle* response_handle,
    gpointer user_data) {
  EXPECT_NE(message, nullptr);
  pthread_t thread;
  RespondsOnBackgroundThreadInfo* info =
      static_cast<RespondsOnBackgroundThreadInfo*>(
          malloc(sizeof(RespondsOnBackgroundThreadInfo)));
  info->messenger = FL_BINARY_MESSENGER(g_object_ref(messenger));
  info->response_handle =
      FL_BINARY_MESSENGER_RESPONSE_HANDLE(g_object_ref(response_handle));
  info->loop = static_cast<GMainLoop*>(user_data);
  EXPECT_EQ(0,
            pthread_create(&thread, nullptr, &response_from_thread_main, info));
}

TEST(FlBinaryMessengerTest, RespondOnBackgroundThread) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  FlBinaryMessenger* messenger = fl_binary_messenger_new(engine);

  // Listen for messages from the engine.
  fl_binary_messenger_set_message_handler_on_channel(
      messenger, "test/messages", message_cb, nullptr, nullptr);

  // Listen for response from the engine.
  fl_binary_messenger_set_message_handler_on_channel(
      messenger, "test/responses", response_from_thread_cb, loop, nullptr);

  // Trigger the engine to send a message.
  const char* text = "Marco!";
  g_autoptr(GBytes) message = g_bytes_new(text, strlen(text));
  fl_binary_messenger_send_on_channel(messenger, "test/send-message", message,
                                      nullptr, nullptr, nullptr);

  // Blocks here until response_cb is called.
  g_main_loop_run(loop);
}

static void kill_handler_notify_cb(gpointer was_called) {
  *static_cast<gboolean*>(was_called) = TRUE;
}

TEST(FlBinaryMessengerTest, DeletingEngineClearsHandlers) {
  FlEngine* engine = make_mock_engine();
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  gboolean was_killed = FALSE;

  // Listen for messages from the engine.
  fl_binary_messenger_set_message_handler_on_channel(messenger, "test/messages",
                                                     message_cb, &was_killed,
                                                     kill_handler_notify_cb);

  g_clear_object(&engine);

  ASSERT_TRUE(was_killed);
}
