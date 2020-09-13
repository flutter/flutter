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

  FlBasicMessageChannel* channel = nullptr;
  GAsyncReadyCallback response_callback = nullptr;
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

FlKeyEventPlugin* fl_key_event_plugin_new(FlBinaryMessenger* messenger,
                                          GAsyncReadyCallback response_callback,
                                          const char* channel_name) {
  g_return_val_if_fail(FL_IS_BINARY_MESSENGER(messenger), nullptr);

  FlKeyEventPlugin* self = FL_KEY_EVENT_PLUGIN(
      g_object_new(fl_key_event_plugin_get_type(), nullptr));

  g_autoptr(FlJsonMessageCodec) codec = fl_json_message_codec_new();
  self->channel = fl_basic_message_channel_new(
      messenger, channel_name == nullptr ? kChannelName : channel_name,
      FL_MESSAGE_CODEC(codec));
  self->response_callback = response_callback;

  return self;
}

void fl_key_event_plugin_send_key_event(FlKeyEventPlugin* self,
                                        GdkEventKey* event,
                                        gpointer user_data) {
  g_return_if_fail(FL_IS_KEY_EVENT_PLUGIN(self));
  g_return_if_fail(event != nullptr);

  const gchar* type;
  switch (event->type) {
    case GDK_KEY_PRESS:
      type = kTypeValueDown;
      break;
    case GDK_KEY_RELEASE:
      type = kTypeValueUp;
      break;
    default:
      return;
  }

  int64_t scan_code = event->hardware_keycode;
  int64_t unicodeScalarValues = gdk_keyval_to_unicode(event->keyval);

  // For most modifier keys, GTK keeps track of the "pressed" state of the
  // modifier keys. Flutter uses this information to keep modifier keys from
  // being "stuck" when a key-up event is lost because it happens after the app
  // loses focus.
  //
  // For Lock keys (ShiftLock, CapsLock, NumLock), however, GTK keeps track of
  // the state of the locks themselves, not the "pressed" state of the key.
  //
  // Since Flutter expects the "pressed" state of the modifier keys, the lock
  // state for these keys is discarded here, and it is substituted for the
  // pressed state of the key.
  //
  // This code has the flaw that if a key event is missed due to the app losing
  // focus, then this state will still think the key is pressed when it isn't,
  // but that is no worse than for "regular" keys until we implement the
  // sync/cancel events on app focus changes.
  //
  // This is necessary to do here instead of in the framework because Flutter
  // does modifier key syncing in the framework, and will turn on/off these keys
  // as being "pressed" whenever the lock is on, which breaks a lot of
  // interactions (for example, if shift-lock is on, tab traversal is broken).
  //
  // TODO(gspencergoog): get rid of this tracked state when we are tracking the
  // state of all keys and sending sync/cancel events when focus is gained/lost.

  // Remove lock states from state mask.
  guint state = event->state & ~(GDK_LOCK_MASK | GDK_MOD2_MASK);

  static bool shift_lock_pressed = false;
  static bool caps_lock_pressed = false;
  static bool num_lock_pressed = false;
  switch (event->keyval) {
    case GDK_KEY_Num_Lock:
      num_lock_pressed = event->type == GDK_KEY_PRESS;
      break;
    case GDK_KEY_Caps_Lock:
      caps_lock_pressed = event->type == GDK_KEY_PRESS;
      break;
    case GDK_KEY_Shift_Lock:
      shift_lock_pressed = event->type == GDK_KEY_PRESS;
      break;
  }

  // Add back in the state matching the actual pressed state of the lock keys,
  // not the lock states.
  state |= (shift_lock_pressed || caps_lock_pressed) ? GDK_LOCK_MASK : 0x0;
  state |= num_lock_pressed ? GDK_MOD2_MASK : 0x0;

  g_autoptr(FlValue) message = fl_value_new_map();
  fl_value_set_string_take(message, kTypeKey, fl_value_new_string(type));
  fl_value_set_string_take(message, kKeymapKey,
                           fl_value_new_string(kLinuxKeymap));
  fl_value_set_string_take(message, kScanCodeKey, fl_value_new_int(scan_code));
  fl_value_set_string_take(message, kToolkitKey,
                           fl_value_new_string(kGtkToolkit));
  fl_value_set_string_take(message, kKeyCodeKey,
                           fl_value_new_int(event->keyval));
  fl_value_set_string_take(message, kModifiersKey, fl_value_new_int(state));
  if (unicodeScalarValues != 0) {
    fl_value_set_string_take(message, kUnicodeScalarValuesKey,
                             fl_value_new_int(unicodeScalarValues));
  }

  fl_basic_message_channel_send(self->channel, message, nullptr,
                                self->response_callback, user_data);
}
