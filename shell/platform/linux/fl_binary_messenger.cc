// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"
#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"

#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"

#include <gmodule.h>

struct _FlBinaryMessenger {
  GObject parent_instance;

  FlEngine* engine;

  // PlatformMessageHandler keyed by channel name
  GHashTable* platform_message_handlers;
};

G_DEFINE_TYPE(FlBinaryMessenger, fl_binary_messenger, G_TYPE_OBJECT)

typedef struct {
  FlBinaryMessengerCallback callback;
  gpointer user_data;
} PlatformMessageHandler;

PlatformMessageHandler* platform_message_handler_new(
    FlBinaryMessengerCallback callback,
    gpointer user_data) {
  PlatformMessageHandler* handler = static_cast<PlatformMessageHandler*>(
      g_malloc0(sizeof(PlatformMessageHandler)));
  handler->callback = callback;
  handler->user_data = user_data;
  return handler;
}

void platform_message_handler_free(gpointer data) {
  PlatformMessageHandler* handler = static_cast<PlatformMessageHandler*>(data);
  g_free(handler);
}

struct _FlBinaryMessengerResponseHandle {
  const FlutterPlatformMessageResponseHandle* response_handle;
};

static void engine_weak_notify_cb(gpointer user_data, GObject* object) {
  FlBinaryMessenger* self = FL_BINARY_MESSENGER(user_data);
  self->engine = nullptr;
}

static FlBinaryMessengerResponseHandle* response_handle_new(
    const FlutterPlatformMessageResponseHandle* response_handle) {
  FlBinaryMessengerResponseHandle* handle =
      static_cast<FlBinaryMessengerResponseHandle*>(
          g_malloc0(sizeof(FlBinaryMessengerResponseHandle)));
  handle->response_handle = response_handle;

  return handle;
}

static void response_handle_free(FlBinaryMessengerResponseHandle* handle) {
  g_free(handle);
}

static gboolean fl_binary_messenger_platform_message_callback(
    FlEngine* engine,
    const gchar* channel,
    GBytes* message,
    const FlutterPlatformMessageResponseHandle* response_handle,
    void* user_data) {
  FlBinaryMessenger* self = FL_BINARY_MESSENGER(user_data);

  FlBinaryMessengerResponseHandle* handle =
      response_handle_new(response_handle);

  PlatformMessageHandler* handler = static_cast<PlatformMessageHandler*>(
      g_hash_table_lookup(self->platform_message_handlers, channel));
  if (handler == nullptr)
    return FALSE;

  handler->callback(self, channel, message, handle, handler->user_data);

  return TRUE;
}

static void fl_binary_messenger_dispose(GObject* object) {
  FlBinaryMessenger* self = FL_BINARY_MESSENGER(object);

  if (self->engine != nullptr) {
    g_object_weak_unref(G_OBJECT(self->engine), engine_weak_notify_cb, self);
    self->engine = nullptr;
  }

  g_clear_pointer(&self->platform_message_handlers, g_hash_table_unref);

  G_OBJECT_CLASS(fl_binary_messenger_parent_class)->dispose(object);
}

static void fl_binary_messenger_class_init(FlBinaryMessengerClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_binary_messenger_dispose;
}

static void fl_binary_messenger_init(FlBinaryMessenger* self) {
  self->platform_message_handlers = g_hash_table_new_full(
      g_str_hash, g_str_equal, g_free, platform_message_handler_free);
}

FlBinaryMessenger* fl_binary_messenger_new(FlEngine* engine) {
  g_return_val_if_fail(FL_IS_ENGINE(engine), nullptr);

  FlBinaryMessenger* self = FL_BINARY_MESSENGER(
      g_object_new(fl_binary_messenger_get_type(), nullptr));

  self->engine = engine;
  g_object_weak_ref(G_OBJECT(engine), engine_weak_notify_cb, self);

  fl_engine_set_platform_message_handler(
      engine, fl_binary_messenger_platform_message_callback, self);

  return self;
}

G_MODULE_EXPORT void fl_binary_messenger_set_message_handler_on_channel(
    FlBinaryMessenger* self,
    const gchar* channel,
    FlBinaryMessengerCallback callback,
    gpointer user_data) {
  g_return_if_fail(FL_IS_BINARY_MESSENGER(self));
  g_return_if_fail(channel != nullptr);
  g_return_if_fail(callback != nullptr);

  PlatformMessageHandler* handler =
      platform_message_handler_new(callback, user_data);
  g_hash_table_replace(self->platform_message_handlers, g_strdup(channel),
                       handler);
}

G_MODULE_EXPORT gboolean fl_binary_messenger_send_response(
    FlBinaryMessenger* self,
    FlBinaryMessengerResponseHandle* response_handle,
    GBytes* response,
    GError** error) {
  g_return_val_if_fail(FL_IS_BINARY_MESSENGER(self), FALSE);
  g_return_val_if_fail(response_handle != nullptr, FALSE);

  if (self->engine == nullptr)
    return TRUE;

  gboolean result = fl_engine_send_platform_message_response(
      self->engine, response_handle->response_handle, response, error);
  response_handle_free(response_handle);

  return result;
}

static void platform_message_ready_cb(GObject* object,
                                      GAsyncResult* result,
                                      gpointer user_data) {
  GTask* task = G_TASK(user_data);
  g_task_return_pointer(task, result, g_object_unref);
}

G_MODULE_EXPORT void fl_binary_messenger_send_on_channel(
    FlBinaryMessenger* self,
    const gchar* channel,
    GBytes* message,
    GCancellable* cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data) {
  g_return_if_fail(FL_IS_BINARY_MESSENGER(self));
  g_return_if_fail(channel != nullptr);

  if (self->engine == nullptr)
    return;

  fl_engine_send_platform_message(
      self->engine, channel, message, cancellable,
      callback != nullptr ? platform_message_ready_cb : nullptr,
      callback != nullptr ? g_task_new(self, cancellable, callback, user_data)
                          : nullptr);
}

G_MODULE_EXPORT GBytes* fl_binary_messenger_send_on_channel_finish(
    FlBinaryMessenger* self,
    GAsyncResult* result,
    GError** error) {
  g_return_val_if_fail(FL_IS_BINARY_MESSENGER(self), FALSE);
  g_return_val_if_fail(g_task_is_valid(result, self), FALSE);

  g_autoptr(GTask) task = G_TASK(result);
  GAsyncResult* r = G_ASYNC_RESULT(g_task_propagate_pointer(task, nullptr));

  if (self->engine == nullptr)
    return nullptr;

  return fl_engine_send_platform_message_finish(self->engine, r, error);
}
