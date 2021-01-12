// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_key_event_plugin.h"
#include "flutter/shell/platform/linux/fl_key_event_plugin_private.h"

#include <gtk/gtk.h>
#include <cinttypes>

#include "flutter/shell/platform/linux/fl_text_input_plugin.h"
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

static constexpr uint64_t kMaxPendingEvents = 1000;

// Definition of the FlKeyEventPlugin GObject class.

struct _FlKeyEventPlugin {
  GObject parent_instance;

  FlBasicMessageChannel* channel = nullptr;
  FlTextInputPlugin* text_input_plugin = nullptr;
  FlKeyEventPluginCallback response_callback = nullptr;
  GPtrArray* pending_events;
};

G_DEFINE_TYPE(FlKeyEventPlugin, fl_key_event_plugin, G_TYPE_OBJECT)

// Declare and define a private pair object to bind the id and the event
// together.

G_DECLARE_FINAL_TYPE(FlKeyEventPair,
                     fl_key_event_pair,
                     FL,
                     KEY_EVENT_PAIR,
                     GObject);

struct _FlKeyEventPair {
  GObject parent_instance;

  uint64_t id;
  GdkEventKey* event;
};

G_DEFINE_TYPE(FlKeyEventPair, fl_key_event_pair, G_TYPE_OBJECT)

// Dispose method for FlKeyEventPair.
static void fl_key_event_pair_dispose(GObject* object) {
  // Redundant, but added so that we don't get a warning about unused function
  // for FL_IS_KEY_EVENT_PAIR.
  g_return_if_fail(FL_IS_KEY_EVENT_PAIR(object));

  FlKeyEventPair* self = FL_KEY_EVENT_PAIR(object);
  g_clear_pointer(&self->event, gdk_event_free);
  G_OBJECT_CLASS(fl_key_event_pair_parent_class)->dispose(object);
}

// Class Initialization method for FlKeyEventPair class.
static void fl_key_event_pair_class_init(FlKeyEventPairClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_key_event_pair_dispose;
}

// Initialization for FlKeyEventPair instances.
static void fl_key_event_pair_init(FlKeyEventPair* self) {}

// Creates a new FlKeyEventPair instance, given a unique ID, and an event struct
// to keep.
FlKeyEventPair* fl_key_event_pair_new(uint64_t id, GdkEventKey* event) {
  FlKeyEventPair* self =
      FL_KEY_EVENT_PAIR(g_object_new(fl_key_event_pair_get_type(), nullptr));

  // Copy the event to preserve refcounts for referenced values (mainly the
  // window).
  GdkEventKey* event_copy = reinterpret_cast<GdkEventKey*>(
      gdk_event_copy(reinterpret_cast<GdkEvent*>(event)));
  self->id = id;
  self->event = event_copy;
  return self;
}

// Declare and define a private class to hold response data from the framework.
G_DECLARE_FINAL_TYPE(FlKeyEventResponseData,
                     fl_key_event_response_data,
                     FL,
                     KEY_EVENT_RESPONSE_DATA,
                     GObject);

struct _FlKeyEventResponseData {
  GObject parent_instance;

  FlKeyEventPlugin* plugin;
  uint64_t id;
  gpointer user_data;
};

// Definition for FlKeyEventResponseData private class.
G_DEFINE_TYPE(FlKeyEventResponseData, fl_key_event_response_data, G_TYPE_OBJECT)

// Dispose method for FlKeyEventResponseData private class.
static void fl_key_event_response_data_dispose(GObject* object) {
  g_return_if_fail(FL_IS_KEY_EVENT_RESPONSE_DATA(object));
  FlKeyEventResponseData* self = FL_KEY_EVENT_RESPONSE_DATA(object);
  if (self->plugin != nullptr) {
    g_object_remove_weak_pointer(G_OBJECT(self->plugin),
                                 reinterpret_cast<gpointer*>(&(self->plugin)));
    self->plugin = nullptr;
  }
}

// Class initialization method for FlKeyEventResponseData private class.
static void fl_key_event_response_data_class_init(
    FlKeyEventResponseDataClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_key_event_response_data_dispose;
}

// Instance initialization method for FlKeyEventResponseData private class.
static void fl_key_event_response_data_init(FlKeyEventResponseData* self) {}

