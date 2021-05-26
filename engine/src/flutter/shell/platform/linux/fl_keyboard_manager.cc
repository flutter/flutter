// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_keyboard_manager.h"

#include <cinttypes>

/* Declare and define FlKeyboardPendingEvent */

/**
 * FlKeyboardPendingEvent:
 * A record for events that have been received by the manager, but
 * dispatched to other objects, whose results have yet to return.
 *
 * This object is used by both the "pending_responds" list and the
 * "pending_redispatches" list.
 */
G_DECLARE_FINAL_TYPE(FlKeyboardPendingEvent,
                     fl_keyboard_pending_event,
                     FL,
                     KEYBOARD_PENDING_EVENT,
                     GObject);

struct _FlKeyboardPendingEvent {
  GObject parent_instance;

  // The target event.
  //
  // This is freed by #FlKeyboardPendingEvent.
  FlKeyEvent* event;

  // Self-incrementing ID attached to an event sent to the framework.
  //
  // Used to identify pending responds.
  uint64_t sequence_id;
  // The number of responders that haven't replied.
  size_t unreplied;
  // Whether any replied responders reported true (handled).
  bool any_handled;

  // A value calculated out of critical event information that can be used
  // to identify redispatched events.
  uint64_t hash;
};

G_DEFINE_TYPE(FlKeyboardPendingEvent, fl_keyboard_pending_event, G_TYPE_OBJECT)

static void fl_keyboard_pending_event_dispose(GObject* object) {
  // Redundant, but added so that we don't get a warning about unused function
  // for FL_IS_KEYBOARD_PENDING_EVENT.
  g_return_if_fail(FL_IS_KEYBOARD_PENDING_EVENT(object));

  FlKeyboardPendingEvent* self = FL_KEYBOARD_PENDING_EVENT(object);
  fl_key_event_dispose(self->event);
  G_OBJECT_CLASS(fl_keyboard_pending_event_parent_class)->dispose(object);
}

static void fl_keyboard_pending_event_class_init(
    FlKeyboardPendingEventClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_keyboard_pending_event_dispose;
}

static void fl_keyboard_pending_event_init(FlKeyboardPendingEvent* self) {}

// Calculates a unique ID for a given FlKeyEvent object to use for
// identification of responses from the framework.
static uint64_t fl_keyboard_manager_get_event_hash(FlKeyEvent* event) {
  // Combine the event timestamp, the type of event, and the hardware keycode
  // (scan code) of the event to come up with a unique id for this event that
  // can be derived solely from the event data itself, so that we can identify
  // whether or not we have seen this event already.
  guint64 type =
      static_cast<uint64_t>(event->is_press ? GDK_KEY_PRESS : GDK_KEY_RELEASE);
  guint64 keycode = static_cast<uint64_t>(event->keycode);
  return (event->time & 0xffffffff) | ((type & 0xffff) << 32) |
         ((keycode & 0xffff) << 48);
}

// Create a new FlKeyboardPendingEvent by providing the target event,
// the sequence ID, and the number of responders that will reply.
//
// This will acquire the ownership of the event.
FlKeyboardPendingEvent* fl_keyboard_pending_event_new(FlKeyEvent* event,
                                                      uint64_t sequence_id,
                                                      size_t to_reply) {
  FlKeyboardPendingEvent* self = FL_KEYBOARD_PENDING_EVENT(
      g_object_new(fl_keyboard_pending_event_get_type(), nullptr));

  self->event = event;
  self->sequence_id = sequence_id;
  self->unreplied = to_reply;
  self->any_handled = false;
  self->hash = fl_keyboard_manager_get_event_hash(event);
  return self;
}

/* Declare and define FlKeyboardManagerUserData */

/**
 * FlKeyEmbedderUserData:
 * The user_data used when #FlKeyboardManagerUserData sends event to
 * responders.
 */
#define FL_TYPE_KEYBOARD_MANAGER_USER_DATA \
  fl_keyboard_manager_user_data_get_type()
