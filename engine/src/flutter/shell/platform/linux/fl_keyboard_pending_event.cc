// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_keyboard_pending_event.h"

/**
 * FlKeyboardPendingEvent:
 * A record for events that have been received by the handler, but
 * dispatched to other objects, whose results have yet to return.
 *
 * This object is used by both the "pending_responds" list and the
 * "pending_redispatches" list.
 */

struct _FlKeyboardPendingEvent {
  GObject parent_instance;

  // The target event.
  FlKeyEvent* event;

  // Unique ID to identify pending responds.
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
  FlKeyboardPendingEvent* self = FL_KEYBOARD_PENDING_EVENT(object);

  g_clear_object(&self->event);

  G_OBJECT_CLASS(fl_keyboard_pending_event_parent_class)->dispose(object);
}

static void fl_keyboard_pending_event_class_init(
    FlKeyboardPendingEventClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_keyboard_pending_event_dispose;
}

static void fl_keyboard_pending_event_init(FlKeyboardPendingEvent* self) {}

// Creates a new FlKeyboardPendingEvent by providing the target event,
// the sequence ID, and the number of responders that will reply.
FlKeyboardPendingEvent* fl_keyboard_pending_event_new(FlKeyEvent* event,
                                                      uint64_t sequence_id,
                                                      size_t to_reply) {
  FlKeyboardPendingEvent* self = FL_KEYBOARD_PENDING_EVENT(
      g_object_new(fl_keyboard_pending_event_get_type(), nullptr));

  self->event = FL_KEY_EVENT(g_object_ref(event));
  self->sequence_id = sequence_id;
  self->unreplied = to_reply;
  self->any_handled = false;
  self->hash = fl_key_event_hash(self->event);

  return self;
}

FlKeyEvent* fl_keyboard_pending_event_get_event(FlKeyboardPendingEvent* self) {
  g_return_val_if_fail(FL_IS_KEYBOARD_PENDING_EVENT(self), nullptr);
  return self->event;
}

uint64_t fl_keyboard_pending_event_get_sequence_id(
    FlKeyboardPendingEvent* self) {
  g_return_val_if_fail(FL_IS_KEYBOARD_PENDING_EVENT(self), 0);
  return self->sequence_id;
}

uint64_t fl_keyboard_pending_event_get_hash(FlKeyboardPendingEvent* self) {
  g_return_val_if_fail(FL_IS_KEYBOARD_PENDING_EVENT(self), 0);
  return self->hash;
}

void fl_keyboard_pending_event_mark_replied(FlKeyboardPendingEvent* self,
                                            gboolean handled) {
  g_return_if_fail(FL_IS_KEYBOARD_PENDING_EVENT(self));
  g_return_if_fail(self->unreplied > 0);
  self->unreplied -= 1;
  if (handled) {
    self->any_handled = TRUE;
  }
}

gboolean fl_keyboard_pending_event_get_any_handled(
    FlKeyboardPendingEvent* self) {
  g_return_val_if_fail(FL_IS_KEYBOARD_PENDING_EVENT(self), FALSE);
  return self->any_handled;
}

gboolean fl_keyboard_pending_event_is_complete(FlKeyboardPendingEvent* self) {
  g_return_val_if_fail(FL_IS_KEYBOARD_PENDING_EVENT(self), FALSE);
  return self->unreplied == 0;
}