// Creates a new FlKeyEventResponseData private class with a plugin that created
// the request, a unique ID for tracking, and optional user data.
// Will keep a weak pointer to the plugin.
FlKeyEventResponseData* fl_key_event_response_data_new(FlKeyEventPlugin* plugin,
                                                       uint64_t id,
                                                       gpointer user_data) {
  FlKeyEventResponseData* self = FL_KEY_EVENT_RESPONSE_DATA(
      g_object_new(fl_key_event_response_data_get_type(), nullptr));

  self->plugin = plugin;
  // Add a weak pointer so we can know if the key event plugin disappeared
  // while the framework was responding.
  g_object_add_weak_pointer(G_OBJECT(plugin),
                            reinterpret_cast<gpointer*>(&(self->plugin)));
  self->id = id;
  self->user_data = user_data;
  return self;
}

// Calculates a unique ID for a given GdkEventKey object to use for
// identification of responses from the framework.
uint64_t fl_key_event_plugin_get_event_id(GdkEventKey* event) {
  // Combine the event timestamp, the type of event, and the hardware keycode
  // (scan code) of the event to come up with a unique id for this event that
  // can be derived solely from the event data itself, so that we can identify
  // whether or not we have seen this event already.
  return (event->time & 0xffffffff) |
         (static_cast<uint64_t>(event->type) & 0xffff) << 32 |
         (static_cast<uint64_t>(event->hardware_keycode) & 0xffff) << 48;
}

// Finds an event in the event queue that was sent to the framework by its ID.
GdkEventKey* fl_key_event_plugin_find_pending_event(FlKeyEventPlugin* self,
                                                    uint64_t id) {
  for (guint i = 0; i < self->pending_events->len; ++i) {
    if (FL_KEY_EVENT_PAIR(g_ptr_array_index(self->pending_events, i))->id ==
        id) {
      return FL_KEY_EVENT_PAIR(g_ptr_array_index(self->pending_events, i))
          ->event;
    }
  }
  return nullptr;
}

// Removes an event from the pending event queue.
static void remove_pending_event(FlKeyEventPlugin* self, uint64_t id) {
  for (guint i = 0; i < self->pending_events->len; ++i) {
    if (FL_KEY_EVENT_PAIR(g_ptr_array_index(self->pending_events, i))->id ==
        id) {
      g_ptr_array_remove_index(self->pending_events, i);
      return;
    }
  }
  g_warning(
      "Tried to remove pending event with id %ld, but the event was not found.",
      id);
}

// Adds an GdkEventKey to the pending event queue, with a unique ID, and the
// plugin that added it.
static void add_pending_event(FlKeyEventPlugin* self,
                              uint64_t id,
                              GdkEventKey* event) {
  if (self->pending_events->len > kMaxPendingEvents) {
    g_warning(
        "There are %d keyboard events that have not yet received a "
        "response from the framework. Are responses being sent?",
        self->pending_events->len);
  }
  g_ptr_array_add(self->pending_events, fl_key_event_pair_new(id, event));
}

// Handles a response from the framework to a key event sent to the framework
// earlier.
static void handle_response(GObject* object,
                            GAsyncResult* result,
                            gpointer user_data) {
  g_autoptr(FlKeyEventResponseData) data =
      FL_KEY_EVENT_RESPONSE_DATA(user_data);

  // Will also return if the weak pointer has been destroyed.
  if (data->plugin == nullptr) {
    return;
  }

  FlKeyEventPlugin* self = data->plugin;

  g_autoptr(GError) error = nullptr;
  FlBasicMessageChannel* messageChannel = FL_BASIC_MESSAGE_CHANNEL(object);
  FlValue* message =
      fl_basic_message_channel_send_finish(messageChannel, result, &error);
  if (error != nullptr) {
    g_warning("Unable to retrieve framework response: %s", error->message);
    return;
  }
  g_autoptr(FlValue) handled_value = fl_value_lookup_string(message, "handled");
  bool handled = FALSE;
  if (handled_value != nullptr) {
    GdkEventKey* event = fl_key_event_plugin_find_pending_event(self, data->id);
    if (event == nullptr) {
      g_warning("Event response for event id %" PRIu64
                " received, but pending event was not found.",
                data->id);
    } else {
      handled = fl_value_get_bool(handled_value);
      if (!handled) {
        if (self->text_input_plugin != nullptr) {
          // Propagate the event to the text input plugin.
          handled = fl_text_input_plugin_filter_keypress(
              self->text_input_plugin, event);
        }
        // Dispatch the event to other GTK windows if the text input plugin
        // didn't handle it. We keep track of the event id so we can recognize
        // the event when our window receives it again and not respond to it. If
        // the response callback is set, then use that instead.
        if (!handled && self->response_callback == nullptr) {
          gdk_event_put(reinterpret_cast<GdkEvent*>(event));
        }
      }
    }
  }

  if (handled) {
    // Because the event was handled, we no longer need to track it. Unhandled
    // events will be removed when the event is re-dispatched to the window.
    remove_pending_event(self, data->id);
  }

  if (self->response_callback != nullptr) {
    self->response_callback(object, message, handled, data->user_data);
  }
}