G_DECLARE_FINAL_TYPE(FlKeyboardManagerUserData,
                     fl_keyboard_manager_user_data,
                     FL,
                     KEYBOARD_MANAGER_USER_DATA,
                     GObject);

struct _FlKeyboardManagerUserData {
  GObject parent_instance;

  // A weak reference to the owner manager.
  FlKeyboardManager* manager;
  uint64_t sequence_id;
};

namespace {

// Context variables for the foreach call used to dispatch events to responders.
typedef struct {
  FlKeyEvent* event;
  FlKeyboardManagerUserData* user_data;
} DispatchToResponderLoopContext;

}  // namespace

G_DEFINE_TYPE(FlKeyboardManagerUserData,
              fl_keyboard_manager_user_data,
              G_TYPE_OBJECT)

static void fl_keyboard_manager_user_data_dispose(GObject* object) {
  g_return_if_fail(FL_IS_KEYBOARD_MANAGER_USER_DATA(object));
  FlKeyboardManagerUserData* self = FL_KEYBOARD_MANAGER_USER_DATA(object);
  if (self->manager != nullptr) {
    g_object_remove_weak_pointer(G_OBJECT(self->manager),
                                 reinterpret_cast<gpointer*>(&(self->manager)));
    self->manager = nullptr;
  }
}

static void fl_keyboard_manager_user_data_class_init(
    FlKeyboardManagerUserDataClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_keyboard_manager_user_data_dispose;
}

static void fl_keyboard_manager_user_data_init(
    FlKeyboardManagerUserData* self) {}

// Creates a new FlKeyboardManagerUserData private class with all information.
FlKeyboardManagerUserData* fl_keyboard_manager_user_data_new(
    FlKeyboardManager* manager,
    uint64_t sequence_id) {
  FlKeyboardManagerUserData* self = FL_KEYBOARD_MANAGER_USER_DATA(
      g_object_new(fl_keyboard_manager_user_data_get_type(), nullptr));

  self->manager = manager;
  // Add a weak pointer so we can know if the key event responder disappeared
  // while the framework was responding.
  g_object_add_weak_pointer(G_OBJECT(manager),
                            reinterpret_cast<gpointer*>(&(self->manager)));
  self->sequence_id = sequence_id;
  return self;
}

/* Define FlKeyboardManager */

struct _FlKeyboardManager {
  GObject parent_instance;

  // The callback that unhandled events should be redispatched through.
  FlKeyboardManagerRedispatcher redispatch_callback;

  // A text plugin.
  //
  // Released by the manager on dispose.
  FlTextInputPlugin* text_input_plugin;

  // An array of #FlKeyResponder. Elements are added with
  // #fl_keyboard_manager_add_responder immediately after initialization and are
  // automatically released on dispose.
  GPtrArray* responder_list;

  // An array of #FlKeyboardPendingEvent. FlKeyboardManager must manually
  // release the elements unless it is transferring them to
  // pending_redispatches.
  GPtrArray* pending_responds;

  // An array of #FlKeyboardPendingEvent. FlKeyboardManager must manually
  // release the elements.
  GPtrArray* pending_redispatches;

  // The last sequence ID used. Increased by 1 by every use.
  uint64_t last_sequence_id;
};

G_DEFINE_TYPE(FlKeyboardManager, fl_keyboard_manager, G_TYPE_OBJECT);

static void fl_keyboard_manager_dispose(GObject* object);

static void fl_keyboard_manager_class_init(FlKeyboardManagerClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_keyboard_manager_dispose;
}

static void fl_keyboard_manager_init(FlKeyboardManager* self) {}

