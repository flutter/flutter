// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_basic_message_channel.h"

#include <gmodule.h>

struct _FlBasicMessageChannel {
  GObject parent_instance;

  // Messenger to communicate on
  FlBinaryMessenger* messenger;

  // Channel name
  gchar* name;

  // Codec to en/decode messages
  FlMessageCodec* codec;

  // Function called when a message is received
  FlBasicMessageChannelMessageHandler message_handler;
  gpointer message_handler_data;
};

// Wrap the binary messenger handle for type safety and to make the API
// consistent
struct _FlBasicMessageChannelResponseHandle {
  FlBinaryMessengerResponseHandle* response_handle;
};

static FlBasicMessageChannelResponseHandle* response_handle_new(
    FlBinaryMessengerResponseHandle* response_handle) {
  FlBasicMessageChannelResponseHandle* handle =
      static_cast<FlBasicMessageChannelResponseHandle*>(
          g_malloc0(sizeof(FlBasicMessageChannelResponseHandle)));
  handle->response_handle = response_handle;

  return handle;
}

static void response_handle_free(FlBasicMessageChannelResponseHandle* handle) {
  g_free(handle);
}

G_DEFINE_AUTOPTR_CLEANUP_FUNC(FlBasicMessageChannelResponseHandle,
                              response_handle_free);

// Added here to stop the compiler from optimising this function away
G_MODULE_EXPORT GType fl_basic_message_channel_get_type();

G_DEFINE_TYPE(FlBasicMessageChannel, fl_basic_message_channel, G_TYPE_OBJECT)

// Called when a binary message is received on this channel
static void message_cb(FlBinaryMessenger* messenger,
                       const gchar* channel,
                       GBytes* message,
                       FlBinaryMessengerResponseHandle* response_handle,
                       gpointer user_data) {
  FlBasicMessageChannel* self = FL_BASIC_MESSAGE_CHANNEL(user_data);

  if (self->message_handler == nullptr) {
    fl_binary_messenger_send_response(messenger, response_handle, nullptr,
                                      nullptr);
    return;
  }

  g_autoptr(GError) error = nullptr;
  g_autoptr(FlValue) message_value =
      fl_message_codec_decode_message(self->codec, message, &error);
  if (message_value == nullptr) {
    g_warning("Failed to decode message: %s", error->message);
    fl_binary_messenger_send_response(messenger, response_handle, nullptr,
                                      nullptr);
  }

  self->message_handler(self, message_value,
                        response_handle_new(response_handle),
                        self->message_handler_data);
}

// Called when a response is received to a sent message
static void message_response_cb(GObject* object,
                                GAsyncResult* result,
                                gpointer user_data) {
  GTask* task = G_TASK(user_data);
  g_task_return_pointer(task, result, g_object_unref);
}

static void fl_basic_message_channel_dispose(GObject* object) {
  FlBasicMessageChannel* self = FL_BASIC_MESSAGE_CHANNEL(object);

  if (self->messenger != nullptr)
    fl_binary_messenger_set_message_handler_on_channel(
        self->messenger, self->name, nullptr, nullptr);

  g_clear_object(&self->messenger);
  g_clear_pointer(&self->name, g_free);
  g_clear_object(&self->codec);

  G_OBJECT_CLASS(fl_basic_message_channel_parent_class)->dispose(object);
}

static void fl_basic_message_channel_class_init(
    FlBasicMessageChannelClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_basic_message_channel_dispose;
}

static void fl_basic_message_channel_init(FlBasicMessageChannel* self) {}

G_MODULE_EXPORT FlBasicMessageChannel* fl_basic_message_channel_new(
    FlBinaryMessenger* messenger,
    const gchar* name,
    FlMessageCodec* codec) {
  g_return_val_if_fail(FL_IS_BINARY_MESSENGER(messenger), nullptr);
  g_return_val_if_fail(name != nullptr, nullptr);
  g_return_val_if_fail(FL_IS_MESSAGE_CODEC(codec), nullptr);

  FlBasicMessageChannel* self = FL_BASIC_MESSAGE_CHANNEL(
      g_object_new(fl_basic_message_channel_get_type(), nullptr));

  self->messenger = FL_BINARY_MESSENGER(g_object_ref(messenger));
  self->name = g_strdup(name);
  self->codec = FL_MESSAGE_CODEC(g_object_ref(codec));

  fl_binary_messenger_set_message_handler_on_channel(
      self->messenger, self->name, message_cb, self);

  return self;
}

G_MODULE_EXPORT void fl_basic_message_channel_set_message_handler(
    FlBasicMessageChannel* self,
    FlBasicMessageChannelMessageHandler handler,
    gpointer user_data) {
  g_return_if_fail(FL_IS_BASIC_MESSAGE_CHANNEL(self));

  self->message_handler = handler;
  self->message_handler_data = user_data;
}

G_MODULE_EXPORT gboolean fl_basic_message_channel_respond(
    FlBasicMessageChannel* self,
    FlBasicMessageChannelResponseHandle* response_handle,
    FlValue* message,
    GError** error) {
  g_return_val_if_fail(FL_IS_BASIC_MESSAGE_CHANNEL(self), FALSE);
  g_return_val_if_fail(response_handle != nullptr, FALSE);

  // Take reference to ensure it is freed
  g_autoptr(FlBasicMessageChannelResponseHandle) owned_response_handle =
      response_handle;

  g_autoptr(GBytes) data =
      fl_message_codec_encode_message(self->codec, message, error);
  if (data == nullptr)
    return FALSE;

  return fl_binary_messenger_send_response(
      self->messenger, owned_response_handle->response_handle, data, error);
}

G_MODULE_EXPORT void fl_basic_message_channel_send(FlBasicMessageChannel* self,
                                                   FlValue* message,
                                                   GCancellable* cancellable,
                                                   GAsyncReadyCallback callback,
                                                   gpointer user_data) {
  g_return_if_fail(FL_IS_BASIC_MESSAGE_CHANNEL(self));
  g_return_if_fail(message != nullptr);

  g_autoptr(GTask) task =
      callback != nullptr ? g_task_new(self, cancellable, callback, user_data)
                          : nullptr;

  g_autoptr(GError) error = nullptr;
  g_autoptr(GBytes) data =
      fl_message_codec_encode_message(self->codec, message, &error);
  if (data == nullptr) {
    if (task != nullptr)
      g_task_return_error(task, error);
    return;
  }

  fl_binary_messenger_send_on_channel(
      self->messenger, self->name, data, cancellable,
      callback != nullptr ? message_response_cb : nullptr,
      g_steal_pointer(&task));
}

G_MODULE_EXPORT FlValue* fl_basic_message_channel_send_on_channel_finish(
    FlBasicMessageChannel* self,
    GAsyncResult* result,
    GError** error) {
  g_return_val_if_fail(FL_IS_BASIC_MESSAGE_CHANNEL(self), nullptr);
  g_return_val_if_fail(g_task_is_valid(result, self), nullptr);

  g_autoptr(GTask) task = G_TASK(result);
  GAsyncResult* r = G_ASYNC_RESULT(g_task_propagate_pointer(task, nullptr));

  g_autoptr(GBytes) message =
      fl_binary_messenger_send_on_channel_finish(self->messenger, r, error);
  if (message == nullptr)
    return nullptr;

  return fl_message_codec_decode_message(self->codec, message, error);
}