// Disposes of an FlKeyEventPlugin instance.
static void fl_key_event_plugin_dispose(GObject* object) {
  FlKeyEventPlugin* self = FL_KEY_EVENT_PLUGIN(object);

  g_clear_object(&self->channel);
  if (self->text_input_plugin != nullptr) {
    g_object_remove_weak_pointer(
        G_OBJECT(self->text_input_plugin),
        reinterpret_cast<gpointer*>(&(self->text_input_plugin)));
    self->text_input_plugin = nullptr;
  }
  g_ptr_array_free(self->pending_events, TRUE);

  G_OBJECT_CLASS(fl_key_event_plugin_parent_class)->dispose(object);
}

// Initializes the FlKeyEventPlugin class methods.
static void fl_key_event_plugin_class_init(FlKeyEventPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_key_event_plugin_dispose;
}

// Initializes an FlKeyEventPlugin instance.
static void fl_key_event_plugin_init(FlKeyEventPlugin* self) {}

// Creates a new FlKeyEventPlugin instance, with a messenger used to send
// messages to the framework, an FlTextInputPlugin used to handle key events
// that the framework doesn't handle. Mainly for testing purposes, it also takes
// an optional callback to call when a response is received, and an optional
// channel name to use when sending messages.
FlKeyEventPlugin* fl_key_event_plugin_new(
    FlBinaryMessenger* messenger,
    FlTextInputPlugin* text_input_plugin,
    FlKeyEventPluginCallback response_callback,
    const char* channel_name) {
  g_return_val_if_fail(FL_IS_BINARY_MESSENGER(messenger), nullptr);
  g_return_val_if_fail(FL_IS_TEXT_INPUT_PLUGIN(text_input_plugin), nullptr);

  FlKeyEventPlugin* self = FL_KEY_EVENT_PLUGIN(
      g_object_new(fl_key_event_plugin_get_type(), nullptr));

  g_autoptr(FlJsonMessageCodec) codec = fl_json_message_codec_new();
  self->channel = fl_basic_message_channel_new(
      messenger, channel_name == nullptr ? kChannelName : channel_name,
      FL_MESSAGE_CODEC(codec));
  self->response_callback = response_callback;
  // Add a weak pointer so we know if the text input plugin goes away.
  g_object_add_weak_pointer(
      G_OBJECT(text_input_plugin),
      reinterpret_cast<gpointer*>(&(self->text_input_plugin)));
  self->text_input_plugin = text_input_plugin;

  self->pending_events = g_ptr_array_new_with_free_func(g_object_unref);
  return self;
}

// Sends a key event to the framework.
bool fl_key_event_plugin_send_key_event(FlKeyEventPlugin* self,
                                        GdkEventKey* event,
                                        gpointer user_data) {
  g_return_val_if_fail(FL_IS_KEY_EVENT_PLUGIN(self), FALSE);
  g_return_val_if_fail(event != nullptr, FALSE);

  // Get an ID for the event, so we can match them up when we get a response
  // from the framework. Use the event time, type, and hardware keycode as a
  // unique ID, since they are part of the event structure that we can look up
  // when we receive a random event that may or may not have been
  // tracked/produced by this code.
  uint64_t id = fl_key_event_plugin_get_event_id(event);
  if (self->pending_events->len != 0 &&
      fl_key_event_plugin_find_pending_event(self, id) != nullptr) {
    // If the event is in the queue of pending events we've seen, then we know
    // that this is a re-dispatched event, and we shouldn't respond to it, but
    // we should remove it from tracking.
    remove_pending_event(self, id);
    return FALSE;
  }

  const gchar* type;
  switch (event->type) {
    case GDK_KEY_PRESS:
      type = kTypeValueDown;
      break;
    case GDK_KEY_RELEASE:
      type = kTypeValueUp;
      break;
    default:
      return FALSE;
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

  static bool shift_lock_pressed = FALSE;
  static bool caps_lock_pressed = FALSE;
  static bool num_lock_pressed = FALSE;
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

  // Track the event as pending a response from the framework.
  add_pending_event(self, id, event);
  FlKeyEventResponseData* data =
      fl_key_event_response_data_new(self, id, user_data);
  // Send the message off to the framework for handling (or not).
  fl_basic_message_channel_send(self->channel, message, nullptr,
                                handle_response, data);
  // Return true before we know what the framework will do, because if it
  // doesn't handle the key, we'll re-dispatch it later.
  return TRUE;
}