static void fl_key_event_destroy_notify(gpointer event);
static void fl_keyboard_manager_dispose(GObject* object) {
  FlKeyboardManager* self = FL_KEYBOARD_MANAGER(object);

  if (self->text_input_plugin != nullptr)
    g_clear_object(&self->text_input_plugin);
  g_ptr_array_free(self->responder_list, TRUE);
  g_ptr_array_set_free_func(self->pending_responds,
                            fl_key_event_destroy_notify);
  g_ptr_array_free(self->pending_responds, TRUE);
  g_ptr_array_set_free_func(self->pending_redispatches,
                            fl_key_event_destroy_notify);
  g_ptr_array_free(self->pending_redispatches, TRUE);

  G_OBJECT_CLASS(fl_keyboard_manager_parent_class)->dispose(object);
}

/* Implement FlKeyboardManager */

// This is an exact copy of g_ptr_array_find_with_equal_func.  Somehow CI
// reports that can not find symbol g_ptr_array_find_with_equal_func, despite
// the fact that it runs well locally.
gboolean g_ptr_array_find_with_equal_func1(GPtrArray* haystack,
                                           gconstpointer needle,
                                           GEqualFunc equal_func,
                                           guint* index_) {
  guint i;
  g_return_val_if_fail(haystack != NULL, FALSE);
  if (equal_func == NULL)
    equal_func = g_direct_equal;
  for (i = 0; i < haystack->len; i++) {
    if (equal_func(g_ptr_array_index(haystack, i), needle)) {
      if (index_ != NULL) {
        *index_ = i;
      }
      return TRUE;
    }
  }

  return FALSE;
}

// Compare a #FlKeyboardPendingEvent with the given sequence_id. The needle
// should be a pointer to uint64_t sequence_id.
static gboolean compare_pending_by_sequence_id(
    gconstpointer pending,
    gconstpointer needle_sequence_id) {
  uint64_t sequence_id = *reinterpret_cast<const uint64_t*>(needle_sequence_id);
  return static_cast<const FlKeyboardPendingEvent*>(pending)->sequence_id ==
         sequence_id;
}

// Compare a #FlKeyboardPendingEvent with the given hash. The #needle should be
// a pointer to uint64_t hash.
static gboolean compare_pending_by_hash(gconstpointer pending,
                                        gconstpointer needle_hash) {
  uint64_t hash = *reinterpret_cast<const uint64_t*>(needle_hash);
  return static_cast<const FlKeyboardPendingEvent*>(pending)->hash == hash;
}

// Try to remove a pending event from `pending_redispatches` with the target
// hash.
//
// Returns true if the event is found and removed.
static bool fl_keyboard_manager_remove_redispatched(FlKeyboardManager* self,
                                                    uint64_t hash) {
  guint result_index;
  gboolean found = g_ptr_array_find_with_equal_func1(
      self->pending_redispatches, static_cast<const uint64_t*>(&hash),
      compare_pending_by_hash, &result_index);
  if (found) {
    FlKeyboardPendingEvent* removed =
        FL_KEYBOARD_PENDING_EVENT(g_ptr_array_remove_index_fast(
            self->pending_redispatches, result_index));
    g_return_val_if_fail(removed != nullptr, TRUE);
    g_object_unref(removed);
    return TRUE;
  } else {
    return FALSE;
  }
}

// The callback used by a responder after the event was dispatched.
static void responder_handle_event_callback(bool handled,
                                            gpointer user_data_ptr) {
  g_return_if_fail(FL_IS_KEYBOARD_MANAGER_USER_DATA(user_data_ptr));
  FlKeyboardManagerUserData* user_data =
      FL_KEYBOARD_MANAGER_USER_DATA(user_data_ptr);
  FlKeyboardManager* self = user_data->manager;

  guint result_index = -1;
  gboolean found = g_ptr_array_find_with_equal_func1(
      self->pending_responds, &user_data->sequence_id,
      compare_pending_by_sequence_id, &result_index);
  g_return_if_fail(found);
  FlKeyboardPendingEvent* pending = FL_KEYBOARD_PENDING_EVENT(
      g_ptr_array_index(self->pending_responds, result_index));
  g_return_if_fail(pending != nullptr);
  g_return_if_fail(pending->unreplied > 0);
  pending->unreplied -= 1;
  pending->any_handled = pending->any_handled || handled;
  // All responders have replied.
  if (pending->unreplied == 0) {
    g_object_unref(user_data_ptr);
    gpointer removed =
        g_ptr_array_remove_index_fast(self->pending_responds, result_index);
    g_return_if_fail(removed == pending);
    bool should_redispatch =
        !pending->any_handled && (self->text_input_plugin == nullptr ||
                                  !fl_text_input_plugin_filter_keypress(
                                      self->text_input_plugin, pending->event));
    if (should_redispatch) {
      g_ptr_array_add(self->pending_redispatches, pending);
      self->redispatch_callback(pending->event->origin);
    } else {
      g_object_unref(pending);
    }
  }
}

