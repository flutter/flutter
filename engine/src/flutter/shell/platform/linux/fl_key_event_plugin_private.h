// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_EVENT_PLUGIN_PRIVATE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_EVENT_PLUGIN_PRIVATE_H_

#include "flutter/shell/platform/linux/fl_key_event_plugin.h"

#include <gtk/gtk.h>

G_BEGIN_DECLS

/**
 * fl_key_event_plugin_get_event_id:
 * @event: a GDK key event (GdkEventKey).
 *
 * Calculates an internal key ID for a given event. Used to look up pending
 * events using fl_key_event_plugin_find_pending_event.
 *
 * Returns: a 64-bit ID representing this GDK key event.
 */
uint64_t fl_key_event_plugin_get_event_id(GdkEventKey* event);

/**
 * fl_key_event_plugin_get_event_id:
 * @id: a 64-bit id representing  a GDK key event (GdkEventKey). Calculated
 * using #fl_key_event_plugin_get_event_id.
 *
 * Looks up an event that is waiting for a response from the framework.
 *
 * Returns: the GDK key event requested, or nullptr if the event doesn't exist
 * in the queue.
 */
GdkEventKey* fl_key_event_plugin_find_pending_event(FlKeyEventPlugin* self,
                                                    uint64_t id);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_EVENT_PLUGIN_PRIVATE_H_
