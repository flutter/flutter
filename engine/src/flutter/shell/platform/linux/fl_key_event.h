// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_EVENT_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_EVENT_H_

#include <gdk/gdk.h>

/**
 * FlKeyEventDispose:
 * @origin: the #FlKeyEvent::origin to dispose.
 *
 * The signature for #FlKeyEvent::dispose_origin, which
 * frees #FlKeyEvent::origin.
 **/
typedef void (*FlKeyEventDisposeOrigin)(gpointer origin);

/**
 * FlKeyEvent:
 * A struct that stores information from GdkEvent.
 *
 * This is a class only used within the GTK embedding, created by
 * FlView and consumed by FlKeyboardManager. It is not sent to
 * the embedder.
 *
 * This object contains information from GdkEvent as well as an origin event
 * object, so that Flutter can create an event object in unit tests even after
 * migrating to GDK 4.0 which stops supporting creating GdkEvent.
 */
typedef struct _FlKeyEvent {
  // Time in milliseconds.
  guint32 time;
  // True if is a press event, otherwise a release event.
  bool is_press;
  // Hardware keycode.
  guint16 keycode;
  // Keyval.
  guint keyval;
  // Modifier state.
  int state;
  // Keyboard group.
  guint8 group;
  // String, null-terminated.
  //
  // Can be nullptr.
  const char* string;
  // An opaque pointer to the original event.
  //
  // This is used when dispatching.  For native events, this is #GdkEvent
  // pointer.  For unit tests, this is a dummy pointer.
  gpointer origin;
  // A callback to free #origin, called in #fl_key_event_dispose.
  //
  // Can be nullptr.
  FlKeyEventDisposeOrigin dispose_origin;
} FlKeyEvent;

/**
 * fl_key_event_new_from_gdk_event:
 * @event: the #GdkEvent this #FlKeyEvent is based on. The #event must be a
 * #GdkEventKey, and will be destroyed by #fl_key_event_dispose.
 *
 * Create a new #FlKeyEvent based on a #GdkEvent.
 *
 * Returns: a new #FlKeyEvent. Must be freed with #fl_key_event_dispose.
 */
FlKeyEvent* fl_key_event_new_from_gdk_event(GdkEvent* event);

/**
 * fl_key_event_dispose:
 * @event: the event to dispose.
 *
 * Properly disposes the content of #event and then the pointer.
 */
void fl_key_event_dispose(FlKeyEvent* event);

FlKeyEvent* fl_key_event_clone(const FlKeyEvent* source);

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_EVENT_H_