FlKeyboardManager* fl_keyboard_manager_new(
    FlTextInputPlugin* text_input_plugin,
    FlKeyboardManagerRedispatcher redispatch_callback) {
  g_return_val_if_fail(text_input_plugin == nullptr ||
                           FL_IS_TEXT_INPUT_PLUGIN(text_input_plugin),
                       nullptr);
  g_return_val_if_fail(redispatch_callback != nullptr, nullptr);

  FlKeyboardManager* self = FL_KEYBOARD_MANAGER(
      g_object_new(fl_keyboard_manager_get_type(), nullptr));

  self->text_input_plugin = text_input_plugin;
  self->redispatch_callback = redispatch_callback;
  self->responder_list = g_ptr_array_new_with_free_func(g_object_unref);

  self->pending_responds = g_ptr_array_new();
  self->pending_redispatches = g_ptr_array_new();

  self->last_sequence_id = 1;

  return self;
}

void fl_keyboard_manager_add_responder(FlKeyboardManager* self,
                                       FlKeyResponder* responder) {
  g_return_if_fail(FL_IS_KEYBOARD_MANAGER(self));
  g_return_if_fail(responder != nullptr);

  g_ptr_array_add(self->responder_list, responder);
}

// The loop body to dispatch an event to a responder.
static void dispatch_to_responder(gpointer responder_data,
                                  gpointer foreach_data_ptr) {
  DispatchToResponderLoopContext* context =
      reinterpret_cast<DispatchToResponderLoopContext*>(foreach_data_ptr);
  FlKeyResponder* responder = FL_KEY_RESPONDER(responder_data);
  fl_key_responder_handle_event(responder, context->event,
                                responder_handle_event_callback,
                                context->user_data);
}

gboolean fl_keyboard_manager_handle_event(FlKeyboardManager* self,
                                          FlKeyEvent* event) {
  g_return_val_if_fail(FL_IS_KEYBOARD_MANAGER(self), FALSE);
  g_return_val_if_fail(event != nullptr, FALSE);

  uint64_t incoming_hash = fl_keyboard_manager_get_event_hash(event);
  if (fl_keyboard_manager_remove_redispatched(self, incoming_hash)) {
    return FALSE;
  }

  FlKeyboardPendingEvent* pending = fl_keyboard_pending_event_new(
      event, ++self->last_sequence_id, self->responder_list->len);

  g_ptr_array_add(self->pending_responds, pending);
  FlKeyboardManagerUserData* user_data =
      fl_keyboard_manager_user_data_new(self, pending->sequence_id);
  DispatchToResponderLoopContext data{
      .event = event,
      .user_data = user_data,
  };
  g_ptr_array_foreach(self->responder_list, dispatch_to_responder, &data);

  return TRUE;
}

gboolean fl_keyboard_manager_is_state_clear(FlKeyboardManager* self) {
  g_return_val_if_fail(FL_IS_KEYBOARD_MANAGER(self), FALSE);
  return self->pending_responds->len == 0 &&
         self->pending_redispatches->len == 0;
}

static void fl_key_event_destroy_notify(gpointer event) {
  fl_key_event_dispose(reinterpret_cast<FlKeyEvent*>(event));
}
