// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_key_channel_responder.h"

#include <gtk/gtk.h>
#include <cinttypes>

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
static constexpr char kSpecifiedLogicalKey[] = "specifiedLogicalKey";
static constexpr char kUnicodeScalarValuesKey[] = "unicodeScalarValues";

static constexpr char kGtkToolkit[] = "gtk";
static constexpr char kLinuxKeymap[] = "linux";

/* Declare and define FlKeyChannelUserData */

/**
 * FlKeyChannelUserData:
 * The user_data used when #FlKeyChannelResponder sends message through the
 * channel.
 */
G_DECLARE_FINAL_TYPE(FlKeyChannelUserData,
                     fl_key_channel_user_data,
                     FL,
                     KEY_CHANNEL_USER_DATA,
                     GObject);

struct _FlKeyChannelUserData {
  GObject parent_instance;

  // The current responder.
  GWeakRef responder;
  // The callback provided by the caller #FlKeyboardHandler.
  FlKeyChannelResponderAsyncCallback callback;
  // The user_data provided by the caller #FlKeyboardHandler.
  gpointer user_data;
};

// Definition for FlKeyChannelUserData private class.
G_DEFINE_TYPE(FlKeyChannelUserData, fl_key_channel_user_data, G_TYPE_OBJECT)

// Dispose method for FlKeyChannelUserData private class.
static void fl_key_channel_user_data_dispose(GObject* object) {
  g_return_if_fail(FL_IS_KEY_CHANNEL_USER_DATA(object));
  FlKeyChannelUserData* self = FL_KEY_CHANNEL_USER_DATA(object);

  g_weak_ref_clear(&self->responder);

  G_OBJECT_CLASS(fl_key_channel_user_data_parent_class)->dispose(object);
}

// Class initialization method for FlKeyChannelUserData private class.
static void fl_key_channel_user_data_class_init(
    FlKeyChannelUserDataClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_key_channel_user_data_dispose;
}

// Instance initialization method for FlKeyChannelUserData private class.
static void fl_key_channel_user_data_init(FlKeyChannelUserData* self) {}

// Creates a new FlKeyChannelUserData private class with all information.
//
// The callback and the user_data might be nullptr.
static FlKeyChannelUserData* fl_key_channel_user_data_new(
    FlKeyChannelResponder* responder,
    FlKeyChannelResponderAsyncCallback callback,
    gpointer user_data) {
  FlKeyChannelUserData* self = FL_KEY_CHANNEL_USER_DATA(
      g_object_new(fl_key_channel_user_data_get_type(), nullptr));

  g_weak_ref_init(&self->responder, responder);
  self->callback = callback;
  self->user_data = user_data;
  return self;
}

/* Define FlKeyChannelResponder */

// Definition of the FlKeyChannelResponder GObject class.
struct _FlKeyChannelResponder {
  GObject parent_instance;

  FlBasicMessageChannel* channel;
};

G_DEFINE_TYPE(FlKeyChannelResponder, fl_key_channel_responder, G_TYPE_OBJECT)

// Handles a response from the method channel to a key event sent to the
// framework earlier.
static void handle_response(GObject* object,
                            GAsyncResult* result,
                            gpointer user_data) {
  g_autoptr(FlKeyChannelUserData) data = FL_KEY_CHANNEL_USER_DATA(user_data);

  g_autoptr(FlKeyChannelResponder) self =
      FL_KEY_CHANNEL_RESPONDER(g_weak_ref_get(&data->responder));
  if (self == nullptr) {
    return;
  }

  g_autoptr(GError) error = nullptr;
  FlBasicMessageChannel* messageChannel = FL_BASIC_MESSAGE_CHANNEL(object);
  FlValue* message =
      fl_basic_message_channel_send_finish(messageChannel, result, &error);
  bool handled = false;
  if (error != nullptr) {
    g_warning("Unable to retrieve framework response: %s", error->message);
  } else {
    g_autoptr(FlValue) handled_value =
        fl_value_lookup_string(message, "handled");
    handled = fl_value_get_bool(handled_value);
  }

  data->callback(handled, data->user_data);
}

// Disposes of an FlKeyChannelResponder instance.
static void fl_key_channel_responder_dispose(GObject* object) {
  FlKeyChannelResponder* self = FL_KEY_CHANNEL_RESPONDER(object);

  g_clear_object(&self->channel);

  G_OBJECT_CLASS(fl_key_channel_responder_parent_class)->dispose(object);
}

// Initializes the FlKeyChannelResponder class methods.
static void fl_key_channel_responder_class_init(
    FlKeyChannelResponderClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_key_channel_responder_dispose;
}

// Initializes an FlKeyChannelResponder instance.
static void fl_key_channel_responder_init(FlKeyChannelResponder* self) {}

// Creates a new FlKeyChannelResponder instance, with a messenger used to send
// messages to the framework, and an FlTextInputHandler that is used to handle
// key events that the framework doesn't handle.
FlKeyChannelResponder* fl_key_channel_responder_new(
    FlBinaryMessenger* messenger) {
  g_return_val_if_fail(FL_IS_BINARY_MESSENGER(messenger), nullptr);

  FlKeyChannelResponder* self = FL_KEY_CHANNEL_RESPONDER(
      g_object_new(fl_key_channel_responder_get_type(), nullptr));

  g_autoptr(FlJsonMessageCodec) codec = fl_json_message_codec_new();
  self->channel = fl_basic_message_channel_new(messenger, kChannelName,
                                               FL_MESSAGE_CODEC(codec));

  return self;
}

void fl_key_channel_responder_handle_event(
    FlKeyChannelResponder* self,
    FlKeyEvent* event,
    uint64_t specified_logical_key,
    FlKeyChannelResponderAsyncCallback callback,
    gpointer user_data) {
  g_return_if_fail(event != nullptr);
  g_return_if_fail(callback != nullptr);

  const gchar* type =
      fl_key_event_get_is_press(event) ? kTypeValueDown : kTypeValueUp;
  int64_t scan_code = fl_key_event_get_keycode(event);
  int64_t unicode_scarlar_values =
      gdk_keyval_to_unicode(fl_key_event_get_keyval(event));

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

  // Remove lock states from state mask.
  guint state =
      fl_key_event_get_state(event) & ~(GDK_LOCK_MASK | GDK_MOD2_MASK);

  static bool shift_lock_pressed = FALSE;
  static bool caps_lock_pressed = FALSE;
  static bool num_lock_pressed = FALSE;
  switch (fl_key_event_get_keyval(event)) {
    case GDK_KEY_Num_Lock:
      num_lock_pressed = fl_key_event_get_is_press(event);
      break;
    case GDK_KEY_Caps_Lock:
      caps_lock_pressed = fl_key_event_get_is_press(event);
      break;
    case GDK_KEY_Shift_Lock:
      shift_lock_pressed = fl_key_event_get_is_press(event);
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
                           fl_value_new_int(fl_key_event_get_keyval(event)));
  fl_value_set_string_take(message, kModifiersKey, fl_value_new_int(state));
  if (unicode_scarlar_values != 0) {
    fl_value_set_string_take(message, kUnicodeScalarValuesKey,
                             fl_value_new_int(unicode_scarlar_values));
  }

  if (specified_logical_key != 0) {
    fl_value_set_string_take(message, kSpecifiedLogicalKey,
                             fl_value_new_int(specified_logical_key));
  }

  FlKeyChannelUserData* data =
      fl_key_channel_user_data_new(self, callback, user_data);
  // Send the message off to the framework for handling (or not).
  fl_basic_message_channel_send(self->channel, message, nullptr,
                                handle_response, data);
}
