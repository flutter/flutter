// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_key_event_plugin.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_basic_message_channel.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_json_message_codec.h"

static constexpr char kChannelName[] = "flutter/keyevent";
static constexpr char kTypeKey[] = "type";
static constexpr char kTypeValueUp[] = "keyup";
static constexpr char kTypeValueDown[] = "keydown";
static constexpr char kKeymapKey[] = "keymap";
static constexpr char kKeyCodeKey[] = "keyCode";
static constexpr char kScanCodeKey[] = "scanCode";
static constexpr char kModifiersKey[] = "modifiers";
static constexpr char kToolkitKey[] = "toolkit";
static constexpr char kUnicodeScalarValuesKey[] = "unicodeScalarValues";

static constexpr char kGtkToolkit[] = "gtk";
static constexpr char kLinuxKeymap[] = "linux";

struct _FlKeyEventPlugin {
  GObject parent_instance;

  FlBasicMessageChannel* channel;
};

G_DEFINE_TYPE(FlKeyEventPlugin, fl_key_event_plugin, G_TYPE_OBJECT)

static void fl_key_event_plugin_dispose(GObject* object) {
  FlKeyEventPlugin* self = FL_KEY_EVENT_PLUGIN(object);

  g_clear_object(&self->channel);

  G_OBJECT_CLASS(fl_key_event_plugin_parent_class)->dispose(object);
}

static void fl_key_event_plugin_class_init(FlKeyEventPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_key_event_plugin_dispose;
}

static void fl_key_event_plugin_init(FlKeyEventPlugin* self) {}

FlKeyEventPlugin* fl_key_event_plugin_new(FlBinaryMessenger* messenger) {
  g_return_val_if_fail(FL_IS_BINARY_MESSENGER(messenger), nullptr);

  FlKeyEventPlugin* self = FL_KEY_EVENT_PLUGIN(
      g_object_new(fl_key_event_plugin_get_type(), nullptr));

  g_autoptr(FlJsonMessageCodec) codec = fl_json_message_codec_new();
  self->channel = fl_basic_message_channel_new(messenger, kChannelName,
                                               FL_MESSAGE_CODEC(codec));

  return self;
}

void fl_key_event_plugin_send_key_event(FlKeyEventPlugin* self,
                                        GdkEventKey* event) {
  g_return_if_fail(FL_IS_KEY_EVENT_PLUGIN(self));
  g_return_if_fail(event != nullptr);

  const gchar* type;
  if (event->type == GDK_KEY_PRESS)
    type = kTypeValueDown;
  else if (event->type == GDK_KEY_RELEASE)
    type = kTypeValueUp;
  else
    return;

  int64_t scan_code = event->hardware_keycode;
  int64_t unicodeScalarValues = gdk_keyval_to_unicode(event->keyval);

  g_autoptr(FlValue) message = fl_value_new_map();
  fl_value_set_string_take(message, kTypeKey, fl_value_new_string(type));
  fl_value_set_string_take(message, kKeymapKey,
                           fl_value_new_string(kLinuxKeymap));
  fl_value_set_string_take(message, kScanCodeKey, fl_value_new_int(scan_code));
  fl_value_set_string_take(message, kToolkitKey,
                           fl_value_new_string(kGtkToolkit));
  fl_value_set_string_take(message, kKeyCodeKey,
                           fl_value_new_int(event->keyval));
  fl_value_set_string_take(message, kModifiersKey,
                           fl_value_new_int(event->state));
  if (unicodeScalarValues != 0) {
    fl_value_set_string_take(message, kUnicodeScalarValuesKey,
                             fl_value_new_int(unicodeScalarValues));
  }

  fl_basic_message_channel_send(self->channel, message, nullptr, nullptr,
                                nullptr);
}
