// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_keyboard_handler.h"

#include "flutter/shell/platform/linux/public/flutter_linux/fl_method_channel.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_standard_method_codec.h"

static constexpr char kChannelName[] = "flutter/keyboard";
static constexpr char kGetKeyboardStateMethod[] = "getKeyboardState";

struct _FlKeyboardHandler {
  GObject parent_instance;

  FlKeyboardManager* keyboard_manager;

  // The channel used by the framework to query the keyboard pressed state.
  FlMethodChannel* channel;
};

G_DEFINE_TYPE(FlKeyboardHandler, fl_keyboard_handler, G_TYPE_OBJECT);

// Returns the keyboard pressed state.
static FlMethodResponse* get_keyboard_state(FlKeyboardHandler* self) {
  g_autoptr(FlValue) result = fl_value_new_map();

  GHashTable* pressing_records =
      fl_keyboard_manager_get_pressed_state(self->keyboard_manager);

  g_hash_table_foreach(
      pressing_records,
      [](gpointer key, gpointer value, gpointer user_data) {
        int64_t physical_key = reinterpret_cast<int64_t>(key);
        int64_t logical_key = reinterpret_cast<int64_t>(value);
        FlValue* fl_value_map = reinterpret_cast<FlValue*>(user_data);

        fl_value_set_take(fl_value_map, fl_value_new_int(physical_key),
                          fl_value_new_int(logical_key));
      },
      result);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

// Called when a method call on flutter/keyboard is received from Flutter.
static void method_call_handler(FlMethodChannel* channel,
                                FlMethodCall* method_call,
                                gpointer user_data) {
  FlKeyboardHandler* self = FL_KEYBOARD_HANDLER(user_data);

  const gchar* method = fl_method_call_get_name(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(method, kGetKeyboardStateMethod) == 0) {
    response = get_keyboard_state(self);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send method call response: %s", error->message);
  }
}

static void fl_keyboard_handler_dispose(GObject* object) {
  FlKeyboardHandler* self = FL_KEYBOARD_HANDLER(object);

  g_clear_object(&self->keyboard_manager);
  g_clear_object(&self->channel);

  G_OBJECT_CLASS(fl_keyboard_handler_parent_class)->dispose(object);
}

static void fl_keyboard_handler_class_init(FlKeyboardHandlerClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_keyboard_handler_dispose;
}

static void fl_keyboard_handler_init(FlKeyboardHandler* self) {}

FlKeyboardHandler* fl_keyboard_handler_new(
    FlBinaryMessenger* messenger,
    FlKeyboardManager* keyboard_manager) {
  FlKeyboardHandler* self = FL_KEYBOARD_HANDLER(
      g_object_new(fl_keyboard_handler_get_type(), nullptr));

  self->keyboard_manager = FL_KEYBOARD_MANAGER(g_object_ref(keyboard_manager));

  // Setup the flutter/keyboard channel.
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel =
      fl_method_channel_new(messenger, kChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_handler,
                                            self, nullptr);
  return self;
}
